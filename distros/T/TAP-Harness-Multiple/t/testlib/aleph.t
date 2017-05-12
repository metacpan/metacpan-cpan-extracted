# -*- perl -*-
use strict;
use warnings;
use Test::Simple tests => 2;

my @x;
@x = (1,1);
ok( $x[0] == $x[1], "elements are identical" );

@x = (1,2);
ok( $x[0] != $x[1], "elements differ" );

