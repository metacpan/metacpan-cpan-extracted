#!/usr/bin/perl

BEGIN {
	$| = 1;
	$^W = 1;
}

use Test::More tests => 2;
use Test::NoWarnings;
use OpenGL;
use OpenGL::List;

# Basic test of the normal stuff
my $id = OpenGL::List::glpList {
	# Null test
};
ok( defined $id, 'Got an id' );
