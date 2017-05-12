#!/usr/bin/perl

# Test that our files are portable across systems.

use strict;

BEGIN {
	$| = 1;
	$^W = 1;
}

my @MODULES = (
	'Test::Portability::Files 0.05',
);

# Load the testing modules
use Test::More;

foreach my $MODULE ( @MODULES ) {
	eval "use $MODULE";
	if ( $@ ) {
		BAIL_OUT( "Failed to load required release-testing module $MODULE" );
	}
}

run_tests();
