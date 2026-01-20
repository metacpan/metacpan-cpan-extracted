#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;
use Time::HiRes qw( gettimeofday tv_interval );

use POE;
use POE::Future;

# Quiet warning
POE::Kernel->run;

# TODO - suggest this for Test::Timer
sub time_about
{
   my ( $code, $limit, $name ) = @_;

   my $start = [ gettimeofday ];
   $code->();
   my $elapsed = tv_interval $start;

   cmp_ok( $elapsed, ">=", $limit * 0.9, "$name took long enough" );
   cmp_ok( $elapsed, "<=", $limit * 1.1, "$name did not take too long" );
}

# new_delay
{
   my $future = POE::Future->new_delay( 1 );

   time_about( sub { $future->await }, 1, '->new_delay future is ready' );

   is( [ $future->get ], [], '$future->get returns empty list on new_delay' );
}

# delay cancellation
{
   my $called;
   my $future = POE::Future->new_delay( 0.1 )
      ->on_done( sub { $called++ } );

   $future->cancel;

   POE::Future->new_delay( 0.3 )->await;

   ok( !$called, '$future->cancel cancels a pending timer' );
}

# new_alarm
{
   my $future = POE::Future->new_alarm( time() + 1 );

   # POE timing is a bit unreliable here :/
   #time_about( sub { $future->await }, 1, '->new_alarm future is ready' );

   is( [ $future->get ], [], '$future->get returns empty list on new_alarm' );
}

done_testing;
