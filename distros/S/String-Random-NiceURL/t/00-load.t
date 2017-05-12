#!/usr/bin/perl

use Test::More tests => 1;

BEGIN {
	use_ok( 'String::Random::NiceURL' );
}

diag( "Testing String::Random::NiceURL $String::Random::NiceURL::VERSION, Perl $], $^X" );
