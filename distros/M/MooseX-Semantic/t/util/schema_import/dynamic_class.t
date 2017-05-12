# use Test::More tests=>5;
use Test::More 
    # skip_all => 'TODO: re-test this with RDF::TrineX::RuleEngine::Jena'
    ;
use Test::Moose;
use RDF::Trine::Namespace qw(rdf);
use Data::Dumper;
use MooseX::Semantic::Test qw(ser ser_dump diff_models);
use Module::Load;
use Try::Tiny;
use RDF::Trine::Namespace qw(foaf rdfs xsd);
use MooseX::Semantic::Util::SchemaImport;

my $foaf_Person_cls = 'My::Test::Bla::Foo::Person';
my $foaf_Document_cls = 'My::Test::Bla::Foo::Document';

my $type_map = {
    $foaf->Person => $foaf_Person_cls,
    $foaf->Document => $foaf_Document_cls,
};
my $importer = MooseX::Semantic::Util::SchemaImport->new;

{
    diag "without reasoning";
    $importer->initialize_classes_from_model(
        base_uri => $foaf,
        model_file => 't/data/ontologies/foaf.rdf',
        type_map => $type_map,
    );


    ok( $type_map->{ $foaf->Person }->meta, 'foaf:Person mapped to Moose' );
    ok( $type_map->{ $foaf->Document }->meta, 'foaf:Document mapped to Moose' );
    is( scalar $foaf_Person_cls->meta->get_attribute_list,
        16,
        '16 attributes for foaf:Person');
    is( scalar $foaf_Document_cls->meta->get_attribute_list,
        2,
        '2 attributes for foaf:Document');
    is( $foaf_Person_cls->meta->get_attribute('knows')->type_constraint->name,
        'ArrayRef[My::Test::Bla::Foo::Person]', 
        'foaf:knows is right for foaf:Person');
}
#{
#    diag "with reasoning";
#
#    my $parser = RDF::Trine::Parser->new('rdfxml');
#
#    my $model_ass = RDF::Trine::Model->temporary_model;
#    $parser->parse_file_into_model('http://example.org', 't/data/ontologies/foaf.rdf', $model_ass);
#    warn Dumper $model_ass->size;
#
#
#    my $inferred = qx{bash bin/reason.sh t/data/ontologies/foaf.rdf};
#    my $model_inf = RDF::Trine::Model->temporary_model;
#    $parser->parse_into_model('http://example.org', $inferred, $model_inf);
#    warn Dumper $model_inf->size;
#
#    $importer->initialize_classes_from_model(
#        base_uri => $foaf,
#        model => $model_inf,
#        type_map => $type_map,
#    );
#
#    ok( $type_map->{ $foaf->Person }->meta, 'foaf:Person mapped to Moose' );
#    ok( $type_map->{ $foaf->Document }->meta, 'foaf:Document mapped to Moose' );
#    is( scalar $foaf_Person_cls->meta->get_attribute_list,
#        16,
#        '16 attributes for foaf:Person');
#    is( scalar $foaf_Document_cls->meta->get_attribute_list,
#        2,
#        '2 attributes for foaf:Document');
#    warn Dumper $foaf_Document_cls->meta->get_attribute_list;
#    is( $foaf_Person_cls->meta->get_attribute('knows')->type_constraint->name,
#        'ArrayRef[My::Test::Bla::Foo::Person]', 
#        'foaf:knows is right for foaf:Person');
#}
done_testing;
