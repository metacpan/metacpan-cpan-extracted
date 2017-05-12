package Net::OpenID::JanRain::Stores::PostgreSQLStore;
use DBI;
use DBD::Pg;
use Net::OpenID::JanRain::Stores::SQLStore;
use Net::OpenID::JanRain::CryptUtil qw( randomString );
our @ISA=qw(Net::OpenID::JanRain::Stores::SQLStore);

# SQL code template strings
my $sqlstrings = {
create_nonce_sql => '
CREATE TABLE <nonce_table>
(
    nonce CHAR(8) UNIQUE PRIMARY KEY,
    expires INTEGER
);
',

create_assoc_sql => '
CREATE TABLE <assoc_table>
(
    server_url VARCHAR(2047),
    handle VARCHAR(255),
    secret BYTEA,
    issued INTEGER,
    lifetime INTEGER,
    assoc_type VARCHAR(64),
    PRIMARY KEY (server_url, handle),
    CONSTRAINT secret_length_constraint CHECK (LENGTH(secret) <= 128)
);
',

create_settings_sql => '
CREATE TABLE <settings_table>
(
    setting VARCHAR(128) UNIQUE PRIMARY KEY,
    value BYTEA,
    CONSTRAINT value_length_constraint CHECK (LENGTH(value) <= 20)
);
',

create_auth_sql => "INSERT INTO <settings_table> VALUES ('auth_key', ?);",
get_auth_sql => "SELECT value FROM <settings_table> WHERE setting = 'auth_key';",

new_assoc_sql => 'INSERT INTO <assoc_table> '.
                 'VALUES (?, ?, ?, ?, ?, ?);',
update_assoc_sql => 'UPDATE <assoc_table> SET '.
                       'secret = (?), issued = ?, '.
                       'lifetime = ?, assoc_type = ? '.
                       'WHERE server_url = ? AND handle = ?;',
get_assocs_sql => 'SELECT handle, secret, issued, lifetime, assoc_type '.
                  'FROM <assoc_table> WHERE server_url = ?;',
get_assoc_sql => 'SELECT handle, secret, issued, lifetime, assoc_type '.
            'FROM <assoc_table> WHERE server_url = ? AND handle = ?;',

remove_assoc_sql => 'DELETE FROM <assoc_table> '.
                    'WHERE server_url = ? AND handle = ?;',

update_nonce_sql => 'UPDATE <nonce_table> SET expires = ? WHERE nonce = ?;',
new_nonce_sql => 'INSERT INTO <nonce_table> VALUES (?, ?);',
get_nonce_sql => 'SELECT * FROM <nonce_table> WHERE nonce = ?;',
remove_nonce_sql => 'DELETE FROM <nonce_table> WHERE nonce = ?;',
};

=head1 Net::OpenID::JanRain::Stores::PostgreSQLStore

This module contains the PostGreSQL OpenID Store.

=head2 Usage

    #Get a handle to your PostgreSQL database:
    my $dbh = DBI->connect("dbi:Pg:yourdb", $un, $pw);

    #For the default table names, "settings", "associations", "nonces":
    my $store = Net::OpenID::JanRain::Stores::PostgreSQLStore->new($dbh);


    #If you desire to modify the table names:
    my $store = Net::OpenID::JanRain::Stores::PostgreSQLStore->new($dbh,
                    {settings_table => "ajustes",
                     associations_table => "asociaciones",
                     nonces_table => "absurdos"});
    #You need not modify all the table names.

    #If the database is new and these tables do not yet exist:
    $store->createTables;


=cut


# Postgres constructor
sub new {
    my $caller = shift;
    my ($dbh, $tablenames) = @_;

    $dbh->{AutoCommit} = 1;
    $dbh->{RaiseError} = 1;
    $dbh->{PrintWarn} = 0;

    my $class = ref($caller) || $caller;

    defined($tablenames) or $tablenames = {};

    my $settings_table = ($tablenames->{settings_table} || 'settings');
    my $assoc_table = ($tablenames->{assoc_table} || 'associations');
    my $nonce_table = ($tablenames->{nonce_table} || 'nonces');

    my $self = {
        settings_table_name => $settings_table,
        assoc_table_name => $assoc_table,
        nonce_table_name => $nonce_table,
        max_nonce_age => 6 * 60 * 60, # six hours in seconds
        sql_cache => {},
        dbh => $dbh,
        AUTH_KEY_LEN => 20,
        sqlstrings => $sqlstrings
    };

    bless($self, $class);
}

# Postgres has no REPLACE INTO, and is picky about binary data.
sub storeAssociation {
    my $self = shift;
    my ($server_url, $assoc) = @_;

    my $dbh = $self->{dbh};
    eval {
	$dbh->begin_work;
        # first check if there is such an association already
        # unfortunately select does not give us reliable row number info
        my ($sth, $junk) = $self->_execSQL('get_assoc_sql',
                                           $server_url,
                                           $assoc->{handle});
        my $rows = $sth->fetchall_arrayref;
        if(@$rows) { # update existing assoc
            # We need to give some special treatment here
            $sth = $self->_getSQL('update_assoc_sql');
            $sth->bind_param(1, $assoc->{secret}, 
                        { pg_type => DBD::Pg::PG_BYTEA });
            $sth->bind_param(2, $assoc->{issued});
            $sth->bind_param(3, $assoc->{lifetime});
            $sth->bind_param(4, $assoc->{assoc_type});
            $sth->bind_param(5, $server_url);
            $sth->bind_param(6, $assoc->{handle});
            $rv = $sth->execute;
        }
        else { # Create a new assoc
            $sth = $self->_getSQL('new_assoc_sql');
            $sth->bind_param(1, $server_url);
            $sth->bind_param(2, $assoc->{handle});
            $sth->bind_param(3, $assoc->{secret}, 
                        { pg_type => DBD::Pg::PG_BYTEA });
            $sth->bind_param(4, $assoc->{issued});
            $sth->bind_param(5, $assoc->{lifetime});
            $sth->bind_param(6, $assoc->{assoc_type});
            $rv = $sth->execute;
        }
        $dbh->commit;
    };
    if ($@) {
        warn "Database trouble: $@";
        eval {$dbh->rollback};
    }
}

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
            my $sth = $self->_getSQL('create_auth_sql');
            $sth->bind_param(1, $auth_key, { pg_type => DBD::Pg::PG_BYTEA });
            $sth->execute;
        }
        $dbh->commit;
    };
    if ($@) {
        warn "Database trouble: $@";
        return undef;
    }
    return $auth_key;
}


sub storeNonce {
    my $self = shift;
    my ($nonce) = @_;

    my $dbh = $self->{dbh};
    eval {
	$dbh->begin_work;
        my ($sth, $junk) = $self->_execSQL('get_nonce_sql', $nonce);
        my $rows = $sth->fetchall_arrayref;
        if(@$rows) { # update existing assoc
            $self->_execSQL('update_nonce_sql', time, $nonce);
        }
        else {
            $self->_execSQL('new_nonce_sql', $nonce, time);
        }
        $dbh->commit;
    };
    if ($@) {
        warn "Database trouble: $@";
        eval {$dbh->rollback};
    }
}




1;
