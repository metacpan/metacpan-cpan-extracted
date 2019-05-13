package Fruits;

use strict;
use warnings;

use Mouse;
extends 'MouseX::Types::Enum';

has name => (is => 'ro', isa => 'Str');
has color => (is => 'ro', isa => 'Str');
has price => (is => 'ro', isa => 'Num');
has has_seed => (is => 'ro', isa => 'Int', default => 1);

sub make_sentence {
    my ($self, $suffix) = @_;
    $suffix ||= "";
    return sprintf("%s is %s%s", $self->name, $self->color, $suffix);
}

sub APPLE {1 => (
    name  => 'Apple',
    color => 'red',
    price => 1.2,
)}
sub GRAPE {2 => (
    name  => 'Grape',
    color => 'purple',
    price => 3.5,
)}
sub BANANA {3 => (
    name     => 'Banana',
    color    => 'yellow',
    has_seed => 0,
    price    => 1.5,
)}

__PACKAGE__->_build_enum;

1;