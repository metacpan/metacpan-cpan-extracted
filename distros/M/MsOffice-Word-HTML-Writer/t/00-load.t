#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'MsOffice::Word::HTML::Writer' );
}

diag( "Testing MsOffice::Word::HTML::Writer $MsOffice::Word::HTML::Writer::VERSION, Perl $], $^X" );
