#!/usr/bin/perl

use strict;
use lib qw( example.1 );
use PerlBean::Style qw(:codegen);

use Circle;
my $circle = Circle->new( {
    radius => 1,
} );
my $op_get = &{$MOF}('get');
my $mb_radius = &{$AN2MBF}('radius');
print 'Circle with radius ', eval( "\$circle->$op_get$mb_radius()" ),
      ' has an area of ', $circle->area(), "\n";

use Square;
my $square = Square->new( {
    width => 1,
} );
my $mb_width = &{$AN2MBF}('width');
print 'Square with width ', eval( "\$square->$op_get$mb_width()" ),
      ' has an area of ', $square->area(), "\n";

use Rectangle;
my $rectangle = Rectangle->new( {
    width => 1,
    height => 2,
} );
my $mb_height = &{$AN2MBF}('height');
print 'Rectangle with width ', eval( "\$rectangle->$op_get$mb_width()" ),
      ' and with height ', eval( "\$rectangle->$op_get$mb_height()" ),
      ' has an area of ', $rectangle->area(), "\n";
