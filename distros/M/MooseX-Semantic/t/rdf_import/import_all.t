use Test::More tests => 10;
use Test::Exception;
use Data::Dumper;
use RDF::Trine;
use RDF::Trine::Namespace qw(foaf);
use MooseX::Semantic::Test::StrictPerson;

my $model = RDF::Trine::Model->new;
RDF::Trine::Parser::Turtle
	->new
	->parse_file_into_model('http://example.com/', 't/data/multiple_persons.ttl', $model);

{
    my @people = 
        sort { $a->name cmp $b->name }
        MooseX::Semantic::Test::StrictPerson->import_all_from_model($model);

    is(scalar @people, 4, "Correct number of people found.");
    is($people[0]->name, "Alice");
    is($people[1]->name, "Bob");
    is($people[2]->name, "Carol");
    is($people[3]->name, "Dave");
}

{
    my $schema_base = 'http://schema.org/';
    my $schema_Person = $schema_base . 'Person';
    my $schema_name = $schema_base . 'name';
    {
        package My::Model::Person;
        use RDF::Trine::Namespace qw(foaf);
        use Moose;
        with qw(MooseX::Semantic::Role::RdfImportAll);
        has name => ( is => 'rw', traits => ['Semantic'], uri => $foaf->name );
    }
    throws_ok { My::Model::Person->import_all_from_model($model) }
        qr/associated RDF types.*rdf_type/, "Can't import all without rdf_type";
    my @people;
    ok( @people = My::Model::Person->import_all( model => $model, rdf_type => $foaf->Person ) );
    is( scalar @people, 3, '3 My::Model::Person imported using foaf rdf_type as argument to import_all' );
    ok( @people = My::Model::Person->import_all( model => $model, rdf_type => [$schema_Person, $foaf->Person] ) );
    is( scalar @people, 5, '5 My::Model::Person imported using foaf and schema rdf_type as argument to import_all' );
}

