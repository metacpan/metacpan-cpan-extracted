#!perl
use strict;
use warnings;
use Net::FleetDB;
use Test::Exception;
use Test::More;

my $fleetdb;
eval { $fleetdb = Net::FleetDB->new( host => '127.0.0.1', port => 3400 ); };

plan skip_all => "Local FleetDB needed for testing: $@" if $@;
plan tests => 15;

is( $fleetdb->query('ping'), 'pong', '["ping"]' );

throws_ok( sub { $fleetdb->query('NOTAMETHOD') },
    qr/Malformed query: unrecognized query type '"NOTAMETHOD"'/ );

$fleetdb->query( 'delete', 'people_test' );
$fleetdb->query( 'drop-index', 'people_test', 'name' );
is( $fleetdb->query( 'count', 'people_test' ), 0, '["count","people_test"]' );

is( $fleetdb->query(
        'insert', 'people_test', { 'id' => 1, 'name' => 'Bob' }
    ),
    1,
    '["insert","people_test",{"name":"Bob","id":1}]'
);
is( $fleetdb->query( 'count', 'people_test' ), 1, '["count","people_test"]' );

is( $fleetdb->query(
        'update', 'people_test', { 'id' => 1, 'name' => 'Bobby' }
    ),
    1,
    '["update","people_test",{"name":"Bobby","id":1}]'
);
is( $fleetdb->query( 'count', 'people_test' ), 1, '["count","people_test"]' );

is( $fleetdb->query(
        'insert', 'people_test',
        [ { 'id' => 2, 'name' => 'Bob2' }, { 'id' => 3, 'name' => 'Amy' } ]
    ),
    2,
    '["insert","people_test",[{"name":"Bob2","id":2},{"name":"Amy","id":3}]]'
);
is( $fleetdb->query( 'count', 'people_test' ), 3, '["count","people_test"]' );
is( $fleetdb->query(
        'count', 'people_test', { 'where' => [ '>', 'id', 2 ] }
    ),
    1,
    '["count","people_test",{"where":[">","id",2]}]'
);

is( $fleetdb->query( 'create-index', 'people_test', 'name' ),
    1, '["create-index","people_test","name"]' );

is_deeply(
    $fleetdb->query(
        'select', 'people_test', { 'order' => [ 'id', 'asc' ] }
    ),
    [   { 'id' => 1, 'name' => 'Bobby' },
        { 'id' => 2, 'name' => 'Bob2' },
        { 'id' => 3, 'name' => 'Amy' },
    ],
    '["select","people_test",{"order":["id","asc"]}]'
);

is_deeply(
    $fleetdb->query(
        'select', 'people_test', { 'order' => [ 'name', 'asc' ] }
    ),
    [   { 'id' => 3, 'name' => 'Amy' },
        { 'id' => 2, 'name' => 'Bob2' },
        { 'id' => 1, 'name' => 'Bobby' },
    ],
    '["select","people_test",{"order":["name","asc"]}]'
);

is( $fleetdb->query(
        'delete', 'people_test', { 'where' => [ '=', 'name', 'Bobby' ] }
    ),
    1,
    '["delete","people_test",{"where":["=","name","Bobby"]}]'
);
is( $fleetdb->query( 'count', 'people_test' ), 2, '["count","people_test"]' );
