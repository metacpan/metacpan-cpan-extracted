#!perl

use Test::More tests => 1;

BEGIN {
	use_ok( 'RDF::LinkedData' );
}

diag( "Testing RDF::LinkedData $RDF::LinkedData::VERSION, Perl $], $^X" );
