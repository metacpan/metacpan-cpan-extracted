package MooseX::Semantic::Util::SchemaImport::Attribute;
use Moose;

with(
    'MooseX::Semantic::Role::Resource',
    'MooseX::Semantic::Role::RdfImport',
);

my $MOOSE = 'http://moose.perl.org/onto#';
my $moose = RDF::Trine::Namespace->new($MOOSE);

has 'type' => (
    traits => ['Semantic'],
    is => 'rw',
    isa => 'Str',
    uri => $moose->type,
);

has name => (
    traits => ['Semantic'],
    is => 'rw',
    isa => 'Str',
    uri => $moose->attr_name,
);

1;
