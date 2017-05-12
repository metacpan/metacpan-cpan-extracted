package TestApp3;

use strict;
use warnings;
use Moose;

with 'MooseX::Object::Pluggable';

__PACKAGE__->meta->make_immutable;

1;
