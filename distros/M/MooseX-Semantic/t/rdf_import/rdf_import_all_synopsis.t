use Test::More skip_all => 'Need to write actual tests'; 
use Data::Dumper;
{
    # My/Model/Person.pm
    package My::Model::Person;
    use Moose;
    with qw( MooseX::Semantic::Role::RdfImportAll MooseX::Semantic::Role::WithRdfType );
    __PACKAGE__->rdf_type([qw{http://xmlns.com/foaf/0.1/Person http://schema.org/Person}]);
    has name => (
        is         => 'rw',
        traits     => ['Semantic'],
        uri        => 'http://xmlns.com/foaf/0.1/name',
        uri_reader => [qw(http://schema.org/name)]
    );
}

my $model = RDF::Trine::Model->new;
RDF::Trine::Parser::Turtle->new->parse_file_into_model(
    'http://example.com/',
    't/data/multiple_persons.ttl',
    $model
);
my @people = My::Model::Person->import_all_from_model($model);
warn Dumper @people;
# print $people[0]->name; #Alice
# print $people[1]->name; #Bob
