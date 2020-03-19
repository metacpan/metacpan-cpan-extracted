#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Object::Pad;

class Counter {
   has $count;
   my $allcount = 0;

   method inc { $count++; $allcount++ }

   method count { $count }
   sub allcount { $allcount }
}

{
   my $countA = Counter->new;
   my $countB = Counter->new;

   $countA->inc;
   $countB->inc;

   is( $countA->count, 1, '$countA->count' );
   is( Counter->allcount, 2, 'Counter->allcount' );
}

done_testing;
