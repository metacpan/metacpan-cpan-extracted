#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

use Object::Pad;

class Counter;
has $count = 0;
method count :lvalue { $count }
method inc { $count++ }

package main;

{
   my $counter = Counter->new;
   $counter->inc;
   is( $counter->count, 1, 'Count is now 1' );
}

done_testing;
