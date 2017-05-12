#!/usr/bin/perl 

# Compile-testing for SMS::Send::AU::MyVodafone

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 4;

ok( $] >= 5.005, 'Perl version is 5.005 or newer' );

use_ok( 'SMS::Send' );
use_ok( 'SMS::Send::AU::MyVodafone' );

my @drivers = SMS::Send->installed_drivers;
is( scalar(grep { $_ eq 'AU::MyVodafone' } @drivers), 1, 'Found installed driver AU::MyVodafone' );

