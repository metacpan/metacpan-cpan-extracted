#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

BEGIN {
   $ENV{CAN_SSH_LOCALHOST} or
      plan skip_all => 'set CAN_SSH_LOCALHOST=1 to test ssh to localhost';

   open( my $sshfd, "-|", qw( ssh localhost perl -e ), q('print "YES\n"') ) or
      plan skip_all => "Unable to ssh localhost and exec perl";

   <$sshfd> eq "YES\n" or
      plan skip_all => "Received incorrect response from ssh perl";
}

use File::Spec;
use IO::Async::Test;
use IO::Async::Loop;

use Net::Async::Tangence::Client;

my $loop = IO::Async::Loop->new();
testing_loop( $loop );

my $client = Net::Async::Tangence::Client->new;
$loop->add( $client );

my $serverpath = File::Spec->rel2abs( "t/server.pl" );

$client->connect_url( "sshexec://localhost/$serverpath" )->get;
pass "Connected via SSHEXEC";

wait_for { defined $client->rootobj };

ok( defined $client->rootobj, "Negotiated rootobj" );

done_testing;
