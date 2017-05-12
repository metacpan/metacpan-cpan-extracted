#!/usr/bin/perl

# Test that our declared minimum Perl version matches our syntax

use strict;

BEGIN {
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

# Terminate leftovers with prejudice aforethought.
require File::Remove;
foreach my $dir ( 't\tmp500', 't\tmp904', 't\tmp901', 't\tmp902', 't\tmp903' ) {
	File::Remove::remove( \1, $dir ) if -d $dir;
}

use File::Spec::Functions qw(catdir);
# I only want to test my own modules, not the module patches to the differing perls...
# Nor do I want 5k+ tests after a RELEASE_TESTING build!
if (-d catdir('blib', 'lib')) {
    all_minimum_version_from_metayml_ok({ paths => [ catdir('blib', 'lib', 'Perl'), 't' ]});
} else {
    all_minimum_version_from_metayml_ok({ paths => [ catdir('lib', 'Perl'), 't' ]});
}
