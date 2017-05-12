#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'OpenOffice::Wordlist' );
}

diag( "Testing OpenOffice::Wordlist $OpenOffice::Wordlist::VERSION, Perl $], $^X" );
