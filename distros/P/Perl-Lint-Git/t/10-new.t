#!perl

# Note: cannot use -T here, Git::Repository uses environment variables directly.

use strict;
use warnings;

use Perl::Lint::Git;
use Test::Exception;
use Test::FailWarnings -allow_deps => 1;
use Test::Requires::Git;
use Test::More;


# Check there is a git binary available, or skip all.
test_requires_git();
plan( tests => 6 );

# Retrieve the path to the test git repository.
ok(
	open( my $persistent, '<', 't/test_information' ),
	'Retrieve the persistent test information.',
) || diag( "Error: $!" );
ok(
	defined( my $work_tree = <$persistent> ),
	'Retrieve the path to the test git repository.',
);

# Make sure that the right parameters return a valid object.
my $git_linter;
lives_ok(
	sub
	{
		$git_linter = Perl::Lint::Git->new(
			file   => $work_tree . '/test.pl',
		);
	},
	'Create an object with "file" set properly.',
);
isa_ok(
	$git_linter,
	'Perl::Lint::Git',
	'$git_linter',
);

# Test error conditions.
dies_ok(
	sub
	{
		$git_linter = Perl::Lint::Git->new();
	},
	'"file" must be defined.',
);
dies_ok(
	sub
	{
		$git_linter = Perl::Lint::Git->new(
			file => 'not_found',
		);
	},
	'"file" must be a valid file path.'
);
