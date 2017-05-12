#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Memory::Cycle;

use Tangence::Constants;
use Tangence::Registry;

use Struct::Dumb 0.09;  # _forbid_arrayification

use lib ".";
use t::TestObj;
use t::TestServerClient;

### TODO
# This test file relies a lot on weird logic in TestObj. Should probably instead just use 
# the object's property manip. methods directly
###

my $registry = Tangence::Registry->new(
   tanfile => "t/TestObj.tan",
);
my $obj = $registry->construct(
   "t::TestObj",
);

my ( $server, $client ) = make_serverclient( $registry );

my $proxy = $client->rootobj;

my $scalar;
my $scalar_changed = 0;
$proxy->watch_property_with_initial( "scalar",
   on_set => sub {
      $scalar = shift;
      $scalar_changed = 1
   },
)->get;

is( $scalar, "123", 'Initial value from watch_property' );

is( $proxy->prop( "scalar" ), 
   "123",
    "scalar property cache" );

my $hash_changed = 0;
$proxy->watch_property_with_initial( "hash",
   on_updated => sub { $hash_changed = 1 },
)->get;

is_deeply( $proxy->prop( "hash" ),
           { one => 1, two => 2, three => 3 },
           'hash property cache' );

my $array_changed = 0;
$proxy->watch_property_with_initial( "array",
   on_updated => sub { $array_changed = 1 },
)->get;

is_deeply( $proxy->prop( "array" ),
           [ 1, 2, 3 ],
           'array property cache' );

$obj->add_number( four => 4 );

$array_changed = 0;

is( $proxy->prop( "scalar" ), 
    "1234",
    "scalar property cache after update" );
is_deeply( $proxy->prop( "hash" ), 
           { one => 1, two => 2, three => 3, four => 4 },
           'hash property cache after update' );
is_deeply( $proxy->prop( "array" ),
           [ 1, 2, 3, 4 ],
           'array property cache after update' );

$scalar_changed = $hash_changed = $array_changed = 0;

$obj->add_number( five => 4 );

ok( !$scalar_changed, 'scalar unchanged' );
ok( !$array_changed,  'array unchanged' );
is_deeply( $proxy->prop( "hash" ),
           { one => 1, two => 2, three => 3, four => 4, five => 4 },
           'hash property cache after wrong five' );

$scalar_changed = $hash_changed = $array_changed = 0;

$obj->add_number( five => 5 );

is( $proxy->prop( "scalar" ),
    "12345",
    "scalar property cache after five" );
is_deeply( $proxy->prop( "hash" ),
           { one => 1, two => 2, three => 3, four => 4, five => 5 },
           'hash property cache after five' );
is_deeply( $proxy->prop( "array" ),
           [ 1, 2, 3, 4, 5 ],
           'array property cache after five' );

$scalar_changed = $hash_changed = $array_changed = 0;

$obj->del_number( 3 );

is( $proxy->prop( "scalar" ),
    "1245",
    "scalar property cache after delete three" );
is_deeply( $proxy->prop( "hash" ),
           { one => 1, two => 2, four => 4, five => 5 },
           'hash property cache after delete three' );
is_deeply( $proxy->prop( "array" ),
           [ 1, 2, 4, 5 ],
           'array property cache after delete three' );

# Just test this directly

$obj->set_prop_array( [ 0 .. 9 ] );

$obj->move_prop_array( 3, 2 );

is_deeply( $proxy->prop( "array" ),
           [ 0, 1, 2, 4, 5, 3, 6, 7, 8, 9 ],
           'array property cacahe after move(+2)' );

$obj->move_prop_array( 5, -2 );

is_deeply( $proxy->prop( "array" ),
           [ 0 .. 9 ],
           'array property cacahe after move(-2)' );

{
   no warnings 'redefine';
   local *Tangence::Property::Instance::_forbid_arrayification = sub {};

   memory_cycle_ok( $registry, '$registry has no memory cycles' );
   memory_cycle_ok( $obj, '$obj has no memory cycles' );
   memory_cycle_ok( $proxy, '$proxy has no memory cycles' );
}

done_testing;
