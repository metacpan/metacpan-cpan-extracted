#!/usr/bin/env perl
#
# $Id$

BEGIN {
    require Test::More;
    if ( eval { require DBD::SQLite } ) {
        Test::More->import( tests => 10 );
    }
    else {
        Test::More->import( skip_all => 'No SQLite driver' );
    }
}

### Test RDB class using in-core scratch db
package My::Test::RDB;

use 5.010;
use parent 'Rose::DB';

__PACKAGE__->use_private_registry;

__PACKAGE__->register_db(
    domain   => 'test',
    type     => 'vapor',
    driver   => 'SQLite',
    database => ':memory:',
);

# SQLite in-memory db evaporates when original dbh is closed.
sub dbi_connect {
    my ( $self, @args ) = @_;
    state $dbh = $self->SUPER::dbi_connect(@args);
    $dbh;
}

### Test cannery
package My::Cannery;
use Rose::DBx::CannedQuery;
use Rose::DBx::Role::QueryCannery;
use Moo 2;
Rose::DBx::Role::QueryCannery->apply(
    {
        query_class => 'Rose::DBx::CannedQuery',
        rdb_class   => 'My::Test::RDB',
        rdb_params  => { domain => 'test', type => 'vapor' }
    }
);

package main;

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

### And now, the real tests
my $qry = My::Cannery->get_query('SELECT * FROM test WHERE color = ?');
isa_ok( $qry, 'Rose::DBx::CannedQuery' );

is( $qry->rdb_class, 'My::Test::RDB', 'RDB class name' );
is_deeply(
    $qry->rdb_params,
    { domain => 'test', type => 'vapor' },
    'RDB parameter attributes'
);
is( $qry->sql, 'SELECT * FROM test WHERE color = ?', 'Query SQL' );

is(
    $qry,
    Rose::DBx::CannedQuery->new_or_cached(
        rdb_class  => 'My::Test::RDB',
        rdb_params => { domain => 'test', type => 'vapor' },
        sql        => 'SELECT * FROM test WHERE color = ?'
    ),
    'query was cached'
);

is(
    $qry,
    My::Cannery->get_query('SELECT * FROM test WHERE color = ?'),
    'and get_query retrieved it'
);

is_deeply(
    [ $qry->results('red') ],
    [
        { id => 2, name => 'fidget', color => 'red' },
        { id => 4, name => 'gidget', color => 'red' },
    ],
    'query results'
);

$qry = My::Cannery->build_query('SELECT * FROM test WHERE color = ?');

isnt(
    $qry,
    My::Cannery->get_query('SELECT * FROM test WHERE color = ?'),
    'build_query does not hit cache'
);

$qry = My::Cannery->build_query('SELECT * FROM test WHERE color = "blue"');

isnt(
    $qry,
    Rose::DBx::CannedQuery->new_or_cached(
        rdb_class  => 'My::Test::RDB',
        rdb_params => { domain => 'test', type => 'vapor' },
        sql        => 'SELECT * FROM test WHERE color = "blue"'
    ),
    'and does not cache its result'
);
