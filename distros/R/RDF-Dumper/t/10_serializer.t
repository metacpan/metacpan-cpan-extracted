use strict;

use Test::More;
use RDF::Trine qw(statement iri);
use RDF::Trine::Model;
use RDF::Trine::Serializer;

use RDF::Dumper;

my $serializer = RDF::Trine::Serializer->new( 'turtle' );
my $model = RDF::Trine::Model->temporary_model;
my $stm = statement( iri('my:a'), iri('my:b'), iri('my:c') );

$model->add_statement( $stm );

my $ttl = $serializer->serialize_model_to_string( $model );

is( rdfdump($model), $ttl, 'model' );
is( rdfdump($model->as_stream), $ttl, 'iterator' );
is( rdfdump($stm), $ttl, 'statement' );
is( rdfdump($serializer, $model), $ttl, 'serializer' );

done_testing;
