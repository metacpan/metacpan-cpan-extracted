#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;
use Test::Refcount;

use Object::Pad;

my $arr = [];

class WithWeak {
   has $one = 1;
   has $slot :writer :param :weak;
   has $two = 2;
}

is_oneref( $arr, '$arr has one reference before we start' );

{
   my $obj = WithWeak->new( slot => $arr );
   is_oneref( $arr, '$arr has one reference after WithWeak construction' );
}

{
   my $obj = WithWeak->new( slot => [] );
   $obj->set_slot( $arr );

   is_oneref( $arr, '$arr has one reference after WithWeak mutator' );
}

# RT139665
{
   class subWithWeak :isa(WithWeak) {
      has $three = 3;
   }

   my $obj = subWithWeak->new( slot => $arr );
   is_oneref( $arr, '$arr has one reference after subWithWeak construction' );
}

{
   class WithInnerHelper {
      has $slot :writer :param :weak;

      class InnerHelperClass :isa(WithInnerHelper) {}
   }

   my $obj = InnerHelperClass->new( slot => $arr );
   is_oneref( $arr, '$arr has one reference after InnerHelperClass construction' );
}

is_oneref( $arr, '$arr has one reference before EOF' );

done_testing;
