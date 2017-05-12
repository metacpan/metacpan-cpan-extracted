#!/usr/bin/perl

# Compile-testing for Object::Tiny::RW::XS

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 2;

ok( $] >= 5.004, 'Perl version is 5.004 or newer' );

require_ok( 'Object::Tiny::RW::XS' );
