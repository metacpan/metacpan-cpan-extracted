
package MySQL::Easy::sth;

use Carp;
use common::sense;

our $AUTOLOAD;

# new {{{
sub new {
    my ($class, $mysql_e, $statement) = @_;
    my $this  = bless { s=>$statement, dbo=>$mysql_e }, $class;

    $this->{sth} = $this->{dbo}->handle->prepare( $statement );

    return $this;
}
# }}}
# bind_execute {{{
sub bind_execute {
    my $this = shift;

    $this->{sth}->execute;
    $this->{sth}->bind_columns( @_ );

    return $this;
}
# }}}
# {{{ sub repair_statement
sub repair_statement {
    my $this = shift;

    $this->{sth} = $this->{dbo}->handle->prepare( $this->{s} );
    return $this;
}

# }}}
# AUTOLOAD {{{
sub AUTOLOAD {
    my $_self = shift;
    my $sub = $AUTOLOAD;
       $sub = $1 if $sub =~ m/::(\w+)$/;

    return unless $_self->{sth}; # I should be dead?
    croak "$sub is not a member of " . ref($_self->{sth}) unless $_self->{sth}->can($sub);

    *{ __PACKAGE__ . "::$sub" } = sub {
        my $this = shift;
        my $tries = 2;

        return unless $this->{sth}; # I should be dead?

        my $wa = wantarray;
        my ($err, $warn, $ret, @ret);

        # warn "DEBUG: FYI, $$-$this is loading $sub()";

        EVAL_IT: eval {
            no strict 'refs';
            local $SIG{__WARN__} = sub { $warn = "@_"; };

            if( $wa ) {
                @ret = $this->{sth}->$sub( @_ );

            } else {
                $ret = $this->{sth}->$sub( @_ );
            }
        };

        $err = $@;

        if( $warn and not $err ) {
            $err = $warn;
            chomp $err;
        }

        if( $err ) {
          # my @c = caller;
          # my $p = "at $c[1] line $c[2], prepared at $this->{_ready_caller}[1] line $this->{_ready_caller}[2]\n";
            my $p = "(prepared at $this->{_ready_caller}[1] line $this->{_ready_caller}[2])";

            1 while $err =~ s/\s+at(?:\s+\S+)?\s+line\s+\d+\.?$//;

            # ERROR executing execute(): DBD::mysql::st execute failed: You have an error in your SQL syntax; check the manual
            $err =~ s/DBD::mysql::sth? execute failed:\s*//;

            if( $err =~ m/(?:MySQL server has gone away|Lost connection)/ ) {
                if( $sub eq "execute" ) {
                    $this->repair_statement;
                    $warn = undef;

                    goto EVAL_IT if ((--$tries) > 0);

                } else {
                    croak "MySQL::Easy::sth can only recover from connection problems during execute(): $err $p";
                }
            }

            croak "ERROR executing $sub(): $err $p";
        }

        return ($wa ? @ret : $ret);
    };

    return $_self->$sub(@_);
}
# }}}
# DESTROY {{{
sub DESTROY {
    my $this = shift;

    # warn "MySQL::Easy::sth is dying"; # This is here to make sure we don't normally die during global destruction.
                                        # Once it appeared to function correctly, it was removed.
                                        # Lastly, we would die during global dest iff: our circular ref from new() were not removed.
                                        # Although, to be truely circular, the MySQL::Easy would need to point to this ::sth also
                                        # and it probably doesn't.  So, is this delete paranoid?  Yeah...  meh.
    delete $this->{dbo};
}
# }}}

package MySQL::Easy;

use Carp ();
use common::sense;
use Scalar::Util qw(blessed);
use overload fallback=>1, '""' => sub { ref($_[0]) . "($_[0]{dbase})" };

use DBI;

our $AUTOLOAD;
our $VERSION = "2.1019";
our $CNF_ENV = "ME_CNF";
our $USER_ENV = "ME_USER";
our $PASS_ENV = "ME_PASS";
our $HOME_ENV = "HOME";
our @MY_CNF_LOCATIONS = (
    $ENV{$CNF_ENV}, "$ENV{$HOME_ENV}/.my.cnf", "/etc/mysql-easy.cnf", "/etc/mysql/my.cnf"
);

# {{{ sub mycroak
sub mycroak(;$) {
    my $error = shift;

    my $i = 1;
    my @c = caller(  $i);
       @c = caller(++$i) while $c[0] eq __PACKAGE__;

    chomp $error;

    1 while
    $error =~ s{\s+at\s+\S+\s+line\s+\d+\.}{}g;
    $error =~ s{\s+\(prepared at $c[1] line $c[2]\)}{}; # this would be a dup error in this case

    #arn "<<<$error\[$i]>>>";

    Carp::croak($error);
}

