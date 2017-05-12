#!perl

# Note: cannot use -T here, Git::Repository uses environment variables directly.

use strict;
use warnings;

use Data::Dumper;
use Perl::Critic::Git;
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

# Prepare Perl::Critic::Git.
my $git_critic;
lives_ok(
	sub
	{
		$git_critic = Perl::Critic::Git->new(
			file   => $work_tree . '/test.pl',
			level  => 'harsh',
		);
	},
	'Create a Perl::Critic::Git object.',
);

# Tests retrieving perlcritic violations.
my $violations;
lives_ok(
	sub
	{
		$violations = $git_critic->get_perlcritic_violations();
	},
	'Retrieve PerlCritic violations.',
);
isa_ok(
	$violations,
	'ARRAY',
	'$violations',
);
is(
	scalar( @$violations ),
	2,
	'Find two violations.',
);
is(
	$violations->[0]->policy(),
	'Perl::Critic::Policy::TestingAndDebugging::RequireUseWarnings',
	'The first violation is TestingAndDebugging::RequireUseWarnings.',
);
is(
	$violations->[1]->policy(),
	'Perl::Critic::Policy::Subroutines::RequireFinalReturn',
	'The second violation is Subroutines::RequireFinalReturn.',
);
