#!perl

# Test that our declared minimum Perl version matches our syntax

use strict;

BEGIN {
	BAIL_OUT ('Perl version unacceptably old.') if ($] < 5.008001);
	use English qw(-no_match_vars);
	$OUTPUT_AUTOFLUSH = 1;
	$WARNING = 1;
}

my @MODULES = (
	'Perl::MinimumVersion 1.26',
	'Test::MinimumVersion 0.101080',
);


# Load the testing modules
use Test::More;
foreach my $MODULE ( @MODULES ) {
	eval "use $MODULE";
	if ( $EVAL_ERROR ) {
		BAIL_OUT( "Failed to load required release-testing module $MODULE" )
	}
}

all_minimum_version_from_metayml_ok();

