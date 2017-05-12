#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 2;
use Test::Script;

require_ok( 'ORLite::Pod' );
script_compiles_ok( 'script/orlite2pod' );
