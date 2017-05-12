#!/usr/bin/perl -w

# Compile testing for Parse::CSV::Colnames

use strict;
use File::Spec::Functions ':ALL';
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 3;

# Check their perl version
ok( $] >= 5.005, "Your perl is new enough" );

# Does the parent module load
use_ok('Parse::CSV 1.00');

# Does the module load
use_ok('Parse::CSV::Colnames');
