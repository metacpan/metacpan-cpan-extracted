#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
BEGIN {
   plan skip_all => "No Test::MemoryGrowth" unless eval { require Test::MemoryGrowth };
}
use Test::MemoryGrowth;

use Tangence::Constants;
use Tangence::Registry;

use lib ".";
use t::TestObj;
use t::TestServerClient;

my $registry = Tangence::Registry->new(
   tanfile => "t/TestObj.tan",
);
my $obj = $registry->construct(
   "t::TestObj",
   scalar   => 123,
   s_scalar => 456,
);

no_growth {
   my ( $server, $client ) = make_serverclient( $registry );

   my $objproxy = $client->rootobj;

   $objproxy->watch_property( "scalar",
      on_set => sub {},
   )->get;

   $server->tangence_closed;
   $client->tangence_closed;

} calls => 1000,
   'Connect/watch/disconnect does not grow memory';

done_testing;
