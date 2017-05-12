use Net::OpenID::JanRain::Stores::SQLStore;
package Net::OpenID::JanRain::Stores::SQLiteStore;
use DBI; 

our @ISA=qw(Net::OpenID::JanRain::Stores::SQLStore);

use strict;
use warnings;

=head1 Net::OpenID::JanRain::Stores::SQLiteStore

This store uses the SQLite2 database to store data for the JanRain OpenID
Consumer and Server.

=head2 Usage


    #Get a handle to your SQLite database:
    my $dbh = DBI->connect("dbi:SQLite2:yourdb", $un, $pw);

    #For the default table names, "settings", "associations", "nonces":
    my $store = Net::OpenID::JanRain::Stores::SQLiteStore->new($dbh);


    #If you desire to modify the table names:
    my $store = Net::OpenID::JanRain::Stores::SQLiteStore->new($dbh,
                    {settings_table => "ajustes",
                     associations_table => "asociaciones",
                     nonces_table => "absurdos"});
    #You need not modify all the table names.

    #If the database is new and these tables do not yet exist:
    $store->createTables;



=cut

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
    secret BLOB(128),
    issued INTEGER,
    lifetime INTEGER,
    assoc_type VARCHAR(64),
    PRIMARY KEY (server_url, handle)
);
',

create_settings_sql => '
CREATE TABLE <settings_table>
(
    setting VARCHAR(128) UNIQUE PRIMARY KEY,
    value BLOB(20)
);
',

create_auth_sql => 'INSERT INTO <settings_table> VALUES ("auth_key", ?);',
get_auth_sql => 'SELECT value FROM <settings_table> WHERE setting = "auth_key";',

set_assoc_sql => 'INSERT OR REPLACE INTO <assoc_table> '.
                 'VALUES (?, ?, ?, ?, ?, ?);',
get_assocs_sql => 'SELECT handle, secret, issued, lifetime, assoc_type '.
                  'FROM <assoc_table> WHERE server_url = ?;',
get_assoc_sql => 'SELECT handle, secret, issued, lifetime, assoc_type '.
            'FROM <assoc_table> WHERE server_url = ? AND handle = ?;',

remove_assoc_sql => 'DELETE FROM <assoc_table> '.
                    'WHERE server_url = ? AND handle = ?;',

add_nonce_sql => 'INSERT OR REPLACE INTO <nonce_table> VALUES (?, ?);',
get_nonce_sql => 'SELECT * FROM <nonce_table> WHERE nonce = ?;',
remove_nonce_sql => 'DELETE FROM <nonce_table> WHERE nonce = ?;',
};

# SQLite store constructor
sub new {
    my $caller = shift;
    my ($dbh, $tablenames) = @_;

    $dbh->{AutoCommit} = 1;
    $dbh->{RaiseError} = 1;
    $dbh->{sqlite_handle_binary_nulls} = 1;

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

1;
