package Parent::Child;

use strict;
use warnings;

use Moose;
extends 'Parent';

has child_field => (is => 'ro', isa => 'Num');

__PACKAGE__->meta->make_immutable;
