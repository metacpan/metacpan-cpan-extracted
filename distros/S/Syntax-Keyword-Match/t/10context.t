#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use Syntax::Keyword::Match;

# in scalar context
{
   my $ret = do {
      my $topic = "two";
      match($topic : eq) {
         case("one")   { 1 }
         case("two")   { 2 }
         case("three") { 3 }
      }
   };
   is( $ret, 2, 'match/case in scalar context' );
}

{
   sub yieldsnumber { 99 }

   my $ret = do {
      match(1 : ==) {
         case(1) { yieldsnumber }
         case(2) { 0 }
      }
   };
   is( $ret, 99, 'match/case yields value of entersub' );
}

# in list context
{
   my @ret = do {
      my $topic = "x,y";
      match($topic : eq) {
         case("a,b") { "a", "b" }
         case("x,y") { "x", "y" }
      }
   };
   is( \@ret, [ "x", "y" ], 'match/case in list context' );
}

# as final-expr
{
   sub func {
      match($_[0] : ==) {
         case(1) { "one" }
         case(2) { "two" }
         case(3) { "three" }
      }
   }

   is( scalar func(2), "two", 'match/case as final-expr' );
}

done_testing;
