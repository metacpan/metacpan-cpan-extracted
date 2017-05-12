#!/usr/bin/perl

# Test that all modules have nothing marked to do.

use strict;

BEGIN {
	use English qw(-no_match_vars);
	$OUTPUT_AUTOFLUSH = 1;
	$WARNING = 1;
}

my @MODULES = (
	'Test::Fixme 0.04',
);

# Load the testing modules
use Test::More;
foreach my $MODULE ( @MODULES ) {
	eval "use $MODULE";
	if ( $EVAL_ERROR ) {
		BAIL_OUT( "Failed to load required release-testing module $MODULE" );
	}
}

# To make this a todo test, remove the comments below, and the spaces
# between TO and DO in the next two lines.
TODO: {
	local $TODO = 'All modules are going to be fixed.';

	run_tests(
		match    => 'TO' . 'DO',                # what to check for
	);
}

