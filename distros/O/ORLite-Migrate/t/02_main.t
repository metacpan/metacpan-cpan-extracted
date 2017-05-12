#!/usr/bin/perl

BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 5;
use File::Spec::Functions ':ALL';
use ORLite::Migrate ();
use t::lib::Test;

# Check for migration patches
my $timeline = catdir( 't', 'data', 'trivial' );
ok( -d $timeline, 'Found timeline' );

# Locate patches
my @patches = ORLite::Migrate::patches( $timeline );
is_deeply(
	\@patches,
	[ undef, 'migrate-1.pl', 'migrate-02.pl', 'migrate-03.pl' ],
	'Found the expected patch set',
);

# Find a plan
my @plan = ORLite::Migrate::plan( $timeline, 1 );
is_deeply(
	\@plan,
	[ 'migrate-02.pl', 'migrate-03.pl' ],
	'Found expected plan',
);

# Set up the file
my $file = test_db();

# Create the test package
eval <<"END_PERL"; die $@ if $@;
package Foo::Bar;

use strict;
use ORLite {
	file   => '$file',
	create => 1,
	prune  => 1,
};

1;
END_PERL

can_ok( 'Foo::Bar', 'do' );
can_ok( 'Foo::Bar', 'orlite' );

