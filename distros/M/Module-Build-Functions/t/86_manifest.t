#!/usr/bin/perl

# Test that our MANIFEST describes the distribution

use strict;

BEGIN {
	use English qw(-no_match_vars);
	$OUTPUT_AUTOFLUSH = 1;
	$WARNING = 1;
}

my @MODULES = (
	'Test::DistManifest 1.001003',
);

# Don't run tests for installs
use Test::More;
unless ( $ENV{RELEASE_TESTING} ) {
	plan( skip_all => "Author tests not required for installation" );
}
unless ( -e 'MANIFEST.SKIP' ) {
	plan( skip_all => "MANIFEST.SKIP does not exist, so cannot test this." );
}

# Load the testing modules
foreach my $MODULE ( @MODULES ) {
	eval "use $MODULE";
	if ( $EVAL_ERROR ) {
		$ENV{RELEASE_TESTING}
		? BAIL_OUT( "Failed to load required release-testing module $MODULE" )
		: plan( skip_all => "$MODULE not available for testing" );
	}
}

manifest_ok();
