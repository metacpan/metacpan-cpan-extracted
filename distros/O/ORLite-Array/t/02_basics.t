#!/usr/bin/perl

# Tests the basic functionality of SQLite.

use strict;

BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 65;
use File::Spec::Functions ':ALL';
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

# Set up again
my $file = test_db();
my $dbh  = create_ok(
	file    => catfile(qw{ t 02_basics.sql }),
	connect => [ "dbi:SQLite:$file" ],
);

# Create the test package
eval <<"END_PERL"; die $@ if $@;
package Foo::Bar;

use strict;
use ORLite::Array '$file';

1;
END_PERL

Foo::Bar->begin;
Foo::Bar->rollback;

# Check the file name
$file = rel2abs($file);
is( Foo::Bar->sqlite, $file,              '->sqlite ok' );
is( Foo::Bar->dsn,    "dbi:SQLite:$file", '->dsn ok'    );

# Check the schema version
is( Foo::Bar->pragma('user_version'), 0, '->user_version ok' );

# Populate the test table
ok(
	Foo::Bar::TableOne->create( col1 => 1, col2 => 'foo' ),
	'Created row 1',
);
my $new = Foo::Bar::TableOne->create( col2 => 'bar' );
isa_ok( $new, 'Foo::Bar::TableOne' );
is( $new->col1, 2,     '->col1 ok' );
is( $new->col2, 'bar', '->col2 ok' );
ok(
	Foo::Bar::TableOne->create( col2 => 'bar' ),
	'Created row 3',
);

# Check the ->count method
is( Foo::Bar::TableOne->count, 3, 'Found 3 rows' );
is( Foo::Bar::TableOne->count('where col2 = ?', 'bar'), 2, 'Condition count works' );

sub test_ones {
	my $ones = shift;
	is( scalar(@$ones), 3, 'Got 3 objects' );
	isa_ok( $ones->[0], 'Foo::Bar::TableOne' );
	is( $ones->[0]->col1, 1,     '->col1 ok' );
	is( $ones->[0]->col2, 'foo', '->col2 ok' );
	isa_ok( $ones->[1], 'Foo::Bar::TableOne' );
	is( $ones->[1]->col1, 2,     '->col1 ok' );
	is( $ones->[1]->col2, 'bar', '->col2 ok' );
	isa_ok( $ones->[2], 'Foo::Bar::TableOne' );
	is( $ones->[2]->col1, 3,     '->col1 ok' );
	is( $ones->[2]->col2, 'bar', '->col2 ok' );

}

# Fetch the rows (list context)
test_ones(
	[ Foo::Bar::TableOne->select('order by col1') ]
);

# Fetch the rows (scalar context)
test_ones(
	scalar Foo::Bar::TableOne->select('order by col1')
);

SCOPE: {
	# Emulate select via iterate
	my $ones = [];
	Foo::Bar::TableOne->iterate( 'order by col1', sub {
		push @$ones, $_;
	} );
	test_ones( $ones );

	# Partial fetch
	my $short = [];
	Foo::Bar::TableOne->iterate( 'order by col1', sub {
		push @$short, $_;
		return 0;
	} );
	is( scalar(@$short), 1, 'Found only one record' );
	is_deeply( $short->[0], $ones->[0], 'Found the same first record' );

	# Lower level equivalent
	my $short2 = [];
	Foo::Bar->iterate( 'select * from table_one order by col1', sub {
		push @$short2, $_;
		return 0;
	} );
	is( scalar(@$short2), 1, 'Found only one record' );
	is_deeply( $short2->[0], [ 1, 'foo' ], 'Found correct alternative' );

	# Delete one of the objects via the class delete method
	my $rv1 = Foo::Bar::TableOne->delete('where col2 = ?', 'bar');
	is( $rv1, 2, 'Deleted 2 rows' );
	is( Foo::Bar::TableOne->count, 1, 'Confirm 2 rows were deleted' );

	# Delete one of the objects via the instance delete method
	ok( $ones->[0]->delete, 'Deleted object' );
	is( Foo::Bar::TableOne->count, 0, 'Confirm 1 row was deleted' );
}

# Database should now be empty
SCOPE: {
	my @none = Foo::Bar::TableOne->select;
	is_deeply( \@none, [ ], '->select ok with nothing' );

	my $none = Foo::Bar::TableOne->select;
	is_deeply( $none, [ ], '->select ok with nothing' );
}

# Transaction testing
SCOPE: {
	ok( Foo::Bar->begin, '->begin' );
	isa_ok( Foo::Bar::TableOne->create, 'Foo::Bar::TableOne' );
	is( Foo::Bar::TableOne->count, 1, 'One row created' );
	ok( Foo::Bar->rollback, '->rollback' );
	is( Foo::Bar::TableOne->count, 0, 'Commit ok' );

	ok( Foo::Bar->begin, '->begin' );
	isa_ok( Foo::Bar::TableOne->create, 'Foo::Bar::TableOne' );
	is( Foo::Bar::TableOne->count, 1, 'One row created' );
	ok( Foo::Bar->commit, '->commit' );
	is( Foo::Bar::TableOne->count, 1, 'Commit ok' );
}

# Truncate
SCOPE: {
	ok( Foo::Bar::TableOne->truncate, '->truncate ok' );
	is( Foo::Bar::TableOne->count, 0, 'Commit ok' );	
}
