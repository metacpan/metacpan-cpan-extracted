#!/usr/bin/perl

# Create a new database when opening a file that doesn't exist

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 13;
use File::Spec::Functions ':ALL';

# Prepare to test
my $test_dir    = catdir( 't', 'data' );
my $test_create = catfile( $test_dir, 'create.sqlite' );
ok( -d $test_dir, 'Test directory exists' );
ok( -r $test_dir, 'Test directory read permissions ok' );
ok( -w $test_dir, 'Test directory write permissions ok' );
ok( -x $test_dir, 'Test directory enter permissions ok' );
ok( ! -f $test_create, 'Test database does not exist yet' );
END { unlink $test_create if -f $test_create; }

# Do the whole thing in one hit...
use_ok( 'Perl::Metrics', $test_create );

# Get the database handle to the database
my $dbh = Perl::Metrics::CDBI->db_Main;
isa_ok( $dbh, 'DBI::db' );

# Does the expected tables exist?
my @tables = $dbh->tables('%', '%', '%');
ok( scalar(@tables), 'Got list of tables in the database' );
@tables = grep { ! /^sqlite_/ } @tables;
ok( scalar(@tables), 'Found at least one non-internal table' );
is( scalar(grep{ /\bfiles\b/ } @tables), 1,
	'Found files table' );
is( scalar(grep{ /\bmetrics\b/ } @tables), 1,
	'Found metrics table' );

# Retrieving all files should return nothing, but not die
my @objects = Perl::Metrics::File->retrieve_all;
is_deeply( \@objects, [ ], "File->retrieve_all doesn't die" );
@objects = Perl::Metrics::Metric->retrieve_all;
is_deeply( \@objects, [ ], "Metric->retrieve_all doesn't die" );

1;
