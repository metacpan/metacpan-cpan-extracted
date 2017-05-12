#!perl
use strict;
use warnings;

use Test::More tests => 6;

use Cwd;
use File::Path qw(rmtree);
use File::Spec::Functions qw(rel2abs catfile);

my $dir = 'test-corpus';

my $executable = rel2abs( catfile( qw( blib script dpan ) ) );

# I only want to skip these if there are no distros to process. Other
# tests set up the test-corpus directory as an empty directory, so I
# don't want to check merely for the directory
SKIP: {
	skip "Test corpus is not present. Skipping tests.", 6 
		unless -d catfile( $dir, qw(authors id) );
	
	my $start_dir = cwd();
	chdir $dir;
	my $report_dir = 'indexer_reports';
	rmtree $report_dir;
	ok( ! -d $report_dir, "$report_dir is gone" );

	my $modules_dir = 'modules';
	rmtree $modules_dir;
	ok( ! -d $modules_dir, "$modules_dir is gone" );
	
	system( $^X, '-Mblib', $executable );
	
	ok( -d $report_dir, "$report_dir is there now" );

	ok( -d $modules_dir, "$modules_dir is gone" );

	my $package_file = catfile( $modules_dir, '02packages.details.txt.gz' );
 	ok( -e $package_file, "$package_file is there" );
	
	my $modlist_file = catfile( $modules_dir, '03modlist.data.gz' );
 	ok( -e $modlist_file, "$modlist_file is there" );
	
	chdir $start_dir;
	};
