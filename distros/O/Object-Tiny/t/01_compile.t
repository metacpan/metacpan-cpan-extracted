#!/usr/bin/perl

# Compile-testing for Object::Tiny

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 3;

ok( $] >= 5.004, 'Perl version is 5.004 or newer' );

require_ok( 'Object::Tiny' );

my $bad = 0;
is( $bad, 0, '$bad ok' );
