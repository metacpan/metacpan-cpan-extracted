#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Quiz::Flashcards' );
}

diag( "Testing Quiz::Flashcards $Quiz::Flashcards::VERSION, Perl $], $^X" );
