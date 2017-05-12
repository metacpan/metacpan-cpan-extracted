#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Timer;

use POE;
use POE::Future;

# Quiet warning
POE::Kernel->run;

# TODO - suggest this for Test::Timer
sub time_about
{
   my ( $code, $limit, $name ) = @_;
   time_between $code, $limit * 0.9, $limit * 1.1, $name;
}

# new_delay
{
   my $future = POE::Future->new_delay( 1 );

   time_about( sub { $future->await }, 1, '->new_delay future is ready' );

   is_deeply( [ $future->get ], [], '$future->get returns empty list on new_delay' );
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

   is_deeply( [ $future->get ], [], '$future->get returns empty list on new_alarm' );
}

done_testing;
