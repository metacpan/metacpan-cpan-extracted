package Fruits;

use strict;
use warnings FATAL => 'all';

use Mouse;
use MouseX::Types::Enum (
    APPLE  => { name => 'Apple', color => 'red' },
    ORANGE => { name => 'Cherry', color => 'red' },
    BANANA => { name => 'Banana', color => 'yellow', has_seed => 0 }
);

has name => (is => 'ro', isa => 'Str');
has color => (is => 'ro', isa => 'Str');
has has_seed => (is => 'ro', isa => 'Int', default => 1);

sub make_sentence {
    my ($self, $suffix) = @_;
    $suffix ||= "";
    return sprintf("%s is %s%s", $self->name, $self->color, $suffix);
}

__PACKAGE__->meta->make_immutable;

1;