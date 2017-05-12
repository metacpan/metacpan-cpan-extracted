#!/usr/bin/perl

# Test that all our prerequisites are defined in the Makefile.PL.

use strict;

BEGIN {
	$| = 1;
	$^W = 1;
}

my @MODULES = (
	'Test::Prereq 1.036',
);

# Load the testing modules
use Test::More;
plan( skip_all => "Module::Install and Test::Prereq do not go together." );

foreach my $MODULE ( @MODULES ) {
	eval "use $MODULE";
	if ( $@ ) {
		BAIL_OUT( "Failed to load required release-testing module $MODULE" )
	}
}

diag('Takes a few minutes...');

my @modules_skip = (
# Needed only for AUTHOR_TEST tests
		'Perl::Critic::More',
		'Test::HasVersion',
		'Test::MinimumVersion',
		'Test::Perl::Critic',
		'Test::Prereq',
);

prereq_ok(5.006001, 'Check prerequisites', \@modules_skip);
