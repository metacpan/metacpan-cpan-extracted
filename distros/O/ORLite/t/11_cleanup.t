#!/usr/bin/perl

# Repeat the previous test, this time with a live transaction at END-time

BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 4;
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
ok( Foo::Bar->begin, 'Created the transaction' );
ok( ! Foo::Bar->dbh->{AutoCommit}, '->{AutoCommit} is off' );

