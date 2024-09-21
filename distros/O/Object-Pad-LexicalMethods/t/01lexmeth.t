#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use Object::Pad::LexicalMethods;
BEGIN { plan skip_all => "No PL_infix_plugin" unless XS::Parse::Infix::HAVE_PL_INFIX_PLUGIN; }

use Object::Pad 0.814;

class TestClass1 {
   my method privatemethod {
      my @args = @_;

      return join( " | ", "the-private-method on $self", @args );
   }

   method m0 {
      return $self->&privatemethod;  # parens are optional for zero args
   }

   method m1 {
      return $self->&privatemethod( "more" );
   }
}

{
   my $obj = TestClass1->new;

   # We don't care how $obj stringifies but it should be stable
   is( $obj->m0, "the-private-method on $obj",
      'result of invoking lexical method within m0' );
   is( $obj->m1, "the-private-method on $obj | more",
      'result of invoking lexical method within m1' );
}

done_testing;