# }}}

# AUTOLOAD {{{
sub AUTOLOAD {
    my $_self = shift;
    my $sub   = $AUTOLOAD;
       $sub   = $1 if $sub =~ m/::(\w+)$/;

    {
        my $handle = $_self->handle;
        mycroak "$sub is not a member of " . ref($handle) unless $handle->can($sub);
    }

    *{ __PACKAGE__ . "::$sub" } = sub {
        my $this = shift;
        my $handle = $this->handle;

        my $wa = wantarray;
        my ($err, $warn, $ret, @ret);
        my @oargs = @_;
        my $tries = 2;

        EVAL_IT: my $eval_result = eval {
            my @cargs = @oargs;
            local $SIG{__WARN__} = sub { $warn = "@_"; };

            $cargs[0] = $cargs[0]->{sth} if @cargs and blessed $cargs[0] and $cargs[0]->isa("MySQL::Easy::sth");

            if( wantarray ) {
                @ret = $handle->$sub(@cargs);

            } else {
                $ret = $handle->$sub(@cargs);
            }

            !$warn
        };

        unless( $eval_result ) {
            $err = $@;

            if( $err =~ m/(?:MySQL server has gone away|Lost connection)/ ) {
                if( blessed $oargs[0] ) {
                    if( $oargs[0]->isa("MySQL::Easy::sth") ) {
                        $oargs[0]->repair_statement;

                    } else {
                        warn "argument to $sub is blessed, but is not a MySQL::Easy::sth, connection rebuild will probably fail";
                    }
                }
                goto EVAL_IT if ((--$tries) > 0);
            }

            if( $warn and not $err ) {
                $err = $warn;
                chomp $err;
            }

            $err =~ s/DBD::mysql::dbh? \S+ failed:\s*//;
            mycroak "ERROR executing $sub(): $err";
        }

        return ($wa ? @ret : $ret);
    };

    #arn "created method $sub, calling";

    return $_self->$sub(@_);
}
# }}}

