#!/usr/bin/perl

BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 4;
use File::Spec::Functions ':ALL';
use ORLite::Migrate::Timeline ();
use t::lib::Test;
use t::lib::MyTimeline;

# Set up the file
my $file = test_db();

# Create the test package
eval <<"END_PERL"; die $@ if $@;
package Foo::Bar;

use strict;
use ORLite::Migrate {
	file         => '$file',
	timeline     => 't::lib::MyTimeline',
	user_version => 3,
	prune        => 1,
};

1;
END_PERL

can_ok( 'Foo::Bar', 'do' );
can_ok( 'Foo::Bar', 'orlite' );
is( Foo::Bar::Foo->base, 'Foo::Bar', 'Foo::Bar::Foo created' );
is( Foo::Bar->pragma('user_version'), 3, 'user_version is 3' );
