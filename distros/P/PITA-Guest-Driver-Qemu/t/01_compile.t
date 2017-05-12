#!/usr/bin/perl

# Compile-testing for PITA::Guest::Driver::Qemu

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 2;

ok( $] > 5.005, 'Perl version is 5.005 or newer' );

use_ok( 'PITA::Guest::Driver::Qemu' );

exit(0);
