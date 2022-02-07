#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;
use Test::Refcount;

use Object::Pad;
use Object::Pad::FieldAttr::Isa;

my $arr = [];

class WithWeak {
   has $slot :writer :param :weak :Isa(ARRAY);
}

is_oneref( $arr, '$arr has one reference before we start' );

{
   my $obj = WithWeak->new( slot => $arr );
   is_oneref( $arr, '$arr has one reference after withWeak construction' );

   ok( !defined eval { $obj->set_slot( "nonref" ) },
      '->set_slot nonref fails' );

   is_oneref( $arr, '$arr has one reference after failed mutator' );
}

is_oneref( $arr, '$arr has one reference before EOF' );

done_testing;
