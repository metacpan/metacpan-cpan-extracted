use strict;
use warnings;
use Test::More;
use Test::Database::Handle;

use DBI;
use File::Spec;
use File::Temp qw( tempdir );

my $dir = tempdir( CLEANUP => 1 );
my $db = File::Spec->catfile( $dir, 'db.sqlite' );

my $dsn = "dbi:SQLite:$db";
my $dbh;
eval { $dbh = DBI->connect($dsn) }
    or plan skip_all => 'DBD::SQLite needed for this test';

# some SQL statements to try out
my @sql = (
    q{CREATE TABLE users (id INTEGER, name VARCHAR(64))},
    q{INSERT INTO users (id, name) VALUES (1, 'book')},
    q{INSERT INTO users (id, name) VALUES (2, 'echo')},
);
my $select = "SELECT id, name FROM users";

plan tests => @sql + 4;

# create some information
ok( $dbh->do($_), $_ ) for @sql;

# create handle
my $handle = Test::Database::Handle->new( dsn => $dsn );

is_deeply(
    [ $handle->connection_info() ],
    [ $dsn, undef, undef ],
    'connection_info()'
);
isa_ok( my $dbh2 = $handle->dbh(), 'DBI::db' );
cmp_ok( $handle->dbh(), 'eq', $dbh2, 'cached dbh' );

# check the data is there
my $lines = $dbh->selectall_arrayref($select);
is_deeply( $lines, [ [ 1, 'book' ], [ 2, 'echo' ] ], $select );

