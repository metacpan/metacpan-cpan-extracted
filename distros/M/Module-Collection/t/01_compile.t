#!/usr/bin/perl -w

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 3;
use Test::Script;

ok( $] >= 5.005, 'Perl version is new enough' );
use_ok( 'Module::Collection' );
script_compiles_ok( 'bin/pmcv' );
