#!/usr/bin/perl

BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 4;
use File::Spec::Functions ':ALL';
use t::lib::Test;

# Check for migration patches
my $timeline = catdir( 't', 'data', 'trivial' );
ok( -d $timeline, 'Found timeline' );

# Set up the test database
my $file = test_db();

# Create the test package
eval <<"END_PERL"; die $@ if $@;
package Foo::Bar;

use strict;
use ORLite::Migrate {
	create       => 1,
	file         => '$file',
	timeline     => '$timeline',
	user_version => 3,
	prune        => 1,
};

1;
END_PERL

# The package should be migrated correctly
is( Foo::Bar->pragma('user_version'), 3, 'New database migrated ok' );
ok( Foo::Bar::Foo->can('count'), 'Created Foo table ok' );
is( Foo::Bar::Foo->count, 3, 'Found expected number of rows' );
