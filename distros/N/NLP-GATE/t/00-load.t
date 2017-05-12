#!perl

use Test::More tests => 5;

BEGIN {
        use_ok( 'XML::Writer' );
	use_ok( 'NLP::GATE' );
	use_ok( 'NLP::GATE::Document' );
	use_ok( 'NLP::GATE::Annotation' );
	use_ok( 'NLP::GATE::AnnotationSet' );
}

diag( "Testing GATE $NLP::GATE::VERSION, Perl $], $^X" );
