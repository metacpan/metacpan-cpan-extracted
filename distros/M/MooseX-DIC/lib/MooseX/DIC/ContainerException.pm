package MooseX::DIC::ContainerException;

use Moose;
use namespace::autoclean;
with 'Throwable';

has message => ( is => 'ro', isa => 'Str', required => 1 );

__PACKAGE__->meta->make_immutable;
1;
