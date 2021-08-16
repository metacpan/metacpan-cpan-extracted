#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

use Syntax::Keyword::Match;

# multiple case labels per block
{
   my $count;

   foreach my $i ( 1 .. 3 ) {
      match($i : ==) {
         case(1), case(2), case(3) { $count++ }
      }
   }

   is( $count, 3, '$count is 3 after cases' );
}

done_testing;
