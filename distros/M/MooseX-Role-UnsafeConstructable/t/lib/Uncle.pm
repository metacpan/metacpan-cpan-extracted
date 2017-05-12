package Uncle;

use strict;
use warnings;

use Moose;

has parent_field => (is => 'ro', isa => 'Num');

__PACKAGE__->meta->make_immutable;
