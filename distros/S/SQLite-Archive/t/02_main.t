#!/usr/bin/perl

BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 4;
use File::Spec::Functions ':ALL';
use SQLite::Archive;

# Locate of the test archive
my $dir = catdir( 't', 'data', 'simple' );
ok( -d $dir, 'Found simple test directory' );





#####################################################################
# Main Tests

# Create an archive object
my $archive = SQLite::Archive->new(
	dir => $dir,
);
isa_ok( $archive, 'SQLite::Archive' );

# Create the SQLite database
my $dbh = $archive->build_db;
isa_ok( $dbh, 'DBI::db' );

# Check that the expected database elements were created
my $rv = $dbh->selectall_arrayref('select * from foo order by id', { Slice => {} });
is_deeply( $rv, [
	{ id => 1, name => 'foo' },
	{ id => 2, name => 'bar' },
], 'Found expected records' );
