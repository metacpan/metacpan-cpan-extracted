use Test::More tests=>2;
use Test::Moose;
use RDF::Trine;
use Data::Dumper;
{
    package My::Model::Person;
    use Moose;
    with qw(MooseX::Semantic::Role::RdfImport);
    has name => (
        traits => ['Semantic'],
        is => 'rw',
        isa => 'Str',
        uri => 'http://xmlns.com/foaf/0.1/name',
        uri_reader => ['http://myont.org/onto#name'],
    );
}

    package main;
    my $base_uri = 'http://myont.org/data/';
    my $rdf_in_turtle = '
        <http://myont.org/data/Lenny> <http://xmlns.com/foaf/0.1/name> "Lenny" .
        <http://myont.org/data/Carl> <http://myont.org/onto#name> "Carl" .
    ';
    my $model = RDF::Trine::Model->temporary_model;
    RDF::Trine::Parser::Turtle->parse_into_model($base_uri, $rdf_in_turtle, $model);
    my $lenny = My::Model::Person->new_from_model($model, 'http://myont.org/data/Lenny');
    my $carl = My::Model::Person->new_from_model($model, 'http://myont.org/data/Carl');
    # print $lenny->name;     # 'Lenny'
    # print $carl->name;      # 'Carl'

    is ($lenny->name, 'Lenny');
    is ($carl->name, 'Carl');
