#!/usr/bin/perl

# Tests the basic functionality of SQLite.

use strict;

BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 6;
use File::Spec::Functions ':ALL';
use t::lib::Test;

# Set up the test database
my $file = test_db();
create_ok(
	file    => catfile(qw{ t 02_basics.sql }),
	connect => [ "dbi:SQLite:$file" ],
);
eval <<"END_PERL";
package Foo::Bar;

use strict;
use ORLite {
	file => '$file',
};
use ORLite::PDL;

1;
END_PERL
is( $@, '', 'Created test Foo::Bar package' );

# Populate the test table
foreach ( 1 .. 3 ) {
	Foo::Bar::TableOne->create( col1 => $_ );
}
is( Foo::Bar::TableOne->count, 3, 'Created three rows' );

# Get the pdl
my $pdl = Foo::Bar->selectcol_pdl(
	'select col1 from table_one order by col1',
);
isa_ok( $pdl, 'PDL' );

# Is it the correct data?
my $stdv = $pdl->stdv;
isa_ok( $stdv, 'PDL' );
is( substr("$stdv", 0, 5), "0.816", 'Got the expected selectcol_pdl result' );
