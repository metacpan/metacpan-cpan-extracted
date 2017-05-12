package MooseX::Semantic::Test::MetaPerson;
use Moose;
use RDF::Trine::Namespace qw(foaf);
use MooseX::Semantic::Util::SchemaImport;

# test: t/util/schema_import/from_foaf.t

with (
#     # 'MooseX::Semantic::Util::SchemaImport',
#     # 'MooseX::Semantic::Role::RdfBackend',
#     # 'MooseX::Semantic::Role::RdfBackend',
    'MooseX::Semantic::Role::RdfSchemaImport' => { import_opts => {
            # model_uri => 'http://xmlns.com/foaf/spec/index.rdf',
            model_file => 't/data/ontologies/foaf.rdf',
            base_uri => 'http://xmlns.com/foaf/0.1/',
            uri => $foaf->Person,
            type_map => {
                $foaf->Person => __PACKAGE__,
            }
    }},
);

1;
