package Parent;

use strict;
use warnings;

use Moose;
with 'MooseX::Role::UnsafeConstructable';

has parent_field => (is => 'ro', isa => 'Num');

__PACKAGE__->meta->make_immutable;


