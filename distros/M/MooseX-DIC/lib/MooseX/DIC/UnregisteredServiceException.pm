package MooseX::DIC::UnregisteredServiceException;

use Moose;
use namespace::autoclean;
extends 'MooseX::DIC::ContainerException';

has service => ( is => 'ro', isa => 'Str', required => 1 );
has '+message' => (
    lazy    => 1,
    default => sub {
        "The service "
            . shift->service
            . " has been invoked but it hasn't been registered";
    }
);

__PACKAGE__->meta->make_immutable;
1;
