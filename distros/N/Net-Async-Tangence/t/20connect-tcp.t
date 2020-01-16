#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use IO::Async::Test;
use IO::Async::Loop;

use Tangence::Registry;

use Net::Async::Tangence::Server;
use Net::Async::Tangence::Client;

use lib ".";
use t::TestObj;

my $loop = IO::Async::Loop->new();
testing_loop( $loop );

my $registry = Tangence::Registry->new(
   tanfile => "t/TestObj.tan",
);
my $obj = $registry->construct(
   "t::TestObj",
   scalar   => 123,
   s_scalar => 456,
);
my $server = Net::Async::Tangence::Server->new(
   registry => $registry,
);
$loop->add( $server );

eval {
   $server->listen( addr => { family => "inet" } )->get; 1;
} or plan skip_all => "Unable to listen on inet socket";

my $host = $server->read_handle->sockhost;
my $port = $server->read_handle->sockport;

my $client = Net::Async::Tangence::Client->new;
$loop->add( $client );

$client->connect_url( "tcp://${host}:${port}/" )->get;
pass "Connected via TCP";

wait_for { defined $client->rootobj };

ok( defined $client->rootobj, "Negotiated rootobj" );

done_testing;
