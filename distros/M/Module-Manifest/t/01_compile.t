#!/usr/bin/perl

# Load testing for Module::Manifest

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 1;

use_ok('Module::Manifest');
