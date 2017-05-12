use Test::More;
use Test::Moose;
use RDF::Trine;
use Data::Dumper;
use MooseX::Semantic::Test qw(ser ser_dump diff_models);

use MooseX::Semantic::Test::BackendPerson;


MooseX::Semantic::Test::BackendPerson->rdf_store({
    storetype => 'DBI',
    name => 'semantic_moose',
    dsn => 'dbi:SQLite:dbname=t/data/semantic_moose.sqlite',
    username => 'FAKE',
    password => 'FAKE',
});

isa_ok( MooseX::Semantic::Test::BackendPerson->rdf_store, 'RDF::Trine::Store');
is( MooseX::Semantic::Test::BackendPerson->rdf_store->model_name, 'semantic_moose');
my $store = MooseX::Semantic::Test::BackendPerson->rdf_store;
# warn Dumper $store;

my $rdf_about_uri = 'http://example/#me';
my $p = MooseX::Semantic::Test::BackendPerson->new(rdf_about => $rdf_about_uri, name => 'kb', favorite_numer => 3);
# warn Dumper $p->name;
# warn Dumper $p->meta->get_attribute('name');
# warn Dumper [$p->meta->get_attribute_list];
# warn Dumper [$p->meta->get_class_attribute_list];
# warn Dumper $p;
$p->store;
my $p2 = MooseX::Semantic::Test::BackendPerson->new_from_store( $rdf_about_uri );
# warn Dumper $p2;
is($p->name, $p2->name, 'Backend Person can be round-tripped');

done_testing;
