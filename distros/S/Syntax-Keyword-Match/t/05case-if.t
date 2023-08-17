#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use Syntax::Keyword::Match;

{
   my @names;
   foreach ( 0 .. 5 ) {
      match( $_ : == ) {
         case(0)         { push @names, "none" }
         case(1)         { push @names, "one" }
         case if($_ < 4) { push @names, "few" }
         default         { push @names, "many" }
      }
   }

   is( \@names, [qw( none one few few many many )], 'case blocks were invoked' );
}

done_testing;
