#!/usr/bin/perl 

# Compile-testing for SMS::Send::RedOxygen

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 4;

ok( $] >= 5.005, 'Perl version is 5.005 or newer' );

use_ok( 'SMS::Send' );
use_ok( 'SMS::Send::RedOxygen' );

my @drivers = SMS::Send->installed_drivers;
is( scalar(grep { $_ eq 'RedOxygen' } @drivers), 1, 'Found installed driver RedOxygen' );

