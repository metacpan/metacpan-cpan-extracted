#!/usr/bin/perl -w

# Load testing for Params::Coerce

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 2;

ok( $] >= 5.005, "Your perl is new enough" );
use_ok('Params::Coerce');
