#!perl

#!/usr/bin/perl

# Test that the POD documentation is comprehensive

use strict;

BEGIN {
	use English qw(-no_match_vars);
	$OUTPUT_AUTOFLUSH = 1;
	$WARNING = 1;
}

my @MODULES = (
	'Pod::Coverage 0.19',
	'Test::Pod::Coverage 1.08',
);

# Don't run tests for installs
use Test::More;
unless ( $ENV{RELEASE_TESTING} ) {
	plan( skip_all => "Author tests not required for installation" );
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



all_pod_coverage_ok({ 
	trustme => [ qr/^(?:check_nmake|get_file)$/ ], 
});