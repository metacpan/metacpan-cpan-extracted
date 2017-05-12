#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Regexp::MultiLanguage' );
}

diag( "Testing Regexp::MultiLanguage $Regexp::MultiLanguage::VERSION, Perl $], $^X" );
