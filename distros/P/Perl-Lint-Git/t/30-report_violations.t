#!perl

# Note: cannot use -T here, Git::Repository uses environment variables directly.

use strict;
use warnings;

use Perl::Lint::Git;
use Test::Deep;
use Test::Exception;
use Test::FailWarnings -allow_deps => 1;
use Test::Requires::Git;
use Test::More;


# Check there is a git binary available, or skip all.
test_requires_git();
plan( tests => 8 );

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
	'Retrieve Perl::Lint::Git object.',
);

# Retrieve violations for author1.
my $author1_violations = $git_linter->report_violations(
	author => 'author1@example.com',
);
isa_ok(
	$author1_violations,
	'ARRAY',
	'Violations for author1@example.com',
);

# Check that the code triggers TestingAndDebugging::RequireUseWarnings.
my @user_warnings_violations = grep
	{ $_->{'policy'} eq 'Perl::Lint::Policy::TestingAndDebugging::RequireUseWarnings' }
	@$author1_violations;

is(
	scalar( @user_warnings_violations ),
	1,
	'Find one violation of TestingAndDebugging::RequireUseWarnings for author1@example.com',
);

# Retrieve violations for author2.
my $author2_violations = $git_linter->report_violations(
	author => 'author2@example.com',
);
isa_ok(
	$author2_violations,
	'ARRAY',
	'Violations for author2@example.com',
);
is(
	scalar( @$author2_violations ),
	1,
	'Find the expected number of violations for author2@example.com',
);
is(
	$author2_violations->[0]->{'policy'},
	'Perl::Lint::Policy::Subroutines::RequireFinalReturn',
	'The violation is Subroutines::RequireFinalReturn.',
);
