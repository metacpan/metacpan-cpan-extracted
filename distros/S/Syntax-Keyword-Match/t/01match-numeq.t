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

done_testing;
