#!/usr/bin/perl

# Index a file

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 29;
use File::Spec::Functions ':ALL';





# Create the empty test metrics database
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





# Locate the file to index
my $test_file = catfile( $test_dir, 'Hello.pm' );
ok( -f $test_file, 'Test file exists' );
ok( -r $test_file, 'Test file is readable' );
my $test_file_abs = rel2abs( $test_file );
ok( -f $test_file_abs, 'Test file exists (absolute path)' );
ok( -r $test_file_abs, 'Test file is readable (absolute path)' );

# Because the hex_id assumes unix newlines, we should be able to 
# know the hex_id of the file in advance accurately.
my $hex_id = 'e9ef626212b3ef354d1786474431fe81';





#####################################################################
# Main Tests

# Index the file
my $time_before = time;
my $object      = Perl::Metrics->index_file( $test_file_abs );
my $time_after  = time;
isa_ok( $object, 'Perl::Metrics::File' );
ok( ! $object->is_changed, 'Object is synced to the database' );
is( $object->path, $test_file_abs, '->path matches the file name' );
like( $object->checked, qr/^\d+$/, '->checked contains digits' );
ok( $object->checked >= $time_before, '->checked is in the correct time range' );
ok( $object->checked <= $time_after,  '->checked is in the correct time range' );
is( $object->hex_id, $hex_id, '->hex_id returns the expected value' );

# Searching for metrics at this point should returns nothing, but not die
is_deeply( [ $object->metrics ], [], '->metrics returns a null list' );

# To validate it actually inserting, retrieve it again
my $object2 = Perl::Metrics::File->retrieve( $test_file_abs );
isa_ok( $object, 'Perl::Metrics::File' );
is( $object->path, $test_file_abs, '->path matches the file name' );

# Check that the ::File->metrics method works correctly in both
# scalar and list forms.
my $metrics_scalar = $object2->metrics;
isa_ok( $metrics_scalar, 'Class::DBI::Iterator' );
my @metrics_list = $object->metrics;
is_deeply( \@metrics_list, [ ], '->metrics in list form returns no objects' );





# Inserting an entire directory
my $hex_hello_world = '8e0554faf1a91139b7f15a77df117542';
my $count = Perl::Metrics->index_directory( $test_dir_abs );
is( $count, 3, '->index_directory adds 3 files' );
my @objects = Perl::Metrics::File->retrieve_all;
is( scalar(@objects), 3, 'Total of 3 despite only 3 added' );
@objects = Perl::Metrics::File->search( hex_id => $hex_hello_world );
is( scalar(@objects), 2, 'Multiple files get the same hex_id when expected' );





# Can the object be loaded as document
@objects = Perl::Metrics::File->retrieve_all;
is( scalar(@objects), 3, 'Found 3 objects' );
foreach my $file ( @objects ) {
	my $Document = $file->Document;
	isa_ok( $Document, 'PPI::Document' );
}

1;
