#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Object::Pad;

class Counter {
   has $count;

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

done_testing;
