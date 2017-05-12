#!/usr/bin/perl

# Tests the basic functionality of SQLite.

use strict;

BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 30;
use File::Spec::Functions ':ALL';
use File::Remove 'clear';
use URI::file ();
use t::lib::Test;

# Flush any existing mirror database file
clear(mirror_db('ORLite::Mirror::Test'));

# Set up the file
my $file = test_db();
my $dbh  = create_ok(
	catfile(qw{ t 02_basics.sql }),
	"dbi:SQLite:$file",
);

# Convert the file into a URI
my $url = URI::file->new_abs($file)->as_string;

# Create the test package
eval <<"END_PERL"; die $@ if $@;
package ORLite::Mirror::Test;

use strict;
use vars qw{\$VERSION};
BEGIN {
	\$VERSION = '1.00';
}

use ORLite::Mirror {
	url          => '$url',
	stub         => 1,
	update       => 'connect',
	user_version => 7,
	prune        => 1,
	array        => 0,
};

1;

END_PERL

foreach ( qw{ orlite sqlite dsn dbh } ) {
	ok(
		ORLite::Mirror::Test->can($_),
		"Created '$_' method",
	);
}

# Connect around the main mechanism and validate
# the database is empty when it's just a stub.
SCOPE: {
	my $temp = DBI->connect(
		ORLite::Mirror::Test->dsn, undef, undef,
	);
	isa_ok( $temp, 'DBI::db' );
	my @rv = $temp->selectall_arrayref('select * from table_one');
	is_deeply( \@rv, [ [ ] ], 'Found no records' );
	$temp->disconnect;
}

# Check the ->count method
is( ORLite::Mirror::Test::TableOne->count, 3, 'Found 3 rows' );
is( ORLite::Mirror::Test::TableOne->count('where col2 = ?', 'bar'), 2, 'Condition count works' );

# Fetch the rows (list context)
SCOPE: {
	my @ones = ORLite::Mirror::Test::TableOne->select('order by col1');
	is( scalar(@ones), 3, 'Got 3 objects' );
	isa_ok( $ones[0], 'ORLite::Mirror::Test::TableOne' );
	isa_ok( $ones[1], 'ORLite::Mirror::Test::TableOne' );
	isa_ok( $ones[2], 'ORLite::Mirror::Test::TableOne' );
	is( $ones[0]->col1, 1,     '->col1 ok' );
	is( $ones[1]->col1, 2,     '->col1 ok' );
	is( $ones[2]->col1, 3,     '->col1 ok' );
	is( $ones[0]->col2, 'foo', '->col2 ok' );
	is( $ones[1]->col2, 'bar', '->col2 ok' );
	is( $ones[2]->col2, 'bar', '->col2 ok' );
}

# Fetch the rows (scalar context)
SCOPE: {
	my $ones = ORLite::Mirror::Test::TableOne->select('order by col1');
	is( scalar(@$ones), 3, 'Got 3 objects' );
	isa_ok( $ones->[0], 'ORLite::Mirror::Test::TableOne' );
	isa_ok( $ones->[1], 'ORLite::Mirror::Test::TableOne' );
	isa_ok( $ones->[2], 'ORLite::Mirror::Test::TableOne' );
	is( $ones->[0]->col1, 1,     '->col1 ok' );
	is( $ones->[1]->col1, 2,     '->col1 ok' );
	is( $ones->[2]->col1, 3,     '->col1 ok' );
	is( $ones->[0]->col2, 'foo', '->col2 ok' );
	is( $ones->[1]->col2, 'bar', '->col2 ok' );
	is( $ones->[2]->col2, 'bar', '->col2 ok' );

	ok( ! ORLite::Mirror::Test::TableOne->can('delete'), 'Did not add data manipulation methods' );
}
