#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 3;
use Test::NoWarnings;
use Test::Script;

use_ok( 'SDL::Tutorial::3DWorld' );

script_compiles( 'script/3dworld' );
