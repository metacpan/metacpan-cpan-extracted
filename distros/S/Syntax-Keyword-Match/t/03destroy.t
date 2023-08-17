#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0 0.000147;

use Syntax::Keyword::Match;

{
   my $arr = [];
   is_oneref( $arr, '$arr has one reference before test' );

   my $ok;
   match( $arr : == ) {
      case( $arr ) { $ok = 1 }
   }
   ok( $ok, '$arr is numerically equal to itself' );

   is_oneref( $arr, '$arr has one reference after test' );
}

done_testing;
