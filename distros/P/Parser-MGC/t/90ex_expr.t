#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

use lib ".";
require "examples/eval-expr.pl";

my $parser = ExprParser->new;

while( <DATA> ) {
   chomp;
   my ( $str, $expect ) = split m/=/;

   is( $parser->from_string( $str ), $expect, $str );
}

done_testing;

__DATA__
1+2=3
 1 + 2 =3
1+2+3=6
10-4=6
10-2-2=6
3*4=12
3*4*5=60
20/4=5
20/5/2=2
3+4*5=23
4*5+3=23
(3+4)*5=35
4*(5+3)=32
