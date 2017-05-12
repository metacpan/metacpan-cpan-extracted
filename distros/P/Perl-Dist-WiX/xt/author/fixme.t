#!/usr/bin/perl

# Test that all modules have a version number.

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
use File::Spec::Functions qw(catdir);
foreach my $MODULE ( @MODULES ) {
	eval "use $MODULE";
	if ( $EVAL_ERROR ) {
		BAIL_OUT( "Failed to load required release-testing module $MODULE" );
	}
}

TODO: {

	local $TODO = 'csjewell@cpan.org is still working through this.';

	run_tests(
		where    => catdir(qw(blib lib Perl)),  # where to find files to check
		match    => 'TODO',                     # what to check for
	);
}