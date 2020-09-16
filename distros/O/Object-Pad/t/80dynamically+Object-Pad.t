#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

BEGIN {
   plan skip_all => "Syntax::Keyword::Dynamically is not available"
      unless eval { require Syntax::Keyword::Dynamically };
   plan skip_all => "Object::Pad is not available"
      unless eval { require Object::Pad };

   Syntax::Keyword::Dynamically->import;
   Object::Pad->import;
}

class Datum {
   has $value = 1;
   method value { $value }

   method test {
      Test::More::is( $self->value, 1, 'value is 1 initially' );

      {
         dynamically $value = 2;
         Test::More::is( $self->value, 2, 'value is 2 inside dynamically-assigned block' );
      }

      Test::More::is( $self->value, 1, 'value is 1 finally' );
   }
}

Datum->new->test;

done_testing;
