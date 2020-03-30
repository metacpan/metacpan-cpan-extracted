#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Object::Pad;

class Counter {
   has $count = 0;
   method count :lvalue { $count }

   method inc { $count++ };
}

# Counter::count has both :lvalue :method attrs
{
   is_deeply( [ sort +attributes::get( \&Counter::count ) ],
      [ 'lvalue', 'method' ],
      'attributes of &Counter::count' );
}

{
   my $counter = Counter->new;
   is( $counter->count, 0, 'count is initially 0');

   $counter->count = 4;
   $counter->inc;

   is( $counter->count, 5, 'count is 5' );
}

done_testing;
