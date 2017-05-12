#!/usr/bin/perl

# Process a directory

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 18;
use File::Spec::Functions ':ALL';

# Create the test metrics database, and fill it
my $test_dir     = catdir( 't', 'data' );
my $test_dir_abs = rel2abs( $test_dir );
my $test_create  = catfile( $test_dir, 'create.sqlite' );
ok( -d $test_dir, 'Test directory exists'                 );
ok( -r $test_dir, 'Test directory read permissions ok'    );
ok( -w $test_dir, 'Test directory write permissions ok'   );
ok( -x $test_dir, 'Test directory enter permissions ok'   );
ok( ! -f $test_create, 'Test database does not exist yet' );
END { unlink $test_create if -f $test_create; }
use_ok( 'Perl::Metrics', $test_create );





#####################################################################
# Process the directory and check results

Perl::Metrics->process_directory( $test_dir_abs );

my @metrics = Perl::Metrics::Metric->search(
	package => 'Perl::Metrics::Plugin::Core',
	{ order_by => 'hex_id, package, name' }
	);
is( scalar(@metrics), 4, '2 metrics on 3 files makes 4 metric objects, correctly' );

my @vals = ( 8, 15, 12, 25 );
foreach ( @metrics ) {
	my $hex_id = $_->hex_id;
	my $name   = $_->name;
	my $value  = $_->value;
	is( $value, shift(@vals), "$hex_id.$name: Value '$value' matches expected" );
}





#####################################################################
# Test cascading deletion

# Get the files
my @files = Perl::Metrics::File->retrieve_all(
	{ order_by => 'path' },
	);
is( scalar(@files), 3, 'Found 3 files' );

# The first and third are the same, so if we remove the first
# files no metrics should be deleted.
ok( $files[0]->delete, 'Deleted file 1' );
is( Perl::Metrics::Metric->search(
		package => 'Perl::Metrics::Plugin::Core',
		{ order_by => 'hex_id, package, name' }
	)->count, 4,
	'Removing a duplicate file leaves the same number of metrics' );

# The second should remove 2 of them
ok( $files[1]->delete, 'Deleted file 2' );
is( Perl::Metrics::Metric->search(
		package => 'Perl::Metrics::Plugin::Core',
		{ order_by => 'hex_id, package, name' }
	)->count, 2,
	'Removing a non-duplicate file removes the expected metrics' );

# The third should leave no metrics at all, regardless of class
ok( $files[2]->delete, 'Deleted file 3' );
is( Perl::Metrics::Metric->retrieve_all->count, 0,
	'Removing all files leaves no metrics' );

1;
