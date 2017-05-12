#!/usr/bin/perl

# Overwrite the original test and do nothing

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More skip_all => 'Test removed in new ExtUtils::Install release';
