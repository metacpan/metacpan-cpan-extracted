#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

use Syntax::Keyword::Match;

# literals
{
   my $ok;
   match("abcd" : =~) {
      case(m/\w+/) { $ok++ }
      case(m/\d+/) { fail('Not this one sorry'); }
   }
   ok( $ok, 'Literal match' );
}

# default
{
   my $ok;
   match("XYZ" : =~) {
      case(m/a/) { fail("Not a") }
      case(m/b/) { fail("Not b") }
      default    { $ok++ }
   }
   ok( $ok, 'Default block executed' );
}

done_testing;
