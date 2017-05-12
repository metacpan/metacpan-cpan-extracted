#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'RDF::Converter::CSV' );
}

diag( "Testing RDF::Converter::CSV $RDF::Converter::CSV::VERSION, Perl $], $^X" );
