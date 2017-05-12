#!/usr/bin/perl

BEGIN {
	$| = 1;
	$^W = 1;
}

use Test::More tests => 2;
use Test::NoWarnings;

use_ok( 'OpenGL::List' );
