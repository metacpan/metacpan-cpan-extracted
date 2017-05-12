#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'SQL::Tokenizer' );
}

diag( "Testing SQL::Tokenizer $SQL::Tokenizer::VERSION, Perl $], $^X" );
