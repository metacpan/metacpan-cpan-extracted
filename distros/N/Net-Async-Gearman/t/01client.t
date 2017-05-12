#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::HexString;
use IO::Async::Test;
use IO::Async::Loop;
use IO::Async::OS;

use Net::Async::Gearman::Client;

my $loop = IO::Async::Loop->new;
testing_loop( $loop );

my ( $S1, $S2 ) = IO::Async::OS->socketpair or die "Cannot socketpair - $!";

my $client = Net::Async::Gearman::Client->new(
   handle => $S1,
);

ok( defined $client, 'defined $client' );

$loop->add( $client );

my $f = $client->submit_job(
   func => "function",
   arg  => "argument",
);

my $buffer = "";
wait_for_stream { length $buffer >= 12+0x13 } $S2 => $buffer;

is_hexstr( $buffer, "\0REQ\0\0\0\x07\0\0\0\x13function\x000\0argument",
   'SUBMIT_JOB request written to buffer' );

$S2->syswrite( "\0RES\0\0\0\x08\0\0\0\x02id" );
$S2->syswrite( "\0RES\0\0\0\x0d\0\0\0\x09id\0result" );

wait_for { $f->is_ready };

is_deeply( [ $f->get ], [ "result" ], '$f->get' );

done_testing;
