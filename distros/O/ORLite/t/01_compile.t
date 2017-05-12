#!/usr/bin/perl

use 5.006;
use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 3;

require_ok( 'ORLite' );
require_ok( 't::lib::Test' );

is(
	$ORLite::VERSION,
	$t::lib::Test::VERSION,
	'$VERSION match'
);
