package MooseX::DIC::ServiceMetadata;

use MooseX::DIC::Types;

use Moose;
use namespace::autoclean;

use constant DEFAULT_ENVIRONMENT => 'default';

has class_name => ( is => 'ro', isa => 'ClassName', required => 1 );
has implements =>
    ( is => 'ro', isa => 'RoleName', predicate => 'has_implements' );
has scope      => ( is => 'ro', isa => 'ServiceScope',  required => 1 );
has qualifiers => ( is => 'ro', isa => 'ArrayRef[Str]', required => 0 );
has environment =>
    ( is => 'ro', isa => 'Str', default => DEFAULT_ENVIRONMENT );
has builder => ( is => 'ro', isa => 'Str', required => 1 );

__PACKAGE__->meta->make_immutable;

1;
