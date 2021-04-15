#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

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

done_testing;
