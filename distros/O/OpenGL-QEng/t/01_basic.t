#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 4;

ok( $] > 5.005, 'Perl version is 5.004 or newer' );

use_ok( 'OpenGL::QEng::Thing' );

my $o = OpenGL::QEng::Thing->new();

ok( defined $o, 'made a Thing' );

ok( $o->isa('OpenGL::QEng::Thing'), 'of the correct class' );
