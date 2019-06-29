#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Timer;

use POE;
use POE::Future;

eval { require Future::IO; require Future::IO::ImplBase; } or
   plan skip_all => "Future::IO is not available";
require Future::IO::Impl::POE;

# Quiet warning
POE::Kernel->run;

# TODO - suggest this for Test::Timer
sub time_about
{
   my ( $code, $limit, $name ) = @_;
   time_between $code, $limit * 0.9, $limit * 1.1, $name;
}

# ->sleep
{
   my $f = Future::IO->sleep( 1 );

   time_about( sub { $f->get }, 1, 'Future::IO->sleep' );
}

# ->sysread
{
   pipe my ( $rd, $wr ) or die "Cannot pipe() - $!";
   $rd->blocking( 0 );

   $wr->autoflush();
   $wr->print( "Some bytes\n" );

   my $f = Future::IO->sysread( $rd, 256 );

   is( $f->get, "Some bytes\n", 'Future::IO->sysread' );
}

# ->syswrite
{
   pipe my ( $rd, $wr ) or die "Cannot pipe() - $!";
   $wr->blocking( 0 );

   $wr->autoflush();
   1 while $wr->syswrite( "X" x 4096 ); # This will eventually return undef/EAGAIN
   $! == Errno::EAGAIN or
      die "Expected EAGAIN, got $!";

   my $f = Future::IO->syswrite( $wr, "ABCD" );

   $rd->sysread( my $buf, 4096 );

   is( $f->get, 4, 'Future::IO->syswrite' );

   1 while $rd->sysread( $buf, 4096 ) == 4096;
   is( $buf, "ABCD", 'Future::IO->syswrite wrote data' );
}

done_testing;
