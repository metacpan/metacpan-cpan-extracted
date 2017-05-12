#!/usr/bin/env perl

use Test::More;

unless ( eval { require DBD::SQLite } ) {
    plan( skip_all => 'No SQLite driver' );
    exit 0;
}

### Test RDB class using in-core scratch db
package My::Test::RDB;

use parent 'Rose::DB';

__PACKAGE__->use_private_registry;

__PACKAGE__->register_db(
    domain   => 'test',
    type     => 'vapor',
    driver   => 'SQLite',
    database => ':memory:',
);

# SQLite in-memory db evaporates when original dbh is closed.
{
    my $dbh;

    sub dbi_connect {
        my ( $self, @args ) = @_;
        $dbh = $self->SUPER::dbi_connect(@args) unless $dbh;
        $dbh;
    }
}

### And then, the rest of the tests
package main;

require Rose::DBx::CannedQuery::Glycosylated;

# Set up the test environment
my $rdb = new_ok(
    'My::Test::RDB' => [
        connect_options => { RaiseError => 1 },
        domain          => 'test',
        type            => 'vapor'
    ],
    'Setup test db'
);
my $dbh = $rdb->dbh;
$dbh->do(
    'CREATE TABLE test ( id INTEGER PRIMARY KEY,
                              name VARCHAR(16),
                              color VARCHAR(8) );'
);
foreach my $data (
    [ 1, q{'widget'}, q{'blue'} ],
    [ 2, q{'fidget'}, q{'red'} ],
    [ 3, q{'midget'}, q{'green'} ],
    [ 4, q{'gidget'}, q{'red'} ]
  )
{
    $dbh->do( q[INSERT INTO test VALUES ( ] . join( ',', @$data ) . ' );' );
}

# . . . and start the testing
my $sweet = new_ok(
    'Rose::DBx::CannedQuery::Glycosylated' => [
        rdb_class  => 'My::Test::RDB',
        rdb_params => {
            domain => 'test',
            type   => 'vapor'
        },
        sql => 'SELECT * FROM test WHERE color = ?'
    ],
    'Create object'
);

is_deeply(
    [ $sweet->do_one_query('red') ],
    [
        { id => 2, name => 'fidget', color => 'red' },
        { id => 4, name => 'gidget', color => 'red' },
    ],
    'do_one_query'
);

is_deeply(
    $sweet->do_one_query_ref( ['red'] ),
    [
        { id => 2, name => 'fidget', color => 'red' },
        { id => 4, name => 'gidget', color => 'red' },
    ],
    'do_one_query_ref() - hashref'
);

is_deeply(
    $sweet->do_one_query_ref( ['red'], [ [1] ] ),
    [ ['fidget'], ['gidget'], ],
    'do_one_query_ref() - arrayref sliced'
);

is_deeply(
    $sweet->do_one_query_ref( ['red'], [ {}, 1 ] ),
    [ { id => 2, name => 'fidget', color => 'red' }, ],
    'do_one_query_ref() - limit to 1'
);

like( $sweet->name, qr[^SELECT \* FROM test], 'default name' );

$sweet = new_ok(
    'Rose::DBx::CannedQuery::Glycosylated' => [
        rdb_class  => 'My::Test::RDB',
        rdb_params => {
            domain => 'test',
            type   => 'vapor'
        },
        sql  => 'SELECT * FROM test WHERE color = "blue"',
        name => 'test_nobind'
    ],
    'Create object (no bind values)'
);

is_deeply(
    [ $sweet->do_one_query() ],
    [ { id => 1, name => 'widget', color => 'blue' } ],
    'do_one_query (no bind values)'
);

is( $sweet->name, 'test_nobind', 'Explicit name for query' );

done_testing;
