package NetHack::Inventory;
{
  $NetHack::Inventory::VERSION = '0.21';
}
use Moose;
with 'NetHack::ItemPool::Role::HasPool';

use NetHack::Inventory::Equipment;

use constant equipment_class => 'NetHack::Inventory::Equipment';

has inventory => (
    traits    => ['Hash'],
    is        => 'ro',
    isa       => 'HashRef[NetHack::Item]',
    default   => sub { {} },
    handles   => {
        get       => 'get',
        set       => 'set',
        remove    => 'delete',
        items     => 'values',
        slots     => 'keys',
        has_items => 'count',
    },
);

has equipment => (
    is      => 'ro',
    isa     => 'NetHack::Inventory::Equipment',
    lazy    => 1,
    handles => qr/^(?!update|remove|(has_)?pool|slots)\w/,
    default => sub {
        my $self = shift;
        $self->equipment_class->new(
            pool => $self->pool,
        )
    },
);

has weight => (
    is      => 'ro',
    isa     => 'Int',
    lazy    => 1,
    builder => '_calculate_weight',
    clearer => 'invalidate_weight',
);

has '+pool' => (
    required => 1,
);

sub _extract_slot {
    my ($slot, $item);

    if (@_ == 2) {
        ($slot, $item) = @_;
        $item->slot($slot);
    }
    else {
        $item = shift;
        $slot = $item->slot;
        confess "No slot was passed to set, and the item ($item) didn't have a value for its slot attribute." if !defined($slot);
    }

    return $slot => $item;
}

around set => sub {
    my $orig = shift;
    my $self = shift;

    my ($slot, $item) = _extract_slot(@_);

    # gold pieces don't belong in inventory
    return if $item->has_identity
           && $item->identity eq 'gold piece';

    $self->$orig($slot => $item);
};

sub update {
    my $self = shift;
    my $args = ref($_[0]) eq 'HASH' ? shift : {};
    my ($slot, $item) = _extract_slot(@_);

    # gold pieces don't belong in inventory
    return if $item->has_identity
           && $item->identity eq 'gold piece';

    if (my $old = $self->get($slot)) {
        if ($old->evolve_from($item, $args)) {
            $self->equipment->update($old);
            $self->invalidate_weight;
        }
        else {
            warn "Displacing [" . $old->raw . "] in slot $slot with "
               . "[" . $item->raw . "].";
            $self->set($slot => $item);
        }

        return $old;
    }

    $self->set($slot => $item);
    return $item;
}

sub add { shift->update({add => 1}, @_) }

after 'set' => sub {
    my $self = shift;
    my $args = ref($_[0]) eq 'HASH' ? shift : {};
    my (undef, $item) = _extract_slot(@_);

    $self->equipment->update($item);
    $self->invalidate_weight;
};

before remove => sub {
    my $self = shift;
    my $item = $self->get(shift);

    $self->equipment->remove($item);
};

sub exact_weight {
    my $self = shift;

    my $weight = 0;
    for my $item ($self->items) {
        return undef if !defined($item->weight);
        $weight += $item->weight;
    }

    return $weight;
}

sub _calculate_weight {
    my $self = shift;

    my ($total_min, $total_max) = (0, 0);
    for my $item ($self->items) {
        my ($min, $max) = (sort $item->spoiler_values('weight'))[0, -1];
        $total_min += $min * $item->quantity;
        $total_max += $max * $item->quantity;
    }

    return int(($total_max + $total_min) / 2);
}

sub decrease_quantity {
    my $self = shift;
    my $slot = shift;
    my $by   = shift || 1;

    my $item = $self->get($slot);
    if (!$item) {
        warn "Inventory->decrease_quantity called on an empty slot '$slot'";
        return 0;
    }

    my $orig_quantity = $item->quantity;

    if ($by >= $orig_quantity) {
        $self->remove($slot);
        return 0;
    }

    $item->quantity($orig_quantity - $by);
    return $item->quantity;
}

__PACKAGE__->meta->make_immutable;
no Moose;

1;

__END__

=head1 NAME

NetHack::Inventory - the player's inventory

=head1 VERSION

version 0.21

=head1 SYNOPSIS

    use NetHack::ItemPool;
    my $pool = NetHack::ItemPool->new;

    $pool->new_item("x - 3 food rations");
    $pool->inventory->get('x'); # NetHack::Item<3 food rations>

    $pool->new_item("M - a unicorn horn");

    # updates (not replaces!) the horn already in M
    $pool->new_item("M - a blessed unicorn horn");

    # replaces the horn in M because it's a different item
    $pool->new_item("M - a scroll of taming");

=head1 DESCRIPTION

=cut
