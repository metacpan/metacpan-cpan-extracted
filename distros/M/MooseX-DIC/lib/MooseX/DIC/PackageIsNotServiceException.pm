package MooseX::DIC::PackageIsNotServiceException;

use Moose;
use namespace::autoclean;
extends 'MooseX::DIC::ContainerException';

has package => ( is => 'ro', isa => 'Str', required => 1 );
has '+message' => (
    lazy    => 1,
    default => sub {
        "The package " . shift->package . " is not an injectable service";
    }
);

__PACKAGE__->meta->make_immutable;
1;
