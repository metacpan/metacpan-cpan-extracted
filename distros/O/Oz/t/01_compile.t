#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 3;

use_ok( 'Oz'           );
use_ok( 'Oz::Script'   );
use_ok( 'Oz::Compiler' );
