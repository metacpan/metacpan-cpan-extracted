package MooseX::DIC::Configuration::ServiceMetadata;

use MooseX::DIC::Types;

use Moose;
use namespace::autoclean;

use constant DEFAULT_ENVIRONMENT => 'default';
use constant DEFAULT_SCOPE => 'singleton';
use constant DEFAULT_BUILDER => 'Moose';

has class_name => ( is => 'ro', isa => 'Str', required => 1 );
has implements => ( is => 'ro', isa => 'Str', required => 1 );
has scope      => ( is => 'ro', isa => 'ServiceScope', default => DEFAULT_SCOPE );
has qualifiers => ( is => 'ro', isa => 'ArrayRef[Str]', default => sub { [] } );
has environment => ( is => 'ro', isa => 'Str', default => DEFAULT_ENVIRONMENT );
has builder => ( is => 'ro', isa => 'Str', default => DEFAULT_BUILDER );
has dependencies => ( is => 'ro', isa => 'HashRef[MooseX::DIC::Configuration::ServiceMetadata::Dependency]', default => sub {{}} );

__PACKAGE__->meta->make_immutable;

1;
