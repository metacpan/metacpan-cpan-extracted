#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use IO::Async::Test;
use IO::Async::Loop;

use Net::Async::Tangence::Client;

my $loop = IO::Async::Loop->new();
testing_loop( $loop );

my $client = Net::Async::Tangence::Client->new;
$loop->add( $client );

my $serverpath = "t/server.pl";

eval {
   $client->connect_url( "exec:///$serverpath" )->get; 1;
} or plan skip_all => "Unable to exec $serverpath";
pass "Connected via EXEC";

wait_for { defined $client->rootobj };

ok( defined $client->rootobj, "Negotiated rootobj" );

done_testing;
