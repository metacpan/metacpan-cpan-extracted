#!/usr/bin/perl -w

# Compilation testing for Package::Util

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 2;

ok( $] >= 5, "Your perl is new enough" );

use_ok('Package::Util');

exit(0);
