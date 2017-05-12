#!perl

# Test that our MANIFEST describes the distribution

use strict;

BEGIN {
	BAIL_OUT ('Perl version unacceptably old.') if ($] < 5.008001);
	use English qw(-no_match_vars);
	$OUTPUT_AUTOFLUSH = 1;
	$WARNING = 1;
}

my @MODULES = (
	'Test::DistManifest 1.009',
);

# Load the testing modules
use Test::More;
unless ( -e 'MANIFEST.SKIP' ) {
	plan( skip_all => "MANIFEST.SKIP does not exist, so cannot test this." );
}
foreach my $MODULE ( @MODULES ) {
	eval "use $MODULE";
	if ( $EVAL_ERROR ) {
		BAIL_OUT( "Failed to load required release-testing module $MODULE" );
	}
}

manifest_ok();

