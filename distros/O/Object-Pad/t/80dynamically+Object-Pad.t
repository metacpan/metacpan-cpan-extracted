#!/usr/bin/perl

use v5.18;
use warnings;

use Test2::V0;

use Test2::Require::Module 'Object::Pad' => '0.800';
use Test2::Require::Module 'Syntax::Keyword::Dynamically';

use Object::Pad;
use Syntax::Keyword::Dynamically;

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
