package MooseX::DIC::FunctionalityNotImplementedException;

use Moose;
use namespace::autoclean;
extends 'MooseX::DIC::ContainerException';

__PACKAGE__->meta->make_immutable;
1;
