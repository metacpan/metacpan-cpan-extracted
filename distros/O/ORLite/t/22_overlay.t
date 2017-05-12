#!/usr/bin/perl

# Tests that overlay modules are automatically loaded

BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 7;
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
package t::lib;

use strict;
use ORLite {
	file => '$file',
};

1;
END_PERL





#####################################################################
# Tests for the base package update methods

isa_ok(
	t::lib::TableOne->create(
		col1 => 1,
		col2 => 'foo',
	),
	't::lib::TableOne',
);

isa_ok(
	t::lib::TableOne->create(
		col1 => 2,
		col2 => 'bar',
	),
	't::lib::TableOne',
);
is( t::lib::TableOne->count, 2, 'Found 2 rows' );

is(
	t::lib::TableOne->count,
	2,
	'Count found 2 rows',
);

SCOPE: {
	my $object = t::lib::TableOne->load(1);
	isa_ok( $object, 't::lib::TableOne' );
	is( $object->dummy, 2, '->dummy ok (overlay was loaded)' );
}
