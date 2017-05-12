#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Pod::From::GoogleWiki' );
}

diag( "Testing Pod::From::GoogleWiki $Pod::From::GoogleWiki::VERSION, Perl $], $^X" );
