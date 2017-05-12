#!perl

# Note: cannot use -T here, Git::Repository uses environment variables directly.

use strict;
use warnings;

use Git::Repository ( 'Log' );
use Test::Exception;
use Test::FailWarnings -allow_deps => 1;
use Test::Git;
use Test::Requires::Git;
use Test::More;


# Check there is a git binary available, or skip all.
test_requires_git();
plan( tests => 12 );

# Create a new, empty repository in a temporary location and return
# a Git::Repository object.
my $repository;
lives_ok(
	sub
	{
		$repository = test_repository(
			temp => [ CLEANUP => 0 ],
		);
	},
	'Initialize the test git repository.',
);

my $work_tree = $repository->work_tree();
ok(
	defined( $work_tree ) && -d $work_tree,
	'Find the work tree for the temporary test repository.',
);

# Retrieve the code to commit.
my $data = do { local $/; <DATA> };
my ( $commit1_code ) = $data =~ /<commit1>\s*(.*?)\s*<\/commit1>/sx;
my ( $commit2_code ) = $data =~ /<commit2>\s*(.*?)\s*<\/commit2>/sx;

# Set up the first author.
$ENV{'GIT_AUTHOR_NAME'} = 'Author1';
$ENV{'GIT_AUTHOR_EMAIL'} = 'author1@example.com';
$ENV{'GIT_COMMITTER_NAME'} = 'Author1';
$ENV{'GIT_COMMITTER_EMAIL'} = 'author1@example.com';

# Create a new file.
my $test_file = $work_tree . '/test.pl';
ok(
	open( my $fh, '>', $test_file ),
	'Create test file.'
) || diag( "Failed to open $test_file for writing: $!" );
print $fh $commit1_code;
close( $fh );

# Add the file to git.
lives_ok(
	sub
	{
		$repository->run( 'add', $test_file );
	},
	'Add test file to the Git index.',
);

lives_ok(
	sub
	{
		$repository->run( 'commit', '-m "First commit."' );
	},
	'Commit to Git.',
);
ok(
	my ( $log ) = $repository->log( '-1' ),
	'Retrieve the log of the commit.',
);
is(
	( split( /\s+/x, $log->author() || '' ) )[0],
	'Author1',
	'The author on the first commit is correct.'
);

# Set up the second author.
$ENV{'GIT_AUTHOR_NAME'} = 'Author2';
$ENV{'GIT_AUTHOR_EMAIL'} = 'author2@example.com';
$ENV{'GIT_COMMITTER_NAME'} = 'Author2';
$ENV{'GIT_COMMITTER_EMAIL'} = 'author2@example.com';

# Modify the file.
ok(
	open( $fh, '>', $test_file ),
	'Modify test file.'
) || diag( "Failed to open $test_file for writing: $!" );
print $fh $commit2_code;
close( $fh );

# Commit the changes to git.
lives_ok(
	sub
	{
		$repository->run( 'commit', '-m "Second commit."', '-a' );
	},
	'Commit to Git.',
);
ok(
	( $log ) = $repository->log( '-1' ),
	'Retrieve the log of the commit.',
);
is(
	( split( /\s+/x, $log->author() || '' ) )[0],
	'Author2',
	'The author on the second commit is correct.'
);

# Store the path to the git repository, for the other tests scripts to use.
ok(
	open( my $persistent, '>', 't/test_information' ),
	'Store the path to the test repository.'
) || diag( "Failed to open $test_file for writing: $!" );
print $persistent $work_tree;
close( $persistent );


__DATA__
<commit1>
#!/usr/bin/perl

use strict;

my $message = "Hello World";
print "$message\n";
</commit1>
<commit2>
#!/usr/bin/perl

use strict;

my $message = "Hello World";
print "$message\n";

sub test
{
	my ( %args ) = @_;
}
</commit2>

