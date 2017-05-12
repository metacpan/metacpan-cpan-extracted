use Test::More 
    # tests=>4,
    skip_all => 'This was just a Proof of Concept, dont care for it now';
use Test::Moose;
use RDF::Trine::Namespace qw(rdf);
use RDF::Trine qw(iri);
use Data::Dumper;
use MooseX::Semantic::Test::Person;
use MooseX::Semantic::Test qw(ser ser_dump diff_models);

use MooseX::Semantic::Util::SchemaImport::Class;
use MooseX::Semantic::Util::SchemaImport::Attribute;

my $base_uri = 'http://myapp/';
my $test_model = RDF::Trine::Model->temporary_model;
RDF::Trine::Parser::Turtle->parse_file_into_model(
    $base_uri,
    't/data/person_moose_definition.ttl',
    $test_model,
);

my $MOOSE = 'http://moose.perl.org/onto#';
my $moose = RDF::Trine::Namespace->new($MOOSE);
my $myapp = RDF::Trine::Namespace->new($base_uri);
# my $classes;

# warn ser_dump( $test_model );

{ 
    package EmptyMoosePackage;
    use Moose;
    1;
}

ok(
my $foaf_metaclass_builder = MooseX::Semantic::Util::SchemaImport::Class->new_from_model(
    $test_model, 
    $myapp->FoafMixin
), 'loaded FoafMixin Metaclass Builder from model');
is(scalar @{$foaf_metaclass_builder->has_attribute}, 2, 'FoafMixin Metaclass Builder has 2 attributes');

is( scalar EmptyMoosePackage->meta->get_attribute_list, 0, 'EmptyMoosePackage has 0 attributes');
# my $classes_iter = $test_model->subjects( $rdf->type, $moose->Class );
# while (my $res = $classes_iter->next) {
 # }
$foaf_metaclass_builder->add_attributes_to_class( 'EmptyMoosePackage' );
is( scalar EmptyMoosePackage->meta->get_attribute_list, 2, 'EmptyMoosePackage has 2 attributes');
# warn Dumper(
    # EmptyMoosePackage->meta->get_attribute('knows')
# );
# warn Dumper __PACKAGE__->meta;


