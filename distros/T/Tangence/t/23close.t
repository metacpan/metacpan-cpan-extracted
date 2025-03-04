#!/usr/bin/perl

use v5.26;
use warnings;

use Future::AsyncAwait 0.47;

use Test2::V0;

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

my ( $conn1, $conn2 ) = map {
   my ( $server, $client ) = make_serverclient( $registry );

   my $objproxy = $client->rootobj;

   my $conn = {
      server    => $server,
      client    => $client,
      objproxy => $objproxy,
   };

   await $objproxy->watch_property( "scalar",
      on_set => sub { $conn->{scalar} = shift; },
   );

   my ( $cursor ) = await $objproxy->watch_property_with_cursor( "queue", "first",
      on_updated => sub {},
   );

   $conn
} 1 .. 2;

$obj->set_prop_scalar( 789 );

is( $conn1->{scalar}, 789, '$scalar from connection 1' );
is( $conn2->{scalar}, 789, '$scalar from connection 2' );

$conn1->{server}->tangence_closed;
$conn1->{client}->tangence_closed;

$obj->set_prop_scalar( 101112 );

is( $conn1->{scalar}, 789, '$scalar unchanged from (closed) connection 1' );
is( $conn2->{scalar}, 101112, '$scalar from connection 2' );

done_testing;
