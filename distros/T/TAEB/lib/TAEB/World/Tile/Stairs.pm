package TAEB::World::Tile::Stairs;
use TAEB::OO;
use TAEB::Util qw/:colors display/;
extends 'TAEB::World::Tile';

has other_side => (
    is       => 'rw',
    isa      => 'TAEB::World::Tile',
    clearer  => 'clear_other_side',
    weak_ref => 1,
);

override debug_color => sub {
    my $self = shift;

    my $different_branch = $self->known_branch
                        && $self->other_side
                        && $self->other_side->known_branch
                        && $self->branch ne $self->other_side->branch;

    return $different_branch
         ? display(COLOR_YELLOW)
         : super;
};

__PACKAGE__->meta->make_immutable;
no TAEB::OO;

1;

