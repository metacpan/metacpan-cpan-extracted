#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::HexString;
use IO::Socket::IP;

use Net::Gearman::Client;

my $listener = IO::Socket::IP->new(
   LocalPort => 0,
   Listen => 1,
) or die "Cannot listen - $!";

my $client = Net::Gearman::Client->new(
   PeerHost    => $listener->sockhost,
   PeerService => $listener->sockport,
);

ok( defined $client, 'defined $client' );

my $server = $listener->accept or die "Cannot accept - $!";

my $f = $client->submit_job(
   func => "function",
   arg  => "argument",
);

$server->sysread( my $buffer, 8192 );

is_hexstr( $buffer, "\0REQ\0\0\0\x07\0\0\0\x13function\x000\0argument",
   'SUBMIT_JOB request written to buffer' );

$server->syswrite( "\0RES\0\0\0\x08\0\0\0\x02id" );
$server->syswrite( "\0RES\0\0\0\x0d\0\0\0\x09id\0result" );

is_deeply( [ $f->get ], [ "result" ], '$f->get' );

done_testing;
