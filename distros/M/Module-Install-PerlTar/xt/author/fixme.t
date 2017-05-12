#!/usr/bin/perl

# Test that all modules have a version number.

use strict;

BEGIN {
	$| = 1;
	$^W = 1;
}

my @MODULES = (
	'Test::Fixme 0.04',
);

# Load the testing modules
use Test::More;
use File::Spec::Functions qw(catdir);
foreach my $MODULE ( @MODULES ) {
	eval "use $MODULE";
	if ( $@ ) {
		BAIL_OUT( "Failed to load required release-testing module $MODULE" );
	}
}

run_tests(
	match    => 'TO'. 'DO',                     # what to check for
);
