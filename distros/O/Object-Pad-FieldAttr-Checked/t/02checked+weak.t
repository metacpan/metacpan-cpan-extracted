#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0 0.000147;  # is_oneref

use Object::Pad;
use Object::Pad::FieldAttr::Checked;

use Scalar::Util qw( blessed );

my $arr = [];

# Cheating
sub ARRAY::check { return !blessed($_[1]) && ref($_[1]) eq "ARRAY" }

class WithWeak {
   field $slot :writer :param :weak :Checked(ARRAY);
}

is_oneref( $arr, '$arr has one reference before we start' );

{
   my $obj = WithWeak->new( slot => $arr );
   is_oneref( $arr, '$arr has one reference after withWeak construction' );

   like( dies { $obj->set_slot( {} ) },
      qr/^Field \$slot requires a value satisfying :Checked\(ARRAY\) at /,
      '->set_slot nonref fails' );

   is_oneref( $arr, '$arr has one reference after failed mutator' );
}

is_oneref( $arr, '$arr has one reference before EOF' );

done_testing;
