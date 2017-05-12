#!/usr/bin/perl

# Test that cleanup works

BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 2;
use File::Spec::Functions ':ALL';
use t::lib::Test;


#####################################################################
# Set up for testing

# Connect
my $file = test_db();
my $dbh  = create_ok(
	file    => catfile(qw{ t 10_cleanup.sql }),
	connect => [ "dbi:SQLite:$file" ],
);

# Create the test package
eval <<"END_PERL"; die $@ if $@;
package Foo::Bar;

use strict;
use ORLite {
	file    => '$file',
	cleanup => 'VACUUM ANALYZE',
};

1;
END_PERL


#####################################################################
# Run the tests

ok( Foo::Bar->can('orlite'), 'Created the ORLite class' );

