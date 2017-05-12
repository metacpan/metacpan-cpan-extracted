package ORTestObjects;

use Moo;

has name => (is => 'rwp', default => sub { 'Fred' });

sub same_name {
    my ($self, $other) =  @_;

    return $self->name eq $other->name;
}

sub give_back {
    my ($self) = @_;

    return $self;
}

sub takes_object {
    my ($self, $object) = @_;

    if($object->isa('ORTestObjects')) {
        return 1;
    }

    return 0;
}

1;
