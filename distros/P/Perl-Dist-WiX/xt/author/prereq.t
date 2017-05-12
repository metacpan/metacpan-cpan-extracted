#!/usr/bin/perl

# Test that all our prerequisites are defined in the Makefile.PL.

use strict;

BEGIN {
	use English qw(-no_match_vars);
	$OUTPUT_AUTOFLUSH = 1;
	$WARNING = 1;
}

my @MODULES = (
	'Test::Prereq::Build 1.037',
);

# Load the testing modules
use Test::More;
foreach my $MODULE ( @MODULES ) {
	eval "use $MODULE";
	if ( $EVAL_ERROR ) {
		BAIL_OUT( "Failed to load required release-testing module $MODULE" )
	}
}

local $ENV{PERL_MM_USE_DEFAULT} = 1;

diag('Takes a few minutes...');

# Terminate leftovers with prejudice aforethought.
require File::Remove;
foreach my $dir ( 't\tmp500', 't\tmp900', 't\tmp901', 't\tmp902', 't\tmp903' ) {
	File::Remove::remove( \1, $dir ) if -d $dir;
}

my @modules_skip = (
# Needed only for AUTHOR_TEST tests
		'Perl::Critic::More',
		'Test::HasVersion',
		'Test::MinimumVersion',
		'Test::Perl::Critic',
		'Test::Prereq',
# Needed only for the optional script
		'CPAN::Mini::Devel',
		'File::Slurp',
		'feature',
# Find out where these are needed.
		'MooseX::AttributeHelpers',
		'MooseX::Singleton',
# Covered by MooseX::Types
		'MooseX::Types::Moose',
# Covered by WiX3.
		'WiX3::XML::GeneratesGUID::Object',
		'WiX3::XML::MergeRef',
# Where is this?
		't::lib::MachineTest',
# Optional module - should not be required.
		'IO::Uncompress::UnXz',
);

prereq_ok(5.010, 'Check prerequisites', \@modules_skip);
