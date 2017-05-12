use strict;
use warnings;
use Test::More skip_all => 'See RDF::TrineX::RuleEngine::Jena'; 
use Test::Moose;
use Data::Dumper;
use MooseX::Semantic::Test qw(ser_dump ser);

use RDF::Trine;
use RDF::Closure;

my $model = RDF::Trine::Model->temporary_model;
my $schema = <<'EOF';
<rdf:RDF 
	xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" 
	xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#" 
	xmlns:owl="http://www.w3.org/2002/07/owl#" 
	xmlns:vs="http://www.w3.org/2003/06/sw-vocab-status/ns#" 
	xmlns:foaf="http://xmlns.com/foaf/0.1/" 
	xmlns:wot="http://xmlns.com/wot/0.1/" 
	xmlns:dc="http://purl.org/dc/elements/1.1/">

  <rdfs:Class rdf:about="http://xmlns.com/foaf/0.1/Person" rdfs:label="Person">
    <rdf:type rdf:resource="http://www.w3.org/2002/07/owl#Class"/>
    <rdfs:subClassOf><owl:Class rdf:about="http://xmlns.com/foaf/0.1/Agent"/></rdfs:subClassOf>
    <rdfs:subClassOf><owl:Class rdf:about="http://www.w3.org/2000/10/swap/pim/contact#Person" rdfs:label="Person"/></rdfs:subClassOf>
    <rdfs:subClassOf><owl:Class rdf:about="http://www.w3.org/2003/01/geo/wgs84_pos#SpatialThing" rdfs:label="Spatial Thing"/></rdfs:subClassOf>
  </rdfs:Class>

  <rdfs:Class rdf:about="http://xmlns.com/foaf/0.1/Agent" >
    <rdf:type rdf:resource="http://www.w3.org/2002/07/owl#Class"/>
    <owl:equivalentClass rdf:resource="http://purl.org/dc/terms/Agent"/>
  </rdfs:Class>

  <rdf:Property rdf:about="http://xmlns.com/foaf/0.1/interest" rdfs:label="interest">
    <rdf:type rdf:resource="http://www.w3.org/2002/07/owl#ObjectProperty"/>
    <rdfs:domain rdf:resource="http://xmlns.com/foaf/0.1/Agent"/>
    <rdfs:range rdf:resource="http://xmlns.com/foaf/0.1/Document"/>
  </rdf:Property>
</rdf:RDF>
EOF
# my $parser = RDF::Trine::Parser->new('rdfxml');
# $parser->parse_into_model( 'http://what.ever',  $schema, $model );

my $test_ttl = <<'EOTTL';
@prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
@prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .

<jim> rdfs:domain <Something> .
EOTTL
# <Something> rdfs:subClassOf <SomeOtherThing> .

my $parser = RDF::Trine::Parser->new('turtle');
$parser->parse_into_model( 'X:',  $test_ttl, $model );

my $reasoner = RDF::Closure::Engine->new('RDFS');
warn Dumper ser_dump $model;
warn Dumper $model->size;
$reasoner->closure();
warn Dumper $model->size;

done_testing;
