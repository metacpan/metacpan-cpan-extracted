#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

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
   $proxy->set_property( "scalar", 456 )->get;

   is( $obj->get_prop_scalar, 456, 'set_property on scalar' );
}

# array
{
   $proxy->set_property( "array", [ 4, 5, 6 ] )->get;

   is_deeply( $obj->get_prop_array, [ 4, 5, 6 ], 'set_property on array' );
}

# queue
{
   $proxy->set_property( "queue", [ 4, 5, 6 ] )->get;

   is_deeply( $obj->get_prop_queue, [ 4, 5, 6 ], 'set_property on queue' );
}

# hash
{
   $proxy->set_property( "hash", { four => 4, five => 5 } )->get;

   is_deeply( $obj->get_prop_hash, { four => 4, five => 5 }, 'set_property on hash' );
}

done_testing;
