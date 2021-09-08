#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

BEGIN {
   plan skip_all => "Syntax::Keyword::Match >= 0.08 is not available"
   unless eval { require Syntax::Keyword::Match;
                 Syntax::Keyword::Match->VERSION( '0.08' ); };
   plan skip_all => "Syntax::Operator::Equ is not available"
   unless eval { require Syntax::Operator::Equ };

   Syntax::Keyword::Match->import;
   Syntax::Operator::Equ->import;
}

# literals
{
   my $ok;
   match("abc" : equ) {
      case("abc") { $ok++ }
      case("def") { fail('Not this one sorry'); }
   }
   ok( $ok, 'Literal match' );
}

# undef is not ""
{
   my $ok;
   match("" : equ) {
      case(undef) { fail('Not this one sorry'); }
      case("")    { $ok++ }
   }
   ok( $ok, '"" did not match undef' );

   undef $ok;
   match(undef : equ) {
      case("")    { fail('Not this one sorry'); }
      case(undef) { $ok++ }
   }
   ok( $ok, 'undef did not match ""' );
}

done_testing;
