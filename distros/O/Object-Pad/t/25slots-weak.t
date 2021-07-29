#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;
use Test::Refcount;

use Object::Pad;

my $arr = [];

class WithWeak {
   has $slot :writer :param :weak;
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

is_oneref( $arr, '$arr has one reference before EOF' );

done_testing;
