use strict;
use diagnostics;

use Cwd;
use File::Spec;
use File::Path;
use Test::More 1;

my $old_dir = cwd;

sub conf_file { $^O eq 'MSWin32' ? '.releaserc' : 'releaserc' }
my $dir = File::Spec->catfile( qw(t test_dir) );

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Setup a test directory
subtest test_dir => sub {
	mkdir $dir, 0755 unless -d $dir;
	ok( -d $dir, "Test directory is there" );

	ok( chdir( $dir ), "Changed into $dir" );
	END { chdir $old_dir; rmtree [ $dir ], 0, 1; }
	};

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Create empty configuration file
subtest create_empty_conf => sub {
	my $rc = open my $fh, '>:utf8', conf_file();
	my $error = $! unless $rc;

	ok( $rc, "Opened empty " . conf_file() );
	diag( "Error creating " . conf_file() . "! $!" ) unless $rc;
	close $fh;

	ok( -e conf_file(), conf_file() . " exists" );
	END { unlink conf_file() }
	};

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Clean up

