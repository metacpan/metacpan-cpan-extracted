package MooseX::Semantic::Test::BackendPerson;
use Moose;
with (
    'MooseX::Semantic::Role::RdfBackend',
    'MooseX::Semantic::Role::RdfImport',
    'MooseX::Semantic::Role::RdfExport',
    'MooseX::Semantic::Role::RdfObsolescence',
    # 'MooseX::Semantic::Role::WithRdfType',
    # 'MooseX::Semantic::Role::Resource',
);

# extends 'MooseX::Semantic::Test::Person';

__PACKAGE__->rdf_type('http://xmlns.com/foaf/0.1/Person');

has name => (
    traits => ['Semantic'],
    is => 'rw',
    isa => 'Str',
    uri => 'http://xmlns.com/foaf/0.1/name',
);
has topic_interest => (
    traits => ['MooseX::Semantic::Meta::Attribute::Trait'],
    is => 'rw',
    isa => 'ArrayRef',
    uri => 'http://xmlns.com/foaf/0.1/topic-interest',
);
has country => (
    traits => ['MooseX::Semantic::Meta::Attribute::Trait'],
    is => 'rw',
    isa => 'Str',
    uri => 'http://ogp.me/ns#country-name',
);
has subjects => (
    traits => ['MooseX::Semantic::Meta::Attribute::Trait'],
    is => 'rw',
    rdf_lang => 'en',
    isa => 'ArrayRef[Str]',
    uri => 'http://purl.org/dc/terms/subject',
);
has friends => (
    traits => ['Semantic', 'Array'],
    is => 'rw',
    isa => 'ArrayRef[MooseX::Semantic::Test::Person]',
    uri => 'http://xmlns.com/foaf/0.1/knows',
    default => sub { [] },
    predicate => 'has_friends',
    handles => {
        'add_friend' => 'push',
        'get_friend' => 'get',
        'find_friend' => 'first',
    },
);
has favorite_numer => (
    traits => ['Semantic'],
    is => 'rw',
    isa => 'Int',
    uri => 'http://xmlns.com/foaf/0.1/favorite_number',
);
has generic_one_to_one_relation => (
    traits => ['Semantic'],
    is => 'rw',
    isa => 'MooseX::Semantic::Test::Person',
    uri => 'http://xmlns.com/foaf/0.1/generic_one_to_one_relation',
);


1;
