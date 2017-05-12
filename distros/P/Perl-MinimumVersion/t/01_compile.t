#!/usr/bin/perl

# Load test the Perl::MinimumVersion module

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More      0.47    'tests' => 3;
use Test::Script    1.03;

ok( $] >= 5.005, 'Your perl is new enough' );

use_ok('Perl::MinimumVersion' );

script_compiles_ok( 'script/perlver', 'perlver compiles ok' );

