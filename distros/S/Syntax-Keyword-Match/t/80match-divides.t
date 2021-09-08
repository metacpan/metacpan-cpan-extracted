#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

BEGIN {
   plan skip_all => "Syntax::Keyword::Match >= 0.08 is not available"
   unless eval { require Syntax::Keyword::Match;
                 Syntax::Keyword::Match->VERSION( '0.08' ); };
   plan skip_all => "Syntax::Operator::Divides is not available"
   unless eval { require Syntax::Operator::Divides };

   Syntax::Keyword::Match->import;
   Syntax::Operator::Divides->import;
}

# literals
{
   my $ok;
   match(15 : %%) {
      case(5) { $ok++ }
      case(6) { fail('Not this one sorry'); }
   }
   ok( $ok, 'Literal match' );
}

done_testing;
