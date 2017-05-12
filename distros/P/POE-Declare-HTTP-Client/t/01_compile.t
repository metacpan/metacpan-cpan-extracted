#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 2;
use Test::NoWarnings;

use_ok( 'POE::Declare::HTTP::Client' );
