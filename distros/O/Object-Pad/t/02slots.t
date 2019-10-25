#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Object::Pad;

class Counter {
   has $count = 0;

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
   has $scalar = 123;
   has @array;
   has %hash;

   method BUILDALL {
      push @array, 456;
      $hash{789} = 10;
   }

   method test {
      ::is( $scalar, 123, '$scalar slot' );
      ::is_deeply( \@array, [ 456 ], '@array slot' );
      ::is_deeply( \%hash, { 789 => 10 }, '%hash slot' );
   }
}

{
   use Data::Dump 'pp';

   my $instance = AllTheTypes->new;

   $instance->test;

   # The exact output of this test is fragile as it depends on the internal
   # representation of the instance, which we do not document and is not part
   # of the API guarantee. We're not really checking that it has exactly this
   # output, just that Data::Dump itself doesn't crash. If a later version
   # changes the representation so that the output here differs, just change
   # the test as long as it is something sensible.
   is( pp($instance),
      q(bless([123, [456], { 789 => 10 }], "AllTheTypes")),
      'pp($instance) sees slot data' );
}

done_testing;
