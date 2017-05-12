#!perl

# Note: cannot use -T here, Git::Repository uses environment variables directly.

use strict;
use warnings;

use Perl::Critic::Git;
use Test::Deep;
use Test::Exception;
use Test::FailWarnings -allow_deps => 1;
use Test::Requires::Git;
use Test::More;


# Check there is a git binary available, or skip all.
test_requires_git();
plan( tests => 9 );

# Retrieve the path to the test git repository.
ok(
	open( my $persistent, '<', 't/test_information' ),
	'Retrieve the persistent test information.',
) || diag( "Error: $!" );
ok(
	defined( my $work_tree = <$persistent> ),
	'Retrieve the path to the test git repository.',
);

# Prepare Perl::Critic::Git.
my $git_critic;
lives_ok(
	sub
	{
		$git_critic = Perl::Critic::Git->new(
			file  => $work_tree . '/test.pl',
			level => 'harsh',
		);
	},
	'Retrieve Perl::Critic::Git object.',
);

# Retrieve violations for author1.
my $author1_violations = $git_critic->report_violations(
	author => 'author1@example.com',
);
isa_ok(
	$author1_violations,
	'ARRAY',
	'Violations for author1@example.com',
);
is(
	scalar( @$author1_violations ),
	1,
	'Find the expected number of violations for author1@example.com',
);
is(
	$author1_violations->[0]->policy(),
	'Perl::Critic::Policy::TestingAndDebugging::RequireUseWarnings',
	'The violation is TestingAndDebugging::RequireUseWarnings.',
);

# Retrieve violations for author2.
my $author2_violations = $git_critic->report_violations(
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
	$author2_violations->[0]->policy(),
	'Perl::Critic::Policy::Subroutines::RequireFinalReturn',
	'The violation is Subroutines::RequireFinalReturn.',
);
