#!/usr/bin/perl

# Tests relating to primary keys.

BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 6;
use File::Spec::Functions ':ALL';
use t::lib::Test;


#####################################################################
# Set up for testing

# Connect
my $file = test_db();
my $dbh  = create_ok(
	file    => catfile(qw{ t 07_pk.sql }),
	connect => [ "dbi:SQLite:$file" ],
);

# Create the test package
eval <<"END_PERL"; die $@ if $@;
package Foo::Bar;

use strict;
use ORLite::Array '$file';

1;
END_PERL


#####################################################################
# Run the tests

my @t1 = Foo::Bar::TableOne->select;
is( scalar(@t1), 9, 'Got 9 table_one objects' );
isa_ok( $t1[0], 'Foo::Bar::TableOne' );
is( $t1[2]->delete(), 1, 'One entry deleted');
@t1 = Foo::Bar::TableOne->select('where col1 = ?', 1);
is( scalar(@t1), 2, 'Got 2 table_one objects' );
@t1 = Foo::Bar::TableOne->select('where col1 = ? and col2 = ?', 1, 2);
is( $t1[0]->col3, 'b', 'Got line with col3 = b');

1;
