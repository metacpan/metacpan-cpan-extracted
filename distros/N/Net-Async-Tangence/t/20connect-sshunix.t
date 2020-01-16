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

use Tangence::Registry;

use Net::Async::Tangence::Server;
use Net::Async::Tangence::Client;

use lib ".";
use t::TestObj;

my $loop = IO::Async::Loop->new();
testing_loop( $loop );

my $client = Net::Async::Tangence::Client->new;
$loop->add( $client );

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

my $path = "t/test.sock";
END { unlink $path if -e $path }

eval {
   $server->listen(
      addr => { family => "unix", path => $path }
   )->get; 1;
} or plan skip_all => "Unable to listen on unix socket";

my $serverpath = File::Spec->rel2abs( $path );

$client->connect_url( "sshunix://localhost/$serverpath" )->get;
pass "Connected via SSHUNIX";

wait_for { defined $client->rootobj };

ok( defined $client->rootobj, "Negotiated rootobj" );

done_testing;
