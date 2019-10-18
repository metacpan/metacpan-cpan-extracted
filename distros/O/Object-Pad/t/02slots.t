#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Object::Pad;

class Counter {
   has $count;

   method inc { $count++ };

   method describe { "Count is now $count" }
}

{
   my $counter = Counter->new;
   $counter->inc;
   $counter->inc;
   $counter->inc;

   is( $counter->describe, "Count is now 3",
      '$counter->describe after $counter->inc x 3' );
}

class AllTheTypes {
   has $scalar;
   has @array;
   has %hash;

   method CREATE {
      $scalar = 123;
      push @array, 456;
      $hash{789} = 10;
   }

   method test {
      ::is( $scalar, 123, '$scalar slot' );
      ::is_deeply( \@array, [ 456 ], '@array slot' );
      ::is_deeply( \%hash, { 789 => 10 }, '%hash slot' );
   }
}

AllTheTypes->new->test;

done_testing;
