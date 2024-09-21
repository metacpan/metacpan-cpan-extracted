#!/usr/bin/perl

use v5.18;
use warnings;

use Test2::V0;

use Object::Pad 0.800;

class Counter;
field $count = 0;
method count :lvalue { $count }
method inc { $count++ }

package main;

{
   my $counter = Counter->new;
   $counter->inc;
   is( $counter->count, 1, 'Count is now 1' );
}

done_testing;
