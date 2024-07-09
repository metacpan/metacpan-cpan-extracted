#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

BEGIN {
   plan skip_all => "Syntax::Keyword::Match >= 0.08 is not available"
   unless eval { require Syntax::Keyword::Match;
                 Syntax::Keyword::Match->VERSION( '0.08' ); };
   plan skip_all => "Syntax::Operator::Is is not available"
   unless eval { require Syntax::Operator::Is };

   Syntax::Keyword::Match->import;
   Syntax::Operator::Is->import;

   diag( "Syntax::Keyword::Match $Syntax::Keyword::Match::VERSION, " .
         "Syntax::Operator::Is $Syntax::Operator::Is::VERSION" );
}

# if we have Syntax::Operator::Is available then we know we must have
# Data::Checks as well
use Data::Checks qw( Num Object );

{
   sub func
   {
      match( $_[0] : is ) {
         case( Num    ) { return "arg is a number" }
         case( Object ) { return "arg is an object" }
         default        { return "arg is neither" }
      }
   }

   Test2::V0::is( func( 123 ),                   "arg is a number",  'func() on number' );
   Test2::V0::is( func( bless [], "SomeClass" ), "arg is an object", 'func() on object' );
   Test2::V0::is( func( [] ),                    "arg is neither",   'func() on arrayref' );
}

done_testing;