# check_warnings {{{
sub check_warnings {
    my $this = shift;
    my $sth  = $this->ready("show warnings");

    # mysql> show warnings;
    # +---------+------+------------------------------------------+
    # | Level   | Code | Message                                  |
    # +---------+------+------------------------------------------+
    # | Warning | 1265 | Data truncated for column 'var' at row 1 |
    # +---------+------+------------------------------------------+

    my @warnings;

    execute $sth or die $this->errstr;
    while( my $a = fetchrow_arrayref $sth ) {
        push @warnings, $a;
    }
    finish $sth;

    if( @warnings ) {
        $@ = join("\n", map("$_->[0]($_->[1]): $_->[2]", @warnings)) . "\n";

        return 0;
    }

    return 1;
}
# }}}
# new {{{
sub new {
    my $this = shift;

    $this = bless {}, $this;

    $this->{dbase} = shift; mycroak "dbase = '$this->{dbase}'?" unless $this->{dbase};
    $this->{dbh} = $this->{dbase} if ref($this->{dbase}) and $this->{dbase}->isa("DBI::db");

    my $args = shift;
    my $tr   = ref($args) ? delete $args->{trace} : $args;

    $this->trace($tr) if $tr and $this->{dbh};

    if( ref $args ) {
        for my $k (keys %$args) {
            my $f;

            if( $this->can($f = "set_$k") ) {
                $this->$f($args->{$k});

            } else {
                mycroak "unrecognized attribute: $k"
            }
        }
    }

    return $this;
}
# }}}
# do {{{
sub do {
    my $this = shift; return unless @_;
    my $sql  = shift;
    my $r; eval { $r = $this->ready($sql)->execute(@_); 1 } or mycroak $@;
    return $r;
}
# }}}
# light_lock {{{
sub light_lock {
    my $this   = shift; return unless @_;
    my $tolock = join(", ", map("$_ read", @_));

    $this->do("lock tables $tolock");
}
# }}}
# lock {{{
sub lock {
    my $this   = shift; return unless @_;
    my $tolock = join(", ", map("$_ write", @_));

    $this->do("lock tables $tolock");
}
# }}}
# unlock {{{
sub unlock {
    my $this = shift;

    $this->do("unlock tables");
}
# }}}
# ready {{{
sub ready {
    my $this = shift;

    my $i = 0;
    my $sth = MySQL::Easy::sth->new( $this, @_ );
       $sth->{_ready_caller} = [ caller(  $i) ];
       $sth->{_ready_caller} = [ caller(++$i) ] while $sth->{_ready_caller}[0] eq __PACKAGE__;

    return $sth;
}
# }}}
# firstcol {{{
sub firstcol {
    my $this = shift;
    my $query = shift;

    my $r;
    eval { $r = $this->selectcol_arrayref($query, undef, @_); 1 }
        or mycroak $@;

    return wantarray ? @$r : $r;
}
# }}}
# firstval {{{
sub firstval {
    my $this = shift;
    my $query = shift;

    my $r;
    eval { $r = $this->selectcol_arrayref($query, undef, @_); 1 }
        or mycroak $@;

    return $r->[0];
}
# }}}
# firstrow {{{
sub firstrow {
    my $this = shift;
    my $query = shift;

    my $r;
    eval { $r = $this->selectrow_arrayref($query, undef, @_); 1 }
        or mycroak $@;

    return wantarray ? @$r : $r;
}
# }}}
# thread_id {{{
sub thread_id {
    my $this = shift;

    return $this->handle->{mysql_thread_id};
}
# }}}
# last_insert_id {{{
sub last_insert_id {
    my $this = shift;

    # return $this->firstcol("select last_insert_id()")->[0];
    # return $this->handle->{mysql_insertid};
    return $this->handle->last_insert_id(undef,undef,undef,undef);
}
# }}}
# DESTROY {{{
sub DESTROY {
    my $this = shift;

    $this->{dbh}->disconnect if $this->{dbh};
}
# }}}
# handle {{{
sub handle {
    my $this = shift;

    return $this->{dbh} if defined($this->{dbh}) and $this->{dbh}->ping;
    # warn "WARNING: MySQL::Easy is trying to reconnect (if possible)" if defined $this->{dbh};

    ($this->{user}, $this->{pass}) = $this->unp unless $this->{user} and $this->{pass};

    $this->{host}  = "localhost" unless $this->{host};
    $this->{port}  =      "3306" unless $this->{port};
    $this->{dbase} =      "test" unless $this->{dbase};
    $this->{trace} =           0 unless $this->{trace};

    if( $this->{dbh} ) {
        eval {
            local $SIG{__WARN__} = sub {};  # Curiously, sometimes we do have a handle, but the ping doesn't work.
                                            # If we replace the handle, DBI complains about not disconnecting.
                                            # If we disconnect, it complains about not desting statement handles.
                                            # Heh.  It's gone dude, let it go.
            $this->{dbh}->disconnect;
        };
    }

    $this->{dbh} =
    DBI->connect("DBI:mysql:$this->{dbase}:host=$this->{host}:port=$this->{port}",
        $this->{user}, $this->{pass}, {

            RaiseError => ($this->{raise} ? 1:0),
            PrintError => ($this->{raise} ? 0:1),

            AutoCommit => 0,

            mysql_enable_utf8    => 1,
            mysql_compression    => 1,
            mysql_ssl            => 1,
            mysql_auto_reconnect => 1,

        });

    mycroak "failed to generate connection: " . DBI->errstr unless $this->{dbh};

    $this->{dbh}->trace($this->{trace});

    return $this->{dbh};
}
# }}}
# unp {{{
sub unp {
    my $this = shift;

    return ($ENV{$USER_ENV}, $ENV{$PASS_ENV}) if $ENV{$USER_ENV} and $ENV{$PASS_ENV};

    my ($user, $pass, $file, $fh);

    for $file (@MY_CNF_LOCATIONS) {
        next unless -f $file;
        next unless open $fh, $file;

        while(<$fh>) {
            $user = $1 if m/user\s*=\s*(.+)/;
            $pass = $1 if m/password\s*=\s*(.+)/;

            return ($user, $pass) if $user and $pass;
        }
    }

    die "unable to locate a username and password\n";
    return;
}
# }}}
# set_host set_user set_pass {{{
sub set_host {
    my $this = shift;

    $this->{host} = shift;
}

sub set_port {
    my $this = shift;

    $this->{port} = shift;
}

sub set_user {
    my $this = shift;

    $this->{user} = shift;
}

sub set_pass {
    my $this = shift;

    $this->{pass} = shift;
}

sub set_raise {
    my $this = shift;

    $this->{raise} = shift;
}
# }}}
# bind_execute {{{
sub bind_execute {
    my $this = shift;
    my $sql  = shift;

    my $sth = $this->ready($sql);

    $sth->execute            or return;
    $sth->bind_columns( @_ ) or return;

    return $sth;
}
# }}}

1;
