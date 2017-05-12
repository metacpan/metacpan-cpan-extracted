#!/usr/bin/perl
# -*- coding: utf-8 -*-

use 5.010;
use utf8;
use RDF::TriN3;
use RDF::vCard;

# Turtle with vCard embbedded inside.
my $n3 = <<'DATA';
@prefix foaf: <http://xmlns.com/foaf/0.1/> .

BEGIN:VCARD
FN:Toby Inkster
NICKNAME:tobyink
END:VCARD
	foaf:knows
		BEGIN:VCARD
		FN:Kjetil Kjernsmo
		NICKNAME:kjetilk
		END:VCARD .

DATA

# Create a parser for that beast...
my $parser = RDF::Trine::Parser::ShorthandRDF->new(
	# Detect BEGIN:VCARD...END:VCARD and automatically convert to a typed literal.
	profile => '@dtpattern "(?i:BEGIN\:VCARD)(?s:(.+?))(?i:END\:VCARD)" <http://example.net/person> .',
	# Run this callback when the datatype is detected.
	datatype_callback => {
		'http://example.net/person' => sub
			{
				my ($node, $callback) = @_;

				# Node representing the person
				my $person = RDF::Trine::Node::Blank->new;

				# Adjust VCard whitespace
				my $vcard_data = $node->literal_value;
				$vcard_data =~ s/^\s*//mg;
				$vcard_data =~ s/\n\s*\n/\n/g;

				# Transform VCard into triples
				my $importer = RDF::vCard::Importer->new;
				my ($card) = $importer->import_string($vcard_data);

				# Provide statements to callback
				$callback->(RDF::Trine::Statement->new(
					$person,
					RDF::Trine::Node::Resource->new('http://purl.org/uF/hCard/terms/hasCard'),
					$card->node,
					));
				$importer->model->get_statements->each($callback);
				
				# Return the node representing the vcard holder
				return $person;
			},
		});

# Parse
my $model = RDF::Trine::Model->new;
$parser->parse_into_model('http://example.org/', $n3, $model);

# Serialize
my %ns = (
	v    => 'http://www.w3.org/2006/vcard/ns#',
	foaf => 'http://xmlns.com/foaf/0.1/',
	h    => 'http://purl.org/uF/hCard/terms/',
	);
print RDF::Trine::Serializer
	->new('Turtle', namespaces => \%ns)
	->serialize_model_to_string($model);
