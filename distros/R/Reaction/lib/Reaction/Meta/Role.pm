package Reaction::Meta::Role;

use Moose;
use Reaction::Meta::Attribute;

extends 'Moose::Meta::Role';

with 'Reaction::Role::Meta::Role';

no Moose;

__PACKAGE__->meta->make_immutable;

1;
