#!/usr/bin/perl

# The same as 12_xs.t except with array => 1

BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More;

# Only run this test if we have Class::XSAccessor
BEGIN {
	eval { require Class::XSAccessor::Array };
	if ( ! $@ and Class::XSAccessor::Array->VERSION and Class::XSAccessor::Array->VERSION >= 1.05 ) {
		plan( tests => 7 );
	} else {
		plan( skip_all => 'Class::XSAccessor::Array 1.05 is not installed' );
	}
}
use File::Spec::Functions ':ALL';
use t::lib::Test;





#####################################################################
# Set up for testing

# Connect
my $file = test_db();
my $dbh  = create_ok(
	file    => catfile(qw{ t 03_fk.sql }),
	connect => [ "dbi:SQLite:$file" ],
);

# Create the test package
eval <<"END_PERL"; die $@ if $@;
package Foo::Bar;

use strict;
use ORLite {
	file       => '$file',
	array      => 1,
	xsaccessor => 1,
};

1;
END_PERL





#####################################################################
# Run the tests

my @t2 = Foo::Bar::TableTwo->select;
is( scalar(@t2), 1, 'Got one table_two object' );
isa_ok( $t2[0], 'Foo::Bar::TableTwo' );

is( $t2[0]->col1, 1, '->col1 ok' );
isa_ok( $t2[0]->col2, 'Foo::Bar::TableOne' );
is( $t2[0]->col2->col1, 1, '->col1 of fk ok' );
is( $t2[0]->col2->col2, 2, '->col2 of fk ok' );
