#!/usr/bin/perl

# tests from KjetilK

use strict;
use Test::More;

use AtteanX::Compatibility::Trine;


use_ok('RDF::RDFa::Generator');
my $store = Attean->get_store('Memory')->new();
my $parser = Attean->get_parser('Turtle')->new();

my $model = Attean::MutableQuadModel->new( store => $store  );

my $iter = $parser->parse_iter_from_bytes('<http://example.org/foo> a <http://example.org/Bar> ; <http://example.org/title> "Dahut"@fr ; <http://example.org/something> [ <http://example.org/else> "Foo" ; <http://example.org/pi> 3.14 ] .');

while (my $triple = $iter->next) {
	$model->add_quad($triple->as_quad(Attean::IRI->new('http://example.org/graph')));
}

subtest 'Default generator' => sub {
	ok(my $document = RDF::RDFa::Generator->new->create_document($model), 'Assignment OK');
	my $string = tests($document);
	like($string, qr|resource="http://example.org/Bar"|, 'Object present');
	like($string, qr|property="ex:title" content="Dahut"|, 'Literals OK');
};

subtest 'Hidden generator' => sub {
	ok(my $document = RDF::RDFa::Generator::HTML::Hidden->new->create_document($model), 'Assignment OK');
	my $string = tests($document);
	like($string, qr|resource="http://example.org/Bar"|, 'Object present');
	like($string, qr|property="ex:title" content="Dahut"|, 'Literals OK');
};

subtest 'Pretty generator' => sub {
	ok(my $document = RDF::RDFa::Generator::HTML::Pretty->new->create_document($model), 'Assignment OK');
	my $string = tests($document);
	like($string, qr|<dd property="ex:title" class="typed-literal" datatype="xsd:langString">Dahut</dd>|, 'Literals OK');
};

sub tests {
	my $document = shift;
	isa_ok($document, 'XML::LibXML::Document');
	my $string = $document->toString;
	like($string, qr|about="http://example.org/foo"|, 'Subject URI present');
	like($string, qr|rel="rdf:type"|, 'Type predicate present');
	like($string, qr|property="ex:pi"|, 'pi predicate present');
	like($string, qr|3\.14|, 'pi decimal present');
	return $string;
}
done_testing();
