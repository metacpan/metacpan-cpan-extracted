package Net::OpenID::JanRain::Stores::SQLStore;
use Net::OpenID::JanRain::Stores;
use DBI;
use Net::OpenID::JanRain::CryptUtil qw( randomString );
our @ISA=qw(Net::OpenID::JanRain::Stores);
use warnings;
use strict;

=head1 Net::OpenID::JanRain::Stores::SQLStore

This module contains the base class for the SQL stores.  It cannot be
instantiated itself, but its included subclasses can. The library includes
three subclasses, MySQLStore, PostGreSQLStore and SQLiteStore. (link these)

=cut

sub blobDecode {
    my $self = shift;
    my ($blob) = @_;
    return $blob;
}

sub blobEncode {
    my $self = shift;
    my ($blob) = @_;
    return $blob;
}

# statement cache
# I use this instead of prepare_cached since it saves on regexp ops
sub _getSQL {
    my $self = shift;
    my ($sqlname) = @_;

    my $cache = $self->{sql_cache};

    return $cache->{$sqlname} if defined($cache->{$sqlname});

    my $sql = $self->{sqlstrings}->{$sqlname};
    $sql =~ s/<assoc_table>/$self->{assoc_table_name}/sg;
    $sql =~ s/<nonce_table>/$self->{nonce_table_name}/sg;
    $sql =~ s/<settings_table>/$self->{settings_table_name}/sg;

    my $sth = $self->{dbh}->prepare($sql);
    $cache->{$sqlname} = $sth;
    return $sth;
}

sub _execSQL {
    my $self = shift;
    my $sqlname = shift;
    my $sth = $self->_getSQL($sqlname);
    my $rv = $sth->execute(@_);
    return ($sth, $rv);
}

=head2 Interface

This class uses the interface of Net::OpenID::JanRain::Stores and
implements one additional method.

=head3 createTables

The one new external method for SQLStores.  It creates
the database tables necessary for the store to work.  It should not
be called if the tables exist already.

=cut

sub createTables {
    my $self = shift;

    my $dbh = $self->{dbh};
    eval {
	$dbh->begin_work;
        $self->_execSQL('create_nonce_sql');
        $self->_execSQL('create_assoc_sql');
        $self->_execSQL('create_settings_sql');
        $dbh->commit;
    };
    if ($@) {
        warn "Database trouble: $@";
        eval{ $dbh->rollback };
    }
}

# The following are the store methods
sub getAuthKey {
    my $self = shift;
    my $dbh = $self->{dbh};
    my $auth_key;
    eval {
        $dbh->begin_work;
        my ($sth, $foo) = $self->_execSQL('get_auth_sql');
        my $data = $sth->fetchrow_arrayref;
        if($data) {
            $auth_key = $self->blobDecode($data->[0]);
            $sth->finish;
        }
        else {
            $auth_key = randomString($self->{AUTH_KEY_LEN});
            $self->_execSQL('create_auth_sql', $auth_key);
        }
        $dbh->commit;
    };
    if ($@) {
        warn "Database trouble: $@";
        return undef;
    }
    return $auth_key;
}

#write assoc to db
sub storeAssociation {
    my $self = shift;
    my ($server_url, $assoc) = @_;

    my $dbh = $self->{dbh};
    eval {
	$dbh->begin_work;
        $self->_execSQL('set_assoc_sql', 
                        $server_url, 
                        $assoc->{handle}, 
                        $self->blobEncode($assoc->{secret}), 
                        $assoc->{issued}, 
                        $assoc->{lifetime}, 
                        $assoc->{assoc_type});
        $dbh->commit;
    };
    if ($@) {
        warn "Database trouble: $@";
        eval {$dbh->rollback};
    }
}

#read assoc from db. return undef if no exist
sub getAssociation {
    use Net::OpenID::JanRain::Association;
    my $self = shift;
    my ($server_url, $handle) = @_;
    my $dbh = $self->{dbh};
    my @associations = ();
    eval {
	$dbh->begin_work;
        my ($sth, $junk);
        if (defined($handle)) {
            ($sth, $junk) = $self->_execSQL('get_assoc_sql', $server_url, $handle);
        }
        else {
            ($sth, $junk) = $self->_execSQL('get_assocs_sql', $server_url);
        }
        #get the stuff
        while( my @row = $sth->fetchrow_array) {
            my $assoc = Net::OpenID::JanRain::Association->new(@row);
            if ($assoc->expiresIn == 0) {
                $self->_execSQL('remove_assoc_sql', 
                                $server_url,
                                $assoc->{handle});
            }
            else {
                $assoc->{secret} = $self->blobDecode($assoc->{secret});
                push @associations, $assoc;
            }
        }
        $dbh->commit;
    };
    if ($@) { #hmm
        warn "Database trouble: $@";
        eval {$dbh->rollback};
        return undef;
    }
    if (@associations) {
	@associations = sort {$a->{issued} <=> $b->{issued}} @associations if $#associations > 0;
	return pop @associations;
    }
    else {
	return undef;
    }
}

# kill!
sub removeAssociation {
    my $self = shift;
    my ($server_url, $handle) = @_;

    my $dbh = $self->{dbh};
    my ($sth, $count);
    eval {
	$dbh->begin_work;
        ($sth, $count) = $self->_execSQL('remove_assoc_sql', $server_url, $handle);
        $dbh->commit;
    };
    if ($@) {
        warn "Database trouble: $@";
        eval {$dbh->rollback};
    }
    return ($count > 0);
}

# add nonce to db. ignore if present
sub storeNonce {
    my $self = shift;
    my ($nonce) = @_;

    my $dbh = $self->{dbh};
    eval {
	$dbh->begin_work;
        $self->_execSQL('add_nonce_sql', $nonce, time);
        $dbh->commit;
    };
    if ($@) {
        warn "Database trouble: $@";
        eval {$dbh->rollback};
    }
}

# return true if nonce is present, false otherwise
sub useNonce {
    my $self = shift;
    my ($nonce) = @_;
    my $dbh = $self->{dbh};
    my $present = 0;
    eval {
	$dbh->begin_work;
        my ($sth, $foo) = $self->_execSQL('get_nonce_sql', $nonce);
        my $row = $sth->fetchrow_arrayref;
        if (defined($row)) {
            my ($crap, $timestamp) = @$row;
            my $nonce_age = time - $timestamp;
            $present = ($nonce_age < $self->{max_nonce_age});
            $self->_execSQL('remove_nonce_sql', $nonce);
        }
        $dbh->commit;
    };
    if ($@) {
        warn "Database trouble: $@";
        eval{$dbh->rollback};
    }
    return $present;
}

# this one's easy.
sub isDumb {
    return undef;
}

1;


