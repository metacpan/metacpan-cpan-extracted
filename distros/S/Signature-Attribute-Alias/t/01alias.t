#!/usr/bin/perl

use v5.26;
use warnings;

use Test2::V0 0.000149;

use Sublike::Extended;
use Signature::Attribute::Alias;

use experimental 'signatures';

{
   my $was_n;
   extended sub incr ( $n :Alias ) { $was_n = $n; $n++; }

   my $x = 10;
   incr $x;
   is( $was_n, 10,
      'incr() saw original value' );
   is( $x, 11,
      'incr() can modify caller arguments' );
}

# refcount
{
   extended sub nothing ( $x :Alias ) { $x = $x; }

   my $arr = [];
   is_oneref( $arr, '$arr has refcount one initially' );

   nothing( $arr );

   is_oneref( $arr, '$arr has refcount one at EOF' );
}

done_testing;
