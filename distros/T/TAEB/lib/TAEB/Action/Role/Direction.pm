package TAEB::Action::Role::Direction;
use Moose::Role;
use List::MoreUtils 'none';

has direction => (
    is       => 'ro',
    isa      => 'Str',
    provided => 1,
);

has target_tile => (
    is       => 'ro',
    isa      => 'TAEB::World::Tile',
    init_arg => undef,
    lazy     => 1,
    default  => sub { TAEB->current_level->at_direction(shift->direction) },
);

sub respond_what_direction { shift->direction }

around target_tile => sub {
    my $orig = shift;
    my $self = shift;

    my $tile = $self->$orig;

    if (@_ && none { $tile->type eq $_ } @_) {
        TAEB->log->action(blessed($self) . " can only handle tiles of type: @_", level => 'warning');
    }

    return $tile;
};

no Moose::Role;

1;

