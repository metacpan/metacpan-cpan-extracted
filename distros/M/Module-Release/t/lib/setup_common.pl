#!/usr/bin/perl
use strict;

use Test::More 1.0;

use File::Temp qw(tempdir);

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Setup a test directory
subtest test_dir => sub {
	my $temp_dir = tempdir( CLEANUP => 1 );
	ok( -d $temp_dir, "Test directory is there" );

	ok( chdir( $temp_dir ), "Changed into $temp_dir" )
		or diag( "Could not change into <$temp_dir>: $!" );
	};

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Create empty configuration file
my $conf_file;
subtest create_empty_conf => sub {
	require Module::Release;
	$conf_file = Module::Release->_select_config_file_name;
	my $rc = open my $fh, '>:encoding(UTF-8)', $conf_file;
	my $error = $! unless $rc;

	ok( $rc, "Opened empty <$conf_file>" );
	diag( "Error creating <$conf_file>: $!" ) unless $rc;
	close $fh;

	ok( -e $conf_file, "<$conf_file> exists" );
	END { unlink $conf_file }
	};

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Clean up


