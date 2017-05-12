#!/usr/bin/perl

# Compile-testing for Object::Tiny::XS

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 3;

ok( $] >= 5.004, 'Perl version is 5.004 or newer' );

require_ok( 'Object::Tiny::XS' );

my $bad = 0;
is( $bad, 0, '$bad ok' );
