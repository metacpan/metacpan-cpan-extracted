#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'RDF::RDFa::Template' );
}

diag( "Testing RDF::RDFa::Template $RDF::RDFa::Template::VERSION, Perl $], $^X" );
