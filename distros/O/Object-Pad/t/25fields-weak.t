#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;
use Test::Refcount;

use Object::Pad ':experimental(init_expr)';

my $arr = [];

class WithWeak {
   field $one = 1;
   field $field :writer :param :weak;
   field $two = 2;
}

is_oneref( $arr, '$arr has one reference before we start' );

{
   my $obj = WithWeak->new( field => $arr );
   is_oneref( $arr, '$arr has one reference after WithWeak construction' );
}

{
   my $obj = WithWeak->new( field => [] );
   $obj->set_field( $arr );

   is_oneref( $arr, '$arr has one reference after WithWeak mutator' );
}

# RT139665
{
   class subWithWeak :isa(WithWeak) {
      field $three = 3;
   }

   my $obj = subWithWeak->new( field => $arr );
   is_oneref( $arr, '$arr has one reference after subWithWeak construction' );
}

{
   class WithInnerHelper {
      field $field :writer :param :weak;

      class InnerHelperClass :isa(WithInnerHelper) {}
   }

   my $obj = InnerHelperClass->new( field => $arr );
   is_oneref( $arr, '$arr has one reference after InnerHelperClass construction' );
}

is_oneref( $arr, '$arr has one reference before EOF' );

done_testing;
