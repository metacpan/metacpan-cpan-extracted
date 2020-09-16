#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

use Object::Pad;

{
   class Counter {
      has $count;
      my $allcount = 0;

      method inc { $count++; $allcount++ }

      method count { $count }
      sub allcount { $allcount }
   }

   my $countA = Counter->new;
   my $countB = Counter->new;

   $countA->inc;
   $countB->inc;

   is( $countA->count, 1, '$countA->count' );
   is( Counter->allcount, 2, 'Counter->allcount' );
}

# anon methods can capture lexicals (RT132178)
{
   class Generated {
      foreach my $letter (qw( x y z )) {
         my $code = method {
            return uc $letter;
         };

         no strict 'refs';
         *$letter = $code;
      }
   }

   my $g = Generated->new;
   is( $g->x, "X", 'generated anon method' );
   is( $g->y, "Y", 'generated anon method' );
   is( $g->z, "Z", 'generated anon method' );
}

done_testing;
