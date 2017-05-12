#!/usr/bin/perl

use Test::More tests => 1;

BEGIN {
	use_ok( 'Net::Amazon::MechanicalTurk' );
}

diag( "Testing Net::Amazon::MechanicalTurk $Net::Amazon::MechanicalTurk::VERSION, Perl $], $^X" );
