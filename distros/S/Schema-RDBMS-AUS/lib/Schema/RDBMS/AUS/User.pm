#!perl

package Schema::RDBMS::AUS::User;

use strict;
use warnings;
use Carp qw(croak);
use DBIx::Transaction;
use URI;
use URI::QueryParam;
use Schema::RDBMS::AUS;

use vars qw(%ENV);

return 1;

# constructors

sub login {
    my($class, $user, $password, %login_info) = @_;
    %login_info = (%login_info, name => $user, password => $password);
    my $self;
    if($self = eval { $class->_login(%login_info) }) {
        my $txn = delete($login_info{_post_login}) || sub { return shift };
        return $self->dbh->transaction(sub {
            $self->used;
            $self->log('login', %login_info) or return;
            $txn->($self);
        });
    } else {
        my $err = $@;
        $self = $class->load(%login_info); # will die if user doesnt exist
        $login_info{error} = $err;
        $self->log('login_failure', %login_info);
        die $err;
    }
}

sub _login {
    my($class, %login_info) = @_;

    if(my $self = $class->load(%login_info)) {
        die qq{Can not log in as group #$self->{id} "$login_info{name}"\n}
            if($self->{is_group});
        
        die qq{Account #$self->{id} "$login_info{name}" is disabled.\n}
            if($self->flag('Disabled'));
        
        if($self->check_password($login_info{password})) {
            return $self;
        } else {
            die qq{Bad password for user #$self->{id} "$login_info{name}"\n};
        }
    } else {
        die qq{No such user "$login_info{name}"\n};
    }
}

sub load {
    my $class = shift;
    return $class->_new(@_)->_LOAD_user;
}

sub create {
    my($class, %args) = @_;
    my $self = $class->_new(%args);

    $self->{password_crypt} = $self->default_password_crypt
        unless $self->{password_crypt};

    return $self->dbh->transaction(sub {
        $self->_CREATE_user or die "Failed to create user.\n";
        $self->log('create', %args) or die "Failed to log user creation.\n";
        return $self unless defined $self->{_password};
        
        $self->{password} = 
            $self->crypt($self->password(delete $self->{_password}));
            
        $self->save;
    });
}

# methods

sub password {
    my($self, $password) = @_;
    if($self->{_validate_password}->($password)) {
        return $password;
    } else {
        die "Invalid password.\n";
    }
}

sub reset_password {
    my($self, $password) = splice(@_, 0, 2);
    if($self->password($password)) {
        return $self->_reset_password($password, @_);
    }
}

sub _reset_password {
    my($self, $password, $reason, %log_params) = @_;
    $reason ||= 'reset_password';
    $self->{password} = $self->crypt($password);
    return $self->dbh->transaction(sub {
        $self->save &&
        $self->log($reason, %log_params);
    });
}

sub change_password {
    my($self, $old, $new, %log_params) = @_;
    if($self->_check_password($old)) {
        return $self->reset_password($new, 'change_password', %log_params);
    } else {
        die "Old password does not match.\n";
    }
}

sub save {
    my $self = shift;
    return $self->dbh->transaction(sub {
        if($self->_UPDATE_user && $self->_save_flags) {
            return $self;
        } else {
            die "Failed to save user.\n";
        }
    });
}

sub used {
    my $self = shift;
    return $self->{time_used} = $self->_UPDATE_used;
}

sub log {
    my($self, $event, %args) = @_;
    delete @args{qw(password id _dbh)};
    my $uri = URI->new;
    $uri->query_form_hash(\%args);
    my $data = $uri->query;
    return $self->_INSERT_user_log($event, $data);
}

sub crypt {
    my $self = shift;
    return $self->{_crypt_class}->crypt(@_);
}

sub check_password {
    my($self, $password) = @_;
    return unless defined $self->{password} && length $self->{password} &&
        defined $password && length $password;
    return $self->_check_password($password);
}

sub flag {
    my($self, $flag) = @_;
    return $self->{_flags}->{lc $flag};
}

sub permission {
    my($self, $perm) = @_;
    return $self->{_permissions}->{lc $perm};
}

sub set_flag {
    my($self, $flag, $value, $create) = @_;
    if(!defined $value) {
        $value = 1;
    } else {
        $value = (!!$value) || 0;
    }
    $self->_SELECT_or_INSERT_flag($flag) if $create;
    return $self->{_flags}->{lc $flag} = $value;
}

sub clear_flag {
    my($self, $flag) = @_;
    delete $self->{_flags}->{lc $flag};
}

sub add_to_group {
    my($self, $group) = @_;
    
    return $self->dbh->transaction(sub {
        $group = ref($self)->load(name => $group, _dbh => $self->{_dbh})
            unless ref $group;
    
        return
            $self->_INSERT_membership($group->{id}) &&
            $self->_refresh_permissions &&
            $self->_refresh_membership;
    });
}

sub remove_from_group {
    my($self, $group) = @_;
    
    return $self->dbh->transaction(sub {
        $group = ref($self)->load(name => $group, _dbh => $self->{_dbh})
            unless ref $group;
    
        return
            $self->_DELETE_membership($group->{id}) &&
            $self->_refresh_permissions &&
            $self->_refresh_membership;
    });
}

sub refresh {
    my $self = shift;
    return $self->_refresh_meta && $self->_refresh_user;
}

# accessors

sub dbh { return $_[0]->{_dbh}; }

sub default_password_crypt { return "SHA1"; }

# driver constructor

sub driver_new {
    my($class, $driver, %args) = @_;
    
    $args{_flags} ||= {};
    $args{_permissions} ||= {};
    $args{_membership} ||= {};

    return bless \%args, $class;
}

# private class methods

sub _connect_cached {
    my($class, %args) = @_;
    
    if(my $dbh = Schema::RDBMS::AUS->dbh(
        @args{qw(_db_dsn _db_user _db_pass _db_opts)}
    )) {
        return $dbh;
    } else {
        croak(qq{_connect_cached() failed: }, DBI->errstr);
    }
}

# private class/object methods

sub _new {
    my($self, %args) = @_;
    
    my $class;
    if($class = ref($self)) {
        %args = (%$self, %args);
    } else {
        $class = $self;
    }

    $args{_dbh} = $self->_connect_cached(%args)
        unless $args{_dbh};

    croak "a database handle (_dbh) is required for $class"
        unless($args{_dbh});
        
    croak "_dbh does not seem to be a DBIx::Transaction object"
        unless($args{_dbh}->isa('DBIx::Transaction::db'));
        
    $args{_dbh_driver} = $args{_dbh}->{Driver}->{Name}
        unless $args{_dbh_driver};
        
    $args{_validate_password} = sub { return length $_[0]; }
        unless $args{_validate_password};

    return $class->driver_new($args{_dbh_driver}, %args);
}

sub _use_crypt_class {
    my $self = shift;
    
    eval "use $self->{_crypt_class}; 1"
        or croak "Failed to load $self->{_crypt_class}: $@";
    
    return $self;
}

sub _refresh_user {
    my $self = shift;
    if(my $row = $self->_SELECT_user) {
        %$self = (%$self, %$row);
        return $self;
    } else {
        die "Refreshing user failed!";
    }
}

sub _refresh_meta {
    my $self = shift;
    return
        $self->_refresh_flags &&
        $self->_refresh_permissions &&
        $self->_refresh_membership
        or die "Refreshing metadata failed!";
}

# low-level queries

sub _LOAD_user {
    my($self, %args) = @_;
    return $self->dbh->transaction(sub {
        if(my $row = $self->_SELECT_user(%args)) {
            %$self = (%$self, %$row);
            $self->_refresh_flags;
            $self->_refresh_permissions;
            $self->_refresh_membership;
            return $self->_use_crypt_class;
        } else {
            die "User not found.\n";
        }
    });
}

sub _check_password {
    my($self, $password) = @_;
    return $self->crypt($password) eq $self->{password};
}

sub _CREATE_user {
    my($self, %args) = @_;
    return $self->dbh->transaction(sub {
        if($self->_INSERT_user(%args)) {
            my $id = $self->dbh->last_insert_id(undef, undef, 'aus_user', undef);
            $self->{id} = $id;
            return $self->_LOAD_user;
        } else {
            return;
        }
    });
}

sub _sql_UPDATE_used {
    my $self = shift;
    return('UPDATE aus_user SET time_used = now() WHERE id = ?', $self->{id});
}

sub _sql_SELECT_used {
    my $self = shift;
    return('SELECT time_used FROM aus_user WHERE id = ?', $self->{id});
}

sub _UPDATE_used {
    my $self = shift;
    my $dbh = $self->dbh;
    return $dbh->transaction(sub {
        my($query, $id) = $self->_sql_UPDATE_used;
        $dbh->do($query, {}, $id)
            or die "Failed to update last used time: ", $dbh->errstr;
            
        ($query, $id) = $self->_sql_SELECT_used;
        return $dbh->selectrow_array($query, {}, $id)
            or die "Failed to fetch last used time: ", $dbh->errstr;
    });
}

sub _FIELDS_user {
    return qw(id name password password_crypt is_group time_used);
}

sub _sql_SELECT_user {
    my($self, %args) = @_;

    my($k, $v);
    my @fields = (
        (map { "aus_user.$_ AS $_" } $self->_FIELDS_user),
        "aus_password_crypt.class AS _crypt_class"
    );
        
    {
        local $" = ", ";
        $k = qq{
            SELECT @fields FROM aus_user
                LEFT OUTER JOIN
                    aus_password_crypt
                ON
                    aus_user.password_crypt = aus_password_crypt.id
        };
    }

    if($args{id}) {
        $k .= "WHERE aus_user.id = ?";
        $v = $args{id};
    } elsif($args{name}) {
        $k .= "WHERE aus_user.name = ?";
        $v = $args{name};
    } else {
        croak q{Neither "name" or "id" were specified to _SELECT_user!};
    }

    return($k, $v);
}

sub _SELECT_user {
    my($self, %args) = @_;
    %args = (%$self, %args);
    
    my($query, $id) = $self->_sql_SELECT_user(%args);
    if(my $sth = $self->dbh->prepare($query)) {
        if($sth->execute($id)) {
            my $rv = $sth->fetchrow_hashref;
            $sth->finish;
            return $rv;
        }
    }

    die "Query $query failed: ", $self->dbh->errstr;
}

sub _SELECT_or_INSERT_flag {
    my($self, $flag) = @_;
    $flag = lc $flag;
    return $self->dbh->transaction(sub {
        my $sth = $self->dbh->prepare_cached(
            "SELECT name FROM aus_flag WHERE name = ?"
        );
        
        $sth->execute($flag) or die $sth->errstr;
        if($sth->fetchrow_array) {
            $sth->finish;
            return $flag;
        } else {
            $sth->finish;
            $self->dbh->do("INSERT INTO aus_flag (name) VALUES (?)", {}, $flag)
                    or die $self->dbh->errstr;
            return $flag;
        }
    });
}

sub _sql_INSERT_user {
    my($self, %args) = @_;
    
    my @keys = sort grep($args{$_}, $self->_FIELDS_user);
    my @qs = (("?") x scalar @keys);

    local $" = ", ";
    return(qq{INSERT INTO aus_user (@keys) VALUES (@qs)}, @keys);
}

sub _INSERT_user {
    my($self, %args) = @_;
    
    %args = (%$self, %args);
    croak "Can't INSERT a user that already has an id" if($args{id});
    
    return $self if($self->dbh->transaction(sub {
        my($query, @keys) = $self->_sql_INSERT_user(%args);
        $self->dbh->do($query, {}, @args{@keys});
    }));
    
    return;
}

sub _INSERT_user_log {
    my($self, $event, $data) = @_;
    return $self->dbh->transaction(sub {
        $self->dbh->do(
            "INSERT INTO aus_user_log (user_id, event, data) VALUES (?, ?, ?)",
            {},
            $self->{id}, $event, $data
        );
    });
}

sub _sql_UPDATE_user {
    my $self = shift;
    my @fields = grep($_ ne 'id' && $_ ne 'time_used', $self->_FIELDS_user);
    my @updates = map { "$_ = ?" } @fields;
    local $" = ", ";
    my $sql = "UPDATE aus_user SET @updates WHERE id = ?";
    return($sql, @fields, 'id');
}

sub _UPDATE_user {
    my $self = shift;
    my($query, @params) = $self->_sql_UPDATE_user;

    return $self->dbh->transaction(
        sub { $self->dbh->do($query, {}, @{$self}{@params}); }
    );
}

sub _sql_DELETE_flags {
    my $self = shift;
    return(
        q{DELETE FROM aus_user_flags WHERE user_id = ?},
        'id'
    );
}

sub _sql_INSERT_flag {
    my $self = shift;
    return(
        q{INSERT INTO aus_user_flags (user_id, flag_name, enabled) VALUES (?, ?, ?)},
        'id'
    );
}

sub _sql_SELECT_flags {
    my $self = shift;
    return(
        q{SELECT flag_name, enabled FROM aus_user_flags WHERE user_id = ?},
        'id'
    );
}

sub _sql_SELECT_permissions {
    my $self = shift;
    return(
        q{SELECT flag_name, enabled FROM aus_all_user_flags WHERE user_id = ?},
        'id'
    );
}

sub _sql_SELECT_membership {
    my $self = shift;
    return(
        q{
            SELECT
                ancestor, min(degree) AS degree
            FROM aus_user_ancestors
            WHERE user_id = ?
            GROUP BY user_id, ancestor
        },
        'id'
    );
}

sub _fetch_flags {
    my($self, $sth) = @_;
    my %rv;
    while(my @row = $sth->fetchrow_array) {
        $rv{lc $row[0]} = $row[1];
    }
    return %rv;
}

sub _SELECT_flags {
    my($self, $query, @params) = @_;
    my %rv;
    $self->dbh->transaction(sub {
        my $sth = $self->dbh->prepare_cached($query);
        if($sth->execute(@{$self}{@params})) {
            %rv = $self->_fetch_flags($sth);
            $sth->finish;
        } else {
            die "fetching flags failed: ", $sth->errstr;
        }
    });
    return %rv;
}

sub _INSERT_membership {
    my($self, $gid) = @_;
    return $self->dbh->transaction(sub {
        my $sth = $self->dbh->prepare_cached(
            q{INSERT INTO aus_user_membership (user_id, member_of) VALUES (?, ?)}
        );
    
        $sth->execute($self->{id}, $gid)
            or die $sth->errstr;
        
        return 1;
    });
}

sub _DELETE_membership {
    my($self, $gid) = @_;
    return $self->dbh->transaction(sub {
        my $sth = $self->dbh->prepare_cached(
            q{DELETE FROM aus_user_membership WHERE user_id = ? AND member_of = ?}
        );
    
        $sth->execute($self->{id}, $gid)
            or die $sth->errstr;
        
        return 1;
    });
}

sub _refresh_flags {
    my $self = shift;
    my %rv = $self->_SELECT_flags($self->_sql_SELECT_flags);
    $self->{_flags} = \%rv;
    return $self->{_flags};
}

sub _refresh_permissions {
    my $self = shift;
    my %rv = $self->_SELECT_flags($self->_sql_SELECT_permissions);
    $self->{_permissions} = \%rv;
    return $self->{_permissions};
}

sub _refresh_membership {
    my $self = shift;
    my %rv = $self->_SELECT_flags($self->_sql_SELECT_membership);
    $self->{_membership} = \%rv;
    return $self->{_membership};
}

sub _save_flags {
    my $self = shift;
    return $self->dbh->transaction(sub {
        my($q, @p) = $self->_sql_DELETE_flags;
        
        $self->dbh->do($q, {}, @{$self}{@p}) or die
            "do($q): ", $self->dbh->errstr;
        
        ($q, @p) = $self->_sql_INSERT_flag;
        
        while(my($k, $v) = each(%{$self->{_flags}})) {
            $self->dbh->do($q, {}, @{$self}{@p}, $k, $v) or
                die "do($q, $k, $v): ", $self->dbh->errstr;
        }
        
        $self->_refresh_permissions;
        return 1;
    });
}
