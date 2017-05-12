#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
BEGIN {
   plan skip_all => "No Test::MemoryGrowth" unless eval { require Test::MemoryGrowth };
}
use Test::MemoryGrowth;
use IO::Async::Test;
use IO::Async::Loop;
use IO::Async::OS;
use IO::Async::Stream;

use Tangence::Constants;
use Tangence::Registry;

use Net::Async::Tangence::Server;
use Net::Async::Tangence::Client;

use lib ".";
use t::Ball;

my $loop = IO::Async::Loop->new();
testing_loop( $loop );

my $registry = Tangence::Registry->new(
   tanfile => "t/Ball.tan",
);
my $ball = $registry->construct(
   "t::Ball",
   colour => "red",
   size   => 100,
);

my $server = Net::Async::Tangence::Server->new(
   registry => $registry,
);

$loop->add( $server );

no_growth {
   my ( $S1, $S2 ) = IO::Async::OS->socketpair() or die "Cannot create socket pair - $!";

   $server->make_new_connection( $S1 );

   my $client = Net::Async::Tangence::Client->new( handle => $S2 );
   $loop->add( $client );

   my $ballproxy;
   wait_for { $ballproxy = $client->rootobj };

   my $f = $ballproxy->watch_property( "colour",
      on_set => sub {},
   );

   wait_for { $f->is_ready };
   $f->get;

   $client->close;
   $loop->loop_once( 0 );
} calls => 100,
   'Connect/watch/disconnect does not grow memory';

done_testing;
