package TAEB::Action::Throw;
use TAEB::OO;
extends 'TAEB::Action';
with 'TAEB::Action::Role::Direction';
with 'TAEB::Action::Role::Item' => { items => [qw/projectile/] };
with 'TAEB::Action::Role::Monster';

use TAEB::Util 'vi2delta';

use constant command => 't';

has '+projectile' => (
    required => 1,
);

has '+direction' => (
    required => 1,
);

has threw_multiple => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
);

has killed => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
);

sub respond_throw_what { shift->projectile->slot }

# we don't get a message when we throw one dagger
sub done {
    my $self = shift;
    TAEB->inventory->decrease_quantity($self->projectile->slot);

    # now mark squares in the path of the projectile as interesting so we pick
    # up projectiles we've thrown
    my ($dx, $dy) = vi2delta($self->direction);
    my ($x, $y)   = (TAEB->x, TAEB->y);

    for (1 .. $self->projectile->throw_range) {
        $x += $dx;
        $y += $dy;

        my $tile = TAEB->current_level->at($x, $y)
            or last;
        $tile->is_walkable(1)
            or last;

        # these tiles would show the projectile we threw
        next if $tile->shows_items;

        $tile->set_interesting(1);

        # if we're throwing at a monster, then the projectile will always stop
        # at the monster's tile (unless we threw multiple and it killed the
        # monster - the subsequent projectiles can fly past)
        if ($tile == $self->target_tile) {
            last unless $self->threw_multiple
                     && $self->killed;
        }
    }
}

sub msg_throw_count {
    my $self  = shift;
    my $count = shift;

    $self->threw_multiple(1);

    # done takes care of the other one
    TAEB->inventory->decrease_quantity($self->projectile->slot, $count - 1);
}

sub msg_killed {
    my ($self, $monster_name) = @_;

    $self->killed(1);
    $self->target_tile->witness_kill($monster_name);
}

sub msg_throw_slip {
    my $self = shift;

    $self->projectile->is_cursed(1);
}

__PACKAGE__->meta->make_immutable;
no TAEB::OO;

1;

