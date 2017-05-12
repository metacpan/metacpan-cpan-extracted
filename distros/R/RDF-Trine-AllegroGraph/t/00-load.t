#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'RDF::Trine::AllegroGraph' );
}

diag( "Testing RDF::Trine::AllegroGraph $RDF::Trine::AllegroGraph::VERSION, Perl $], $^X" );
