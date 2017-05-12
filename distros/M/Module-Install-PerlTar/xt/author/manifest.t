#!/usr/bin/perl

# Test that our MANIFEST describes the distribution

use strict;

BEGIN {
	$| = 1;
	$^W = 1;
}

my @MODULES = (
	'Test::DistManifest 1.001003',
);

# Load the testing modules
use Test::More;
foreach my $MODULE ( @MODULES ) {
	eval "use $MODULE";
	if ( $@ ) {
		BAIL_OUT( "Failed to load required release-testing module $MODULE" );
	}
}

manifest_ok();
