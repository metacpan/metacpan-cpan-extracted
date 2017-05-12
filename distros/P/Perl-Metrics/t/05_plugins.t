#!/usr/bin/perl

# Test the basic operations of plugins

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 16;
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
my $count = Perl::Metrics->index_directory( $test_dir_abs );
is( $count, 3, 'Added initial 3 files' );





#####################################################################
# Manually create a plugin object.

use Perl::Metrics::Plugin::Core;
my $core = Perl::Metrics::Plugin::Core->new;
isa_ok( $core, 'Perl::Metrics::Plugin::Core' );
isa_ok( $core, 'Perl::Metrics::Plugin'       );
my $metrics = $core->metrics;
is( ref($metrics), 'HASH', '->metrics returns a hash' );

# Iterate and process the file objects
ok( $core->process_index, '->process_index returns true' );

my @metrics = Perl::Metrics::Metric->retrieve_all( { order_by => 'hex_id, package, name' } );
is( scalar(@metrics), 4, '2 metrics on 3 files makes 4 metric objects, correctly' );

my @vals = ( 8, 15, 12, 25 );
foreach ( @metrics ) {
	my $hex_id = $_->hex_id;
	my $name   = $_->name;
	my $value  = $_->value;
	is( $value, shift(@vals), "$hex_id.$name: Value '$value' matches expected" );
}
