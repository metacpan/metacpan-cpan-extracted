#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

use Object::Pad;

use attributes ();

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

class TwiceCounter isa Counter {
   method inc :override { $self->SUPER::inc; $self->SUPER::inc; }
}

done_testing;
