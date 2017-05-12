package NetHack::Inventory::Equipment;
{
  $NetHack::Inventory::Equipment::VERSION = '0.21';
}
use Moose;
with 'NetHack::ItemPool::Role::HasPool';

sub weapon_slots { qw/weapon offhand quiver/ }
sub armor_slots  { qw/helmet gloves boots bodyarmor cloak shirt shield/ }
sub accessory_slots { qw/left_ring right_ring amulet blindfold/ }

sub slots {
    my $self = shift;
    return ($self->weapon_slots, $self->armor_slots, $self->accessory_slots)
}

for my $slot (__PACKAGE__->slots) {
    has $slot => (
        is        => 'rw',
        isa       => 'NetHack::Item',
        clearer   => "clear_$slot",
        predicate => "has_$slot",
    );
}

has '+pool' => (
    required => 1,
);

my %weapon_slots = (
    weapon  => 'is_wielded',
    offhand => 'is_offhand',
    quiver  => 'is_quivered',
);

sub update {
    my $self = shift;
    my $item = shift;

    $self->_update_weapon($item);
    $self->_update_ring($item);
    $self->_update_armor($item);
}

sub _update_ring {
    my $self = shift;
    my $item = shift;

    if ($item->type eq 'ring' && (my $hand = $item->hand)) {
        my $slot = "${hand}_ring";

        if ($item != ($self->$slot || 0)) {
            my $clearer = "clear_$slot";
            $self->$clearer;
            $self->$slot($item);
        }
    }
}

sub _update_nonring_accessory {
    my $self = shift;
    my $item = shift;

    my $slot;

    if ($item->isa('NetHack::Item::Amulet')) {
        $slot = 'amulet';
    } elsif ($item->isa('NetHack::Item::Tool::Accessory')) {
        $slot = 'blindfold';
    } else {
        return;
    }

    if ($item->is_worn) {
        if ($item != ($self->$slot || 0)) {
            my $clearer = "clear_$slot";
            $self->$clearer;
            $self->$slot($item);
        }
    }
}

sub _update_weapon {
    my $self = shift;
    my $item = shift;

    for my $slot (keys %weapon_slots) {
        my $check = $weapon_slots{$slot};
        next unless $item->$check;
        next if $self->$slot && $self->$slot == $item;

        my $clearer = "clear_$slot";
        $self->$clearer;
        $self->$slot($item);
    }
}

sub _update_armor {
    my $self = shift;
    my $item = shift;

    return unless $item->type eq 'armor';

    my $slot = $item->subtype;

    if ($item->is_worn) {
        if ($item != ($self->$slot || 0)) {
            my $clearer = "clear_$slot";
            $self->$clearer;
            $self->$slot($item);
        }
    }
    else {
        if ($item == ($self->$slot || 0)) {
            my $clearer = "clear_$slot";
            $self->$clearer;
        }
    }
}

sub remove {
    my $self = shift;
    my $item = shift;

    for my $slot (__PACKAGE__->slots) {
        my $incumbent = $self->$slot;

        next unless $incumbent
                 && $incumbent->slot eq $item->slot;

        my $clearer = "clear_$slot";
        $self->$clearer;
    }
}

for my $slot (keys %weapon_slots) {
    my $accessor = $weapon_slots{$slot};

    before "clear_$slot" => sub {
        my $self = shift;
        my $item = $self->$slot or return;
        $item->$accessor(0) if $item->$accessor;
    };
};

for my $slot (__PACKAGE__->armor_slots, "amulet", "blindfold") {
    before "clear_$slot" => sub {
        my $self = shift;
        my $item = $self->$slot or return;

        $item->is_worn(0) if $item->is_worn;
    };
}

for my $hand (qw/left_ring right_ring/) {
    before "clear_$hand" => sub {
        my $self = shift;
        my $item = $self->$hand or return;
        $item->hand(undef) if $item->hand;
    };
}

# everything except weapons hard depends on itself because
# there is no quick swap for armour
my %dependencies = (
    shirt => {
        hard => [qw/cloak bodyarmor shirt/],
        two_hand => 'soft',
    },
    bodyarmor => {
        hard => [qw/cloak bodyarmor/],
        two_hand => 'soft',
    },
    cloak => {
        hard => [qw/cloak/],
    },
    left_ring => {
        hard => [qw/left_ring/],
        soft => [qw/gloves/],
        two_hand => 'soft',
    },
    right_ring => {
        hard => [qw/right_ring/],
        soft => [qw/gloves weapon/],
    },
    gloves => {
        hard => [qw/gloves/],
        soft => [qw/weapon/],
    },
    helmet => {
        hard => [qw/helmet/],
    },
    boots => {
        hard => [qw/boots/],
    },
    shield => {
        hard => [qw/shield/],
        two_hand => 'hard',
    },
    amulet => {
        hard => [qw/amulet/],
    },
    blindfold => {
        hard => [qw/blindfold/],
    },
    weapon => {
        soft => [qw/weapon/],
    },
    offhand => {
        soft => [qw/weapon/],
    },
    quiver => {
    },
);

sub _covering_slots {
    my ($self, $slot, $hardonly) = @_;
    my $dependencies = $dependencies{$slot};
    my @hard_deps = @{ $dependencies->{hard} || [] };
    my @soft_deps = @{ $dependencies->{soft} || [] };

    my @covering;
    push @covering, 'weapon'
        if $dependencies->{two_hand}
        && ($dependencies->{two_hand} eq 'hard' || !$hardonly)
        && $self->weapon && $self->weapon->hands == 2;

    push @covering, @hard_deps;
    push @covering, @soft_deps unless $hardonly;

    return grep { $self->$_ } @covering;
}


sub under_cursed {
    my ($self, $slot) = @_;

    for my $cslot ($self->_covering_slots($slot, 0)) {
        return 1 if $self->$cslot->is_cursed;
    }

    return 0;
}

sub blockers {
    my ($self, $slot) = @_;

    my @r;

    for my $cslot ($self->_covering_slots($slot, 1)) {
        push @r, $cslot, $self->$cslot;
    }

    return @r if wantarray;
    return $r[1];
}

sub slots_inside_out {
    qw/shirt bodyarmor boots helmet cloak right_ring left_ring gloves shield
       amulet blindfold offhand weapon quiver/;
}

__PACKAGE__->meta->make_immutable;
no Moose;

1;

__END__

=head1 NAME

NetHack::Inventory::Equipment - the player's equipment

=head1 VERSION

version 0.21

=head1 SYNOPSIS

    use NetHack::ItemPool;
    my $pool = NetHack::ItemPool->new;
    my $excalibur = $pool->new_item("the +3 Excalibur (weapon in hand)");
    is($pool->inventory->weapon, $excalibur);

    my $grayswandir = $pool->new_item("the +7 Grayswandir (weapon in hand)");
    is($pool->inventory->weapon, $grayswandir);

=head1 DESCRIPTION

=head2 under_cursed SLOT

Returns true if the slot is inaccessible because it is covered by at
least one cursed item.

=head2 blockers SLOT

Returns a list of (slot,item) pairs for items that cover the slot and
have to be removed to access it, outermost first; or the item for the
outermost blocker in scalar context.

=head2 slots_inside_out

Returns a list of all slots, ordered such that changing a slot need not
affect any slot earlier in the list.  Right ring comes before left ring.

=cut
