#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Olson::Abbreviations' );
}

diag( "Testing Olson::Abbreviations $Olson::Abbreviations::VERSION, Perl $], $^X" );
