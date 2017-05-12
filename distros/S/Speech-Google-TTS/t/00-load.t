#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Speech::Google::TTS' );
}

diag( "Testing Speech::Google::TTS $Speech::Google::TTS::VERSION, Perl $], $^X" );
