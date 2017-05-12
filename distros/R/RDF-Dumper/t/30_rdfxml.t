use strict;

use Test::More;
use RDF::Trine qw(statement iri);
use RDF::Trine::Model;
use RDF::Trine::Serializer;
use RDF::Trine::Parser;
use utf8;

use RDF::Dumper rdfdump => { format => 'rdfxml' };

my $parser = RDF::Trine::Parser->new('rdfxml');
my $model = RDF::Trine::Model->temporary_model;
my $rdf = join '', <DATA>;

$parser->parse_into_model( iri('http://localhost/'), $rdf, $model );

my $serializer = RDF::Trine::Serializer->new( 'rdfxml' );

my $rdfxml = $serializer->serialize_model_to_string($model);

is( rdfdump($model), $rdfxml, 'rdfxml (model)' );
is( rdfdump($model->as_stream), $rdfxml, 'rdfxml (iterator)' );

done_testing;

__DATA__
<?xml version="1.0" encoding="UTF-8" ?>
<rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
         xmlns:dc="http://purl.org/dc/elements/1.1/">
  <rdf:Description rdf:about="http://de.wikipedia.org/wiki/Resource_Description_Framework">
    <dc:title>Resource Description Framework</dc:title>
    <dc:publisher>Wikipedia - Die freie Enzyklopaedie</dc:publisher>
  </rdf:Description>
</rdf:RDF>
