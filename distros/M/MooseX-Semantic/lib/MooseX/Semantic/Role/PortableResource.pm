package MooseX::Semantic::Role::PortableResource;
use Moose::Role;
with qw(
    MooseX::Semantic::Role::Resource
    MooseX::Semantic::Role::RdfExport
    MooseX::Semantic::Role::RdfImport
    MooseX::Semantic::Role::WithRdfType
);

1;
