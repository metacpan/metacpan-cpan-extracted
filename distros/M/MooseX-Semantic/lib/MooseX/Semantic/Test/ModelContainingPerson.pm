package MooseX::Semantic::Test::ModelContainingPerson;
use Moose;
# use MooseX::Semantic::

with qw(
    MooseX::Semantic::Role::RdfExport
);

has data_bucket => (
    traits => ['Semantic'],
    is => 'rw',
    isa => 'RDF::Trine::Model',
    default => sub { RDF::Trine::Model->temporary_model },
    uri => 'DUMMY'
);


1;
