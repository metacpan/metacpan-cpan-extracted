#!/usr/bin/perl

use v5.18;
use warnings;

use Test2::V0 0.000148; # is_refcount

use Object::Pad 0.800;

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
   class subWithWeak {
      inherit WithWeak;

      field $three = 3;
   }

   my $obj = subWithWeak->new( field => $arr );
   is_oneref( $arr, '$arr has one reference after subWithWeak construction' );
}

{
   class WithInnerHelper {
      field $field :writer :param :weak;

      class InnerHelperClass { inherit WithInnerHelper; }
   }

   my $obj = InnerHelperClass->new( field => $arr );
   is_oneref( $arr, '$arr has one reference after InnerHelperClass construction' );
}

is_oneref( $arr, '$arr has one reference before EOF' );

done_testing;
