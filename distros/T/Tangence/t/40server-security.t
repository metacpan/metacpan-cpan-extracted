#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

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
);
# generate a second object that exists but we don't tell the client about
my $obj2 = $registry->construct(
   "t::TestObj",
);

my ( $server, $client ) = make_serverclient( $registry );

my $proxy = $client->rootobj;

# gutwrench into the objectproxy to make a new one with a different ID
$proxy->{id} == $obj->id or die "ARGH failed to have correct object ID in proxy";

my $proxy2 = { %$proxy, id => $obj2->id };
bless $proxy2, ref $proxy;

# $proxy2 should now not work for anything

# methods
{
   my $f = $proxy2->call_method( "method", 0, "" );

   like( $f->failure, qr/^Access not allowed to object with id 2/,
      'unseen objects inaccessible by method' );
}

# events
{
   my $f = $proxy2->subscribe_event( "event", on_fire => sub {} );

   like( $f->failure, qr/^Access not allowed to object with id 2/,
      'unseen objects inaccessible by event' );
}

# properties
{
   my $f = $proxy2->get_property( "scalar" );

   like( $f->failure, qr/^Access not allowed to object with id 2/,
      'unseen objects inaccessible by property get' );

   $f = $proxy2->set_property( "scalar", 123 );

   like( $f->failure, qr/^Access not allowed to object with id 2/,
      'unseen objects inaccessible by property set' );

   $f = $proxy2->watch_property( "scalar", on_set => sub {} );

   like( $f->failure, qr/^Access not allowed to object with id 2/,
      'unseen objects inaccessible by property watch' );
}

# as argument to otherwise-allowed object
{
   $proxy->set_property( "objset", [ $proxy ] )->get; # is allowed

   my $f = $proxy->set_property( "objset", [ $proxy2 ] );

   like( $f->failure, qr/^Access not allowed to object with id 2/,
      'unseen objects not allowed by value' );
}

done_testing;
