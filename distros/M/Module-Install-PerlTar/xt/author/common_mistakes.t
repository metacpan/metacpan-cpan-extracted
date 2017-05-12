#!/usr/bin/perl

# Test that all modules have no common misspellings.

use strict;

BEGIN {
	$| = 1;
	$^W = 1;
}

my @MODULES = (
	'Pod::Spell::CommonMistakes 0.01',
	'Test::Pod::Spelling::CommonMistakes 0.01',
);

# Load the testing modules
use Test::More;
foreach my $MODULE ( @MODULES ) {
	eval "use $MODULE";
	if ( $@ ) {
		BAIL_OUT( "Failed to load required release-testing module $MODULE" );
	}
}

all_pod_files_ok();
