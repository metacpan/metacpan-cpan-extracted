use Test::More skip_all => 'Need to write actual tests'; 
use Data::Dumper;
use MooseX::Semantic::Util::SchemaExport;
use MooseX::Semantic::Test::StrictPerson;
my $b = MooseX::Semantic::Util::SchemaExport->new;
# warn Dumper ($b->meta);
my $p = MooseX::Semantic::Test::StrictPerson->new(
    name => 'ABC'
);
# warn Dumper $p;
my $mod = $b->extract_ontology( $p );
my $serializer = RDF::Trine::Serializer->new('ntriples');
warn Dumper $serializer->serialize_model_to_string( $mod );

