#!/usr/bin/perl

# Tests relating to foreign keys.

BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 5;
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
use ORLite '$file';

1;
END_PERL





#####################################################################
# Run the tests

my @t2 = Foo::Bar::TableTwo->select;
is( scalar(@t2), 1, 'Got one table_two object' );
isa_ok( $t2[0], 'Foo::Bar::TableTwo' );

is( $t2[0]->col1, 1, '->col1 ok' );
isa_ok( $t2[0]->col2, 'Foo::Bar::TableOne' );
