#!/usr/bin/perl

# Tests mixed casing

use strict;

BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 51;
use File::Spec::Functions ':ALL';
use t::lib::Test;

# Set up the database
my $file = test_db();
my $dbh  = create_ok(
	file    => catfile(qw{ t 24_rowid.sql }),
	connect => [ "dbi:SQLite:$file" ],
);

# Create the test package
eval <<"END_PERL"; die $@ if $@;
package Foo::Bar;

use strict;
use ORLite {
	file     => '$file',
	array    => 1,
	x_update => 1,
};

1;
END_PERL





######################################################################
# No primary key

SCOPE: {
	my $object = Foo::Bar::One->create(
		rowid     => 123,
		firstname => 'Adam',
		lastname  => 'Kennedy',
		age       => 1,
	);
	isa_ok( $object, 'Foo::Bar::One' );
	is( $object->rowid, 1, '->rowid ok' );
	is( $object->firstname, 'Adam', '->firstname ok' );
	is( $object->lastname, 'Kennedy', '->lastname ok' );
	is( $object->age, 1, '->age ok' );

	# Create a clone of the object
	my $clone = Foo::Bar::One->create(
		firstname => 'Bob',
		lastname  => 'Kennedy',
		age       => 2,
	);
	isa_ok( $clone, 'Foo::Bar::One' );
	is( $clone->rowid, 2, '->rowid ok' );

	# Updating the clone should not change the original
	ok(
		$clone->update( age => 3 ),
		'Updating only one object',
	);
	my @check = Foo::Bar::One->select('where rowid = 1');
	is( scalar(@check), 1, 'Found original object' );
	is( $check[0]->age, 1, 'Age of original was not changed' );

	# Deleting the clone should not delete the original
	ok(
		$clone->delete,
		'Deleting only one object',
	);
	is( Foo::Bar::One->count, 1, 'One row remains' );
}





######################################################################
# Simple primary key

SCOPE: {
	my $object = Foo::Bar::Two->create(
		firstname => 'Adam',
		lastname  => 'Kennedy',
		age       => '123',
	);
	isa_ok( $object, 'Foo::Bar::Two' );
	is( $object->rowid, 1, '->rowid ok' );
	is( $object->id, 1, '->id ok' );
	is( $object->two_id, 1, '->two_id ok' );
	is( $object->firstname, 'Adam', '->firstname ok' );
	is( $object->lastname, 'Kennedy', '->lastname ok' );
	is( $object->age, 123, '->age ok' );
}





######################################################################
# Composite primary key

SCOPE: {
	my $object = Foo::Bar::Three->create(
		firstname => 'Adam',
		lastname  => 'Kennedy',
		age       => '123',
	);
	isa_ok( $object, 'Foo::Bar::Three' );
	is( $object->rowid, 1, '->rowid ok' );
	is( $object->firstname, 'Adam', '->firstname ok' );
	is( $object->lastname, 'Kennedy', '->lastname ok' );
	is( $object->age, 123, '->age ok' );
}





######################################################################
# View of a table with no keys

SCOPE: {
	my @list = Foo::Bar::Four->select;
	is( scalar(@list), 1, 'Found one object' );
	my $object = shift @list;
	isa_ok( $object, 'Foo::Bar::Four' );
	ok( ! $object->can('rowid'), '->rowid ok' );
	is( $object->firstname, 'Adam', '->firstname ok' );
	is( $object->lastname, 'Kennedy', '->lastname ok' );
	is( $object->age, 1, '->age ok' );
}





######################################################################
# View of a table with one key

SCOPE: {
	my @list = Foo::Bar::Five->select;
	is( scalar(@list), 1, 'Found one object' );
	my $object = shift @list;
	isa_ok( $object, 'Foo::Bar::Five' );
	ok( ! $object->can('rowid'), '->rowid ok' );
	is( $object->firstname, 'Adam', '->firstname ok' );
	is( $object->lastname, 'Kennedy', '->lastname ok' );
	is( $object->age, 123, '->age ok' );
}





######################################################################
# View of a table with a composite key

SCOPE: {
	my @list = Foo::Bar::Six->select;
	is( scalar(@list), 1, 'Found one object' );
	my $object = shift @list;
	isa_ok( $object, 'Foo::Bar::Six' );
	ok( ! $object->can('rowid'), '->rowid ok' );
	is( $object->firstname, 'Adam', '->firstname ok' );
	is( $object->lastname, 'Kennedy', '->lastname ok' );
	is( $object->age, 123, '->age ok' );
}





#####################################################################
# Table with a single non-integer primary key

SCOPE: {
	my $object = Foo::Bar::Seven->create(
		name => 'Adam',
		age  => '123',
	);
	isa_ok( $object, 'Foo::Bar::Seven' );
	is( $object->rowid, 1, '->rowid ok' );
	is( $object->name, 'Adam', '->firstname ok' );
	is( $object->age, 123, '->age ok' );
	
	# Update the object
	$object->update( age => 125 );
	
	# Load it back from the database
	my $loaded = Foo::Bar::Seven->load('Adam');
	isa_ok( $loaded, 'Foo::Bar::Seven' );
	is( $loaded->rowid, 1, '->rowid ok' );
	is( $loaded->name, 'Adam', '->firstname ok' );
	is( $loaded->age, 125, '->age ok' );
	
	# Delete the object
	$object->delete;
}
