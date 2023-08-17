#!/usr/bin/perl

use 5.006;
use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 3;

require_ok( 'ORLite' );
use lib 't/lib';
use_ok( 'LocalTest' );

is(
	$ORLite::VERSION,
	$LocalTest::VERSION,
	'$VERSION match'
);
