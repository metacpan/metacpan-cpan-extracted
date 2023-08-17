#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use Syntax::Keyword::Match;

# literals
{
   my $ok;
   match("abc" : eq) {
      case("abc") { $ok++ }
      case("def") { fail('Not this one sorry'); }
   }
   ok( $ok, 'Literal match' );
}

# case expressions
{
   my $ok;
   my $second = "second";
   match("second" : eq) {
      case("first") { fail("Not first") }
      case($second) { $ok++ }
      case("third") { fail("Not third") }
   }
   ok( $ok, 'Expression match' );
}

# default
{
   my $ok;
   match("xyz" : eq) {
      case("a") { fail("Not a") }
      case("b") { fail("Not b") }
      default   { $ok++ }
   }
   ok( $ok, 'Default block executed' );
}

# expressions evaluated just once
{
   my $evalcount;
   sub topicexpr { $evalcount++; return "string" }

   my $ok;
   match(topicexpr() : eq) {
      case("abc")    { fail('Nope'); }
      case("def")    { fail('Still nope'); }
      case("string") { $ok++ }
   }
   ok( $ok, 'Function call match' );

   is( $evalcount, 1, 'Topic expression evaluated just once' );
}

# Constant but non-literal expressions are accepted
{
   my $ok;
   match("XY" : eq) {
      case("X" . "Y") { $ok++ }
   }
   ok( $ok, 'Constant non-literal parses' );
}

# overloaded 'eq' operator
{
   my $equal;
   package Greedy {
      use overload 'eq' => sub { $equal };
   }

   sub greedy_is_ten
   {
      match(bless [], "Greedy" : eq) {
         case("ten") { return "YES" }
         default     { return "NO" }
      }
   }

   $equal = 1;
   is( greedy_is_ten, "YES", 'Greedy is 10 when set' );

   $equal = 0;
   is( greedy_is_ten, "NO", 'Greedy is not 10 when unset' );
}

done_testing;
