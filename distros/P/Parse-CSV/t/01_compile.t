#!/usr/bin/perl 

# Compile testing for Parse::CSV

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 1;

use_ok('Parse::CSV');
