# -*- perl -*-
use strict;
use warnings;
use Test::More tests => 4;

my @x;
@x = (1,1);
ok( $x[0] == $x[1], "elements are identical" );
is( $x[0], $x[1], "elements are identical: is" );

@x = (1,2);
ok( $x[0] != $x[1], "elements differ" );
isnt( $x[0], $x[1], "elements differ: isnt" );

