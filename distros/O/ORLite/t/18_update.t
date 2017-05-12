#!/usr/bin/perl

# Tests for the experimental update methods

BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 10;
use File::Spec::Functions ':ALL';
use t::lib::Test;





#####################################################################
# Set up for testing

# Connect
my $file = test_db();
my $dbh  = create_ok(
	file    => catfile(qw{ t 18_update.sql }),
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

isa_ok(
	Foo::Bar::TableOne->create(
		col1 => 1,
		col2 => 'one',
	),
	'Foo::Bar::TableOne',
);





######################################################################
# Test for the table update method

# Check the object as is
my $one = Foo::Bar::TableOne->load(1);
isa_ok( $one, 'Foo::Bar::TableOne' );
is( $one->col1, 1, '->col1 ok' );
is( $one->col2, 'one', '->col2 ok' );

# Update one accessor row
is( $one->update( col2 => 'two' ), 1, '->update(accessor) ok' );
is_deeply(
	$one,
	Foo::Bar::TableOne->load(1),
	'Change is applied identically to object and database forms',
);

# Change a primary key as well
is( $one->update( col1 => 3, col2 => 'three' ), 1, '->update(pk) ok' );
is_deeply(
	$one,
	Foo::Bar::TableOne->load(3),
	'Change is applied identically to object and database forms',
);

# Do we throw an exception on now columns
eval {
	$one->update();
};
ok( $@, 'Exception thrown on null update' );
