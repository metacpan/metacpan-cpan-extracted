#!/usr/bin/perl

# Test that our declared minimum Perl version matches our syntax

use strict;

BEGIN {
	$| = 1;
	$^W = 1;
}

my @MODULES = (
	'Perl::MinimumVersion 1.25',
	'Test::MinimumVersion 0.101080',
);

# Load the testing modules
use Test::More;
foreach my $MODULE ( @MODULES ) {
	eval "use $MODULE";
	if ( $@ ) {
		BAIL_OUT( "Failed to load required release-testing module $MODULE" )
	}
}

all_minimum_version_from_metayml_ok();
