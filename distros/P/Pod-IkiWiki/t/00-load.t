#!perl -T

use Test::More tests => 2;
use Test::NoWarnings;

BEGIN {
	use_ok( 'Pod::IkiWiki' );
}

diag( "Testing Pod::IkiWiki $Pod::IkiWiki::VERSION, Perl $], $^X" );
