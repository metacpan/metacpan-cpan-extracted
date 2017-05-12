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

ok(
	!$git_linter->_is_analyzed(),
	'The file is flagged as not analyzed.',
);

lives_ok(
	sub
	{
		$git_linter->get_authors();
	},
	'Get authors, which requires analyzing the file.',
);

ok(
	$git_linter->_is_analyzed(),
	'The file is flagged as analyzed.',
);
