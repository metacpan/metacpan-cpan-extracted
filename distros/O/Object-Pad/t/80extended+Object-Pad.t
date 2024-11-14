#!/usr/bin/perl

use v5.18;
use warnings;

use Test2::V0;
BEGIN { $] >= 5.026000 or plan skip_all => "No parse_subsignature()"; }

use Test2::Require::Module 'Object::Pad' => '0.800';
use Test2::Require::Module 'Sublike::Extended' => '0.29';

use Object::Pad;
use Sublike::Extended;

# extended method
{
   class C1 {
      extended method f (:$x, :$y) { return "x=$x y=$y" }
   }

   is( C1->new->f( x => "first", y => "second" ), "x=first y=second",
      'extended method' );
}

# method + S:E 0.29
{
   use Sublike::Extended 'method';

   class C2 {
      method f (:$x, :$y) { return "x=$x y=$y" }
   }

   is( C2->new->f( x => "third", y => "fourth" ), "x=third y=fourth",
      'method with extended keyword' );
}

done_testing;
