#!perl

# Note: cannot use -T here, Git::Repository uses environment variables directly.

use strict;
use warnings;

use Data::Dumper;
use Perl::Lint::Git;
use Test::Deep;
use Test::Exception;
use Test::FailWarnings -allow_deps => 1;
use Test::Requires::Git;
use Test::More;


# Check there is a git binary available, or skip all.
test_requires_git();
plan( tests => 7 );

# Retrieve the path to the test git repository.
ok(
	open( my $persistent, '<', 't/test_information' ),
	'Retrieve the persistent test information.',
) || diag( "Error: $!" );
ok(
	defined( my $work_tree = <$persistent> ),
	'Retrieve the path to the test git repository.',
);

# Prepare Perl::Lint::Git.
my $git_linter;
lives_ok(
	sub
	{
		$git_linter = Perl::Lint::Git->new(
			file => $work_tree . '/test.pl',
		);
	},
	'Create a Perl::Lint::Git object.',
);

# Tests retrieving perllinter violations.
my $violations;
lives_ok(
	sub
	{
		$violations = $git_linter->get_perl_lint_violations();
	},
	'Retrieve PerlLint violations.',
);
isa_ok(
	$violations,
	'ARRAY',
	'$violations',
);
is(
	scalar( @$violations ),
	5,
	'Find 5 violations.',
);

is_deeply(
	[
		sort
		map { $_->{'policy'} }
		@$violations
	],
	[
		qw(
			Perl::Lint::Policy::Modules::RequireExplicitPackage
			Perl::Lint::Policy::Modules::RequireVersionVar
			Perl::Lint::Policy::Subroutines::RequireFinalReturn
			Perl::Lint::Policy::TestingAndDebugging::RequireUseWarnings
			Perl::Lint::Policy::ValuesAndExpressions::ProhibitInterpolationOfLiterals
		)
	],
	'The violations found match the expected list.',
) || diag( explain( $violations ) );
