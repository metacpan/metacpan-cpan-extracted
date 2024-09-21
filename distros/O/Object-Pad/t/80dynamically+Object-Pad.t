#!/usr/bin/perl

use v5.18;
use warnings;

use Test2::V0;

BEGIN {
   plan skip_all => "Syntax::Keyword::Dynamically is not available"
      unless eval { require Syntax::Keyword::Dynamically };
   plan skip_all => "Object::Pad >= 0.800 is not available"
      unless eval { require Object::Pad;
                    Object::Pad->VERSION( '0.800' ) };

   Syntax::Keyword::Dynamically->import;
   Object::Pad->import;

   diag( "Syntax::Keyword::Dynamically $Syntax::Keyword::Dynamically::VERSION, " .
         "Object::Pad $Object::Pad::VERSION" );
}

class Datum {
   field $value = 1;
   method value { $value }

   method test {
      ::is( $self->value, 1, 'value is 1 initially' );

      {
         dynamically $value = 2;
         ::is( $self->value, 2, 'value is 2 inside dynamically-assigned block' );
      }

      ::is( $self->value, 1, 'value is 1 finally' );
   }
}

Datum->new->test;

done_testing;
