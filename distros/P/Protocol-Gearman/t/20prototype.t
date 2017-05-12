#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::HexString;

use Future;

use Protocol::Gearman;

my $sent = "";
my $next_future;

my $gearman = Protocol::Gearman->new_prototype(
   send       => sub { $sent .= $_[1] },
   new_future => sub { $next_future = Future->new },
);

ok( defined $gearman, '$gearman defined' );

# send
{
   $gearman->send_packet( SUBMIT_JOB => "func", "id", "ARGS" );

   is_hexstr( $sent, "\0REQ\0\0\0\x07\0\0\0\x0cfunc\0id\0ARGS",
      'data written by ->send_packet' );
}

# new_future
{
   my $f = $gearman->new_future;

   is( $next_future, $f, '$next_future is $f' );
}

done_testing;
