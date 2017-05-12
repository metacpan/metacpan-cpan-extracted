package TAEB::World::Equipment;
use TAEB::OO;
extends 'NetHack::Inventory::Equipment';

use overload %TAEB::Meta::Overload::default;

sub debug_line {
    my $self = shift;
    my @eq;

    for my $slot ($self->slots) {
        my $item = $self->$slot;
        push @eq, $slot . ': ' . $item->debug_line
            if $item;
    }

    return join "\n", @eq;
}

sub msg_slot_empty {
    my ($self, $slot) = @_;

    my $clear = "clear_$slot";

    $self->$clear;
}

__PACKAGE__->meta->make_immutable;
no TAEB::OO;

1;

