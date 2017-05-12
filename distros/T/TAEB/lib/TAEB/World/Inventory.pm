package TAEB::World::Inventory;
use TAEB::OO;
extends 'NetHack::Inventory';

use List::Util 'first';
use TAEB::Util 'assert';

use overload %TAEB::Meta::Overload::default;

use constant equipment_class => 'TAEB::World::Equipment';

has '+equipment' => (
    isa => 'TAEB::World::Equipment',
);

sub find {
    my $self = shift;

    return first { $_->match(@_) } $self->items if !wantarray;
    return grep { $_->match(@_) } $self->items;
}

around _calculate_weight => sub {
    my $orig = shift;

    my $weight = $orig->(@_);
    my $gold_weight =
        NetHack::Item::Spoiler->spoiler_for('gold piece')->{weight};
    $gold_weight = int(TAEB->gold * $gold_weight);

    return $weight + $gold_weight;
};

=head2 has_projectile

Returns true (actually, the item) if TAEB has something useful to throw.

=cut

my @projectiles = (
    qr/\bdagger\b/,
    qr/\bspear\b/,
    qr/\bshuriken\b/,
    qr/\bdart\b/,
    "rock", # to not catch rock mole corpses
);

sub has_projectile {
    my $self = shift;

    for my $projectile (@projectiles) {
        my $found = $self->find(
            identity   => $projectile,
            is_wielded => sub { !$_ },
            cost       => 0,
        );
        return $found if $found;
    }
    return;
}

sub debug_line {
    my $self = shift;
    my @items;

    return "No inventory." unless $self->has_items;

    push @items, 'Inventory (' . $self->weight . ' hzm)';
    for my $slot (sort $self->slots) {
        push @items, sprintf '%s - %s', $slot, $self->get($slot)->debug_line;
    }

    return join "\n", @items;
}

sub msg_got_item {
    my $self = shift;
    my $item = shift;

    $self->add($item->slot => $item);
}

sub msg_lost_item {
    my $self = shift;
    my $item = shift;

    # XXX
}

sub msg_corpse_rot {
    my $self    = shift;
    my $monster = shift;

    my @possibilities = $self->find(
        type    => 'food',
        subtype => 'corpse',
        monster => $monster,
    );

    if (@possibilities == 0) {
        TAEB->log->inventory("Unable to find the '$monster' corpse that rotted away");
    }
    elsif (@possibilities > 2) {
        TAEB->enqueue_message(check => 'inventory');
    }
    elsif (@possibilities == 1) {
        my $slot = $possibilities[0]->slot;

        TAEB->log->inventory("The '$monster' corpse(s) in slot $slot rotted away");
        $self->remove($slot);
    }
}

sub msg_sanity {
    my $self = shift;

    {
        use Scalar::Util 'refaddr';

        my %invent_worn;

        for my $item ($self->items) {
            push @{$invent_worn{weapon}}, $item if $item->is_wielded;
            push @{$invent_worn{offhand}}, $item if $item->is_offhand;
            push @{$invent_worn{quiver}}, $item if $item->is_quivered;

            if ($item->can("is_worn") && $item->is_worn) {
                if ($item->can("hand")) {
                    push @{$invent_worn{$item->hand . "_ring"}}, $item;
                } else {
                    push @{$invent_worn{$item->specific_slots->[0]}}, $item;
                }
            }
        }

        for my $slot ($self->equipment->slots) {

            my $inv = $invent_worn{$slot} || [];
            my $eq  = $self->$slot;

            next if (!$eq && !@$inv);

            assert($eq, "$slot is not registered in equipment");

            assert(@$inv <= 1, "$slot holds multiple items in inventory");

            assert(@$inv, "equipment has a phantom $slot");

            assert(refaddr $inv->[0] == refaddr $eq,
                "$slot has different items in equipment and inventory");
        }
    }
}

__PACKAGE__->meta->make_immutable;
no TAEB::OO;

1;

