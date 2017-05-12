#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'RSSycklr' );
}

diag( "Testing RSSycklr $RSSycklr::VERSION, Perl $], $^X" );
