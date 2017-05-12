#!/usr/bin/perl

# Test that the shim => 1 option works

BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 12;
use File::Spec::Functions ':ALL';
use t::lib::Test;





#####################################################################
# Set up for testing

# Connect
my $file = test_db();
my $dbh  = create_ok(
	file    => catfile(qw{ t 02_basics.sql }),
	connect => [ "dbi:SQLite:$file" ],
);

# Create the test package
eval <<"END_PERL"; die $@ if $@;
package Foo::Bar;

use strict;
use ORLite {
	file => '$file',
	shim => 1,
};

1;
END_PERL

CLASS: {
	package Foo::Bar::TableOne;

	use vars qw{$INCREMENT};
	BEGIN {
		$INCREMENT = 0;
	}

	# Overload new to increment the counter
	sub new {
		my $self = shift->SUPER::new(@_);
		$INCREMENT++;
		return $self;
	}

	1;
}

is( $Foo::Bar::TableOne::INCREMENT, 0, '->new calls = 0' );





#####################################################################
# Tests for the base package update methods

isa_ok(
	Foo::Bar::TableOne->create(
		col1 => 1,
		col2 => 'foo',
	),
	'Foo::Bar::TableOne',
);
is( $Foo::Bar::TableOne::INCREMENT, 1, '->new calls = 1' );

isa_ok(
	Foo::Bar::TableOne->create(
		col1 => 2,
		col2 => 'bar',
	),
	'Foo::Bar::TableOne',
);
is( Foo::Bar::TableOne->count, 2, 'Found 2 rows' );
is( $Foo::Bar::TableOne::INCREMENT, 2, '->new calls = 2' );

is(
	Foo::Bar::TableOne->count,
	2,
	'Count found 2 rows',
);
is( $Foo::Bar::TableOne::INCREMENT, 2, '->new calls = 2' );

SCOPE: {
	my $object = Foo::Bar::TableOne->load(1);
	isa_ok( $object, 'Foo::Bar::TableOne' );
	isa_ok( $object, 'Foo::Bar::TableOne::Shim' );
	is( $Foo::Bar::TableOne::INCREMENT, 2, '->new calls = 3' );
}
