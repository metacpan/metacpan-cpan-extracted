#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Refcount;

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

   method BUILD {
      push @array, 456;
      $hash{789} = 10;
   }

   method test {
      Test::More::is( $scalar, 123, '$scalar slot' );
      Test::More::is_deeply( \@array, [ 456 ], '@array slot' );
      Test::More::is_deeply( \%hash, { 789 => 10 }, '%hash slot' );
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

# Variant of RT132228 about individual slot lexicals
class Holder {
   has $slot;
   method slot :lvalue { $slot }
}

{
   my $datum = [];
   is_oneref( $datum, '$datum initially' );

   my $holder = Holder->new;
   $holder->slot = $datum;
   is_refcount( $datum, 2, '$datum while held by Holder' );

   undef $holder;
   is_oneref( $datum, '$datum finally' );
}

done_testing;
