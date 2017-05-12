#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Net::Spotify' );
}

diag( "Testing Net::Spotify $Net::Spotify::VERSION, Perl $], $^X" );
