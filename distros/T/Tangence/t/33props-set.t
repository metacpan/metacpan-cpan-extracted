#!/usr/bin/perl

use v5.26;
use warnings;

use Future::AsyncAwait 0.47;

use Test2::V0;

use Tangence::Registry;

use lib ".";
use t::TestObj;
use t::TestServerClient;

my $registry = Tangence::Registry->new(
   tanfile => "t/TestObj.tan",
);
my $obj = $registry->construct(
   "t::TestObj",
);

my ( $server, $client ) = make_serverclient( $registry );

my $proxy = $client->rootobj;

# scalar
{
   await $proxy->set_property( "scalar", 456 );

   is( $obj->get_prop_scalar, 456, 'set_property on scalar' );
}

# array
{
   await $proxy->set_property( "array", [ 4, 5, 6 ] );

   is( $obj->get_prop_array, [ 4, 5, 6 ], 'set_property on array' );
}

# queue
{
   await $proxy->set_property( "queue", [ 4, 5, 6 ] );

   is( $obj->get_prop_queue, [ 4, 5, 6 ], 'set_property on queue' );
}

# hash
{
   await $proxy->set_property( "hash", { four => 4, five => 5 } );

   is( $obj->get_prop_hash, { four => 4, five => 5 }, 'set_property on hash' );
}

done_testing;
