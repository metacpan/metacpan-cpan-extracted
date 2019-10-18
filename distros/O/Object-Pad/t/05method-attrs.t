#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Object::Pad;

class Counter {
   has $count;
   method count :lvalue { $count }

   method inc { $count++ };
}

{
   my $counter = Counter->new;
   $counter->count = 4;
   $counter->inc;

   is( $counter->count, 5, 'count is 5' );
}

done_testing;
