#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::HexString;
use IO::Socket::IP;

use Net::Gearman::Worker;

my $listener = IO::Socket::IP->new(
   LocalPort => 0,
   Listen => 1,
) or die "Cannot listen - $!";

my $worker = Net::Gearman::Worker->new(
   PeerHost    => $listener->sockhost,
   PeerService => $listener->sockport,
);

ok( defined $worker, 'defined $worker' );

my $server = $listener->accept or die "Cannot accept - $!";

my $job;

# grab_job
{
   my $f = $worker->grab_job;

   $server->sysread( my $buffer, 8192 );

   is_hexstr( $buffer, "\0REQ\0\0\0\x09\0\0\0\0" );

   $server->syswrite( "\0RES\0\0\0\x0b\0\0\0\x0eH:c:1\0func\0arg" );

   $job = $f->get;

   ok( defined $job, '$job defined' );

   is( $job->func, "func" );
   is( $job->arg,  "arg" );
}

# $job->complete
{
   $job->complete( "result" );

   $server->sysread( my $buffer, 8192 );

   is_hexstr( $buffer, "\0REQ\0\0\0\x0d\0\0\0\x0cH:c:1\0result" );
}

done_testing;
