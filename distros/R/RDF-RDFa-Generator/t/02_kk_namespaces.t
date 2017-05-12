#!/usr/bin/perl

# tests from KjetilK

use strict;
use Test::More;

use RDF::Trine::Model;

my $model = RDF::Trine::Model->temporary_model;

use RDF::Trine::Parser;
my $parser     = RDF::Trine::Parser->new( 'turtle' );
$parser->parse_into_model( 'http://example.org/', '</foo> a </Bar> .', $model );

use RDF::RDFa::Generator;

{
	ok(my $document = RDF::RDFa::Generator->new->create_document($model), 'Assignment OK');
	isa_ok($document, 'XML::LibXML::Document');
	my $string = $document->toString;

	unlike($string, qr|xmlns:http://www.w3.org/1999/02/22-rdf-syntax-ns#="rdf"|, 'RDF namespace shouldnt be reversed');
	like($string, qr|xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"|, 'Correct RDF namespace declaration');
}

done_testing();