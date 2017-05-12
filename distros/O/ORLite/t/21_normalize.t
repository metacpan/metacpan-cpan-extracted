#!/usr/bin/perl

# Tests mixed casing

use strict;

BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 78;
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
	file    => catfile(qw{ t 21_normalize.sql }),
	connect => [ "dbi:SQLite:$file" ],
);

# Create the test package
eval <<"END_PERL"; die $@ if $@;
package Foo::Bar;

use strict;
use ORLite {
	file => '$file',
};

1;
END_PERL

# Simple null transaction to stimulate any errors
Foo::Bar->begin;
Foo::Bar->rollback;

# Check the file name
$file = rel2abs($file);
is( Foo::Bar->sqlite, $file,              '->sqlite ok' );
is( Foo::Bar->dsn,    "dbi:SQLite:$file", '->dsn ok'    );

# Check the schema version
is( Foo::Bar->pragma('user_version'), 0, '->user_version ok' );

# Check metadata methods in the test table
is( Foo::Bar::TableOne->base, 'Foo::Bar', '->base ok' );
is( Foo::Bar::TableOne->table, 'tableOne', '->table ok' );
my $columns = Foo::Bar::TableOne->table_info;
is_deeply( $columns, [
	{
		cid        => 0,
		dflt_value => undef,
		name       => 'columnID',
		notnull    => 1,
		pk         => 1,
		type       => 'integer',
	},
	{
		cid        => 1,
		dflt_value => undef,
		name       => 'ColumnTwo',
		notnull    => 0,
		pk         => 0,
		type       => 'string',
	},
], '->table_info ok' );

# Populate the test table
ok(
	Foo::Bar::TableOne->create( columnID => 1, ColumnTwo => 'foo' ),
	'Created row 1',
);
isa_ok( Foo::Bar::TableOne->load(1), 'Foo::Bar::TableOne' );
my $new = Foo::Bar::TableOne->create( ColumnTwo => 'bar' );
isa_ok( $new, 'Foo::Bar::TableOne' );
is( $new->columnID, 2,     '->columnID ok' );
is( $new->ColumnTwo, 'bar', '->ColumnTwo ok' );
ok( ! $new->can('id'), 'Convenience ->id method is not created' );

ok(
	Foo::Bar::TableOne->create( ColumnTwo => 'bar' ),
	'Created row 3',
);

# Check the ->count method
is( Foo::Bar::TableOne->count, 3, 'Found 3 rows' );
is( Foo::Bar::TableOne->count('where ColumnTwo = ?', 'bar'), 2, 'Condition count works' );

sub test_ones {
	my $ones = shift;
	is( scalar(@$ones), 3, 'Got 3 objects' );
	isa_ok( $ones->[0], 'Foo::Bar::TableOne' );
	is( $ones->[0]->columnID, 1,     '->columnID ok' );
	is( $ones->[0]->ColumnTwo, 'foo', '->ColumnTwo ok' );
	isa_ok( $ones->[1], 'Foo::Bar::TableOne' );
	is( $ones->[1]->columnID, 2,     '->columnID ok' );
	is( $ones->[1]->ColumnTwo, 'bar', '->ColumnTwo ok' );
	isa_ok( $ones->[2], 'Foo::Bar::TableOne' );
	is( $ones->[2]->columnID, 3,     '->columnID ok' );
	is( $ones->[2]->ColumnTwo, 'bar', '->ColumnTwo ok' );
}

# Fetch the rows (list context)
test_ones(
	[ Foo::Bar::TableOne->select('order by columnID') ]
);

# Fetch the rows (scalar context)
test_ones(
	scalar Foo::Bar::TableOne->select('order by columnID')
);

SCOPE: {
	# Emulate select via iterate
	my $ones = [];
	Foo::Bar::TableOne->iterate( 'order by columnID', sub {
		push @$ones, $_;
	} );
	test_ones( $ones );

	# Partial fetch
	my $short = [];
	Foo::Bar::TableOne->iterate( 'order by columnID', sub {
		push @$short, $_;
		return 0;
	} );
	is( scalar(@$short), 1, 'Found only one record' );
	is_deeply( $short->[0], $ones->[0], 'Found the same first record' );

	# Lower level equivalent
	my $short2 = [];
	Foo::Bar->iterate( 'select * from tableOne order by columnID', sub {
		push @$short2, $_;
		return 0;
	} );
	is( scalar(@$short2), 1, 'Found only one record' );
	is_deeply( $short2->[0], [ 1, 'foo' ], 'Found correct alternative' );

	# Delete one of the objects via the class delete method
	my @delete = Foo::Bar::TableOne->select('where ColumnTwo = ?', 'bar');
	$_->delete foreach @delete;
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
	is( Foo::Bar->connected, !1, '->connected is false' );
	ok( Foo::Bar->begin, '->begin' );
	is( Foo::Bar->connected, 1,  '->connected is true' );
	isa_ok( Foo::Bar::TableOne->create, 'Foo::Bar::TableOne' );
	is( Foo::Bar::TableOne->count, 1, 'One row created' );
	ok( Foo::Bar->rollback, '->rollback' );
	is( Foo::Bar->connected, !1, '->connected is false' );
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





######################################################################
# Exceptions

# Load an object that does not exist
SCOPE: {
	my @rv = eval {
		Foo::Bar::TableOne->load(undef);
	};
	is( scalar(@rv), 0, 'Exception returns nothing' );
	like( $@, qr/Foo::Bar::TableOne row does not exist/, 'Foo::Bar::TableOne row does not exist' );
}






######################################################################
# ID Normalisation

# Test that the convenience ->id method is created
SCOPE: {
	my $foo = Foo::Bar::Foo->create( name => 'bar' );
	isa_ok( $foo, 'Foo::Bar::Foo' );
	is( $foo->foo_id, 1,   '->foo_id ok' );
	is( $foo->name, 'bar', '->name ok' );
	is( $foo->id, 1,       '->id ok' );
}
