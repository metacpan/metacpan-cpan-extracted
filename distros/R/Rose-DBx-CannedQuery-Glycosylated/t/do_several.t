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
    $sweet->do_many_queries(
        {
            first => [ ['red'], [ [] ] ],
            second => ['green'],
        }
    ),
    {
        first => [ [ 2, 'fidget', 'red' ], [ 4, 'gidget', 'red' ] ],
        second => [ { id => 3, name => 'midget', color => 'green' } ],
    },
    'do_many_queries named'
);

is_deeply(
    $sweet->do_many_queries( [ [ ['red'], 1 ], ['green'] ] ),
    [
        [ { id => 2, name => 'fidget', color => 'red' } ],
        [ { id => 3, name => 'midget', color => 'green' } ],
    ],
    'do_many_queries anonymous array'
);

$sweet = new_ok(
    'Rose::DBx::CannedQuery::Glycosylated' => [
        rdb_class  => 'My::Test::RDB',
        rdb_params => {
            domain => 'test',
            type   => 'vapor'
        },
        sql => 'SELECT * FROM test WHERE color = "blue"'
    ],
    'Create object (no bind values)'
);

is_deeply(
    $sweet->do_many_queries(),
    [ [ { id => 1, name => 'widget', color => 'blue' } ] ],
    'do_many_queries (no bind values)'
);

is_deeply(
    $sweet->do_many_queries( [ [ [], [ [] ] ] ] ),
    [ [ [ 1, 'widget', 'blue' ] ] ],
    'do_many_queries (no bind values, array result)'
);

done_testing;
