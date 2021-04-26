#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

use Syntax::Keyword::Match;

# literals
{
   my $ok;
   match(123 : ==) {
      case(123) { $ok++ }
      case(456) { fail('Not this one sorry'); }
   }
   ok( $ok, 'Literal match' );
}

# case expressions
{
   my $ok;
   my $twenty = 20;
   match(20 : ==) {
      case(10)      { fail("Not 10") }
      case($twenty) { $ok++ }
      case(30)      { fail("Not 30") }
   }
   ok( $ok, 'Expression match' );
}

# default
{
   my $ok;
   match(789 : ==) {
      case(10) { fail("Not 10") }
      case(20) { fail("Not 20") }
      default   { $ok++ }
   }
   ok( $ok, 'Default block executed' );
}

# expressions evaluated just once
{
   my $evalcount;
   sub topicexpr { $evalcount++; return 300 }

   my $ok;
   match(topicexpr() : ==) {
      case(100) { fail('Nope'); }
      case(200) { fail('Still nope'); }
      case(300) { $ok++ }
   }
   ok( $ok, 'Function call match' );

   is( $evalcount, 1, 'Topic expression evaluated just once' );
}

# Constant but non-literal expressions are accepted
{
   my $ok;
   match(45 : ==) {
      case(40 + 5) { $ok++ }
   }
   ok( $ok, 'Constant non-literal parses' );
}

# overloaded '==' operator
{
   my $equal;
   package Greedy {
      use overload '==' => sub { $equal };
   }

   sub greedy_is_ten
   {
      match(bless [], "Greedy" : ==) {
         case(10) { return "YES" }
         default  { return "NO" }
      }
   }

   $equal = 1;
   is( greedy_is_ten, "YES", 'Greedy is 10 when set' );

   $equal = 0;
   is( greedy_is_ten, "NO", 'Greedy is not 10 when unset' );
}

done_testing;
