#!/usr/bin/perl

# Tests the basic functionality of SQLite.

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 6;
use File::Spec::Functions ':ALL';
use File::pushd;
use t::lib::Test;

SCOPE: {
	# Test file
	my $file = test_db();

	# Connect
	my $dbh = connect_ok("dbi:SQLite:$file");
	$dbh->begin_work;
	$dbh->rollback;
	ok( $dbh->disconnect, 'disconnect' );
}

SCOPE: {
	# Generate the distribution core
	my $dist = create_dist('03_basics.sql');

	# Generate the documentation
	my $pushd = pushd( $dist );
	unshift @INC, 'lib';
	require Foo::Bar;
	ORLite::Pod->new(
		from   => 'Foo::Bar',
		to     => 'lib',
		author => 'Author Name',
		email  => 'email@example.com',
	)->run;

	# Check for the files we expect to be created
	ok(
		-f catfile( 'lib', 'Foo', 'Bar.pod' ),
		'Created Foo/Bar.pod',
	);
	ok(
		-f catfile( 'lib', 'Foo', 'Bar', 'TableOne.pod' ),
		'Created Foo/Bar/TableOne.pod',
	);
	ok(
		-f catfile( 't', 'pod.t' ),
		'Created t/pod.t',
	);
}
