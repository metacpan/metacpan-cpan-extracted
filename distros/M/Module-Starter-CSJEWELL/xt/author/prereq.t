#!perl

# Test that all our prerequisites are defined in the Build.PL.

use strict;

BEGIN {
	BAIL_OUT ('Perl version unacceptably old.') if ($] < 5.008001);
	use English qw(-no_match_vars);
	$OUTPUT_AUTOFLUSH = 1;
	$WARNING = 1;
}

my @MODULES = (
	'Test::Prereq::Build 1.036',
);

# Load the testing modules
use Test::More;
foreach my $MODULE ( @MODULES ) {
	eval "use $MODULE";
	if ( $EVAL_ERROR ) {
		$ENV{RELEASE_TESTING}
		? BAIL_OUT( "Failed to load required release-testing module $MODULE" )
		: plan( skip_all => "$MODULE not available for testing" );
	}
}

local $ENV{PERL_MM_USE_DEFAULT} = 1;

diag('Takes a few minutes...');

my @modules_skip = (
# Modules needed for prerequisites, not for this module
    # List here if needed.
# Needed only for AUTHOR_TEST tests
	'Parse::CPAN::Meta',
	'Perl::Critic',
	'Perl::Critic::More',
	'Perl::Critic::Utils::Constants',
	'Perl::MinimumVersion',
	'Perl::Tidy',
	'Pod::Coverage::Moose',
	'Pod::Coverage',
	'Pod::Simple',
	'Test::CPAN::Meta',
	'Test::DistManifest',
	'Test::MinimumVersion',
	'Test::Perl::Critic',
	'Test::Pod',
	'Test::Pod::Coverage',
	'Test::Portability::Files',
	'Test::Prereq::Build',
);

prereq_ok(5.008001, 'Check prerequisites', \@modules_skip);

