#!/usr/bin/perl

use v5.18;
use warnings;

use Test2::V0;

use Object::Pad 0.800;

class Counter {
   field $count;

   method inc { $count++ };
   method make_incrsub {
      return sub { $count++ };
   }

   method count { $count }
}

{
   my $counter = Counter->new;
   my $inc = $counter->make_incrsub;

   $inc->();
   $inc->();

   is( $counter->count, 2, '->count after invoking incrsub' );
}

# RT132249
{
   class Widget {
      field $_menu;
      method popup_menu {
         my $on_activate = sub { undef $_menu };
      }
      method on_mouse {
      }
   }

   # If we got to here without crashing then the test passed
   pass( 'RT132249 did not cause a crash' );
}

done_testing;
