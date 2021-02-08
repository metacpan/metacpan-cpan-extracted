#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

use Syntax::Keyword::Dynamically;

my $var = 1;
{
   dynamically $var = 2;
   {
      dynamically $var = 3;

      is( $var, 3, '$var is 3 in inner scope' );
   }

   is( $var, 2, '$var is 2 in middle scope' );
}

is( $var, 1, '$var is 1 at toplevel' );

done_testing;
