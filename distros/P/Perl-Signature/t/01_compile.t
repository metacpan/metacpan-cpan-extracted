#!/usr/bin/perl

# Load test the Perl::Signature module

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}





# Does everything load?
use Test::More 'tests' => 3;

ok( $] >= 5.005, 'Your perl is new enough' );

use_ok('Perl::Signature'     );
use_ok('Perl::Signature::Set');

1;
