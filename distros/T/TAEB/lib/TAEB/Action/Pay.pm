package TAEB::Action::Pay;
use TAEB::OO;
extends 'TAEB::Action';
with 'TAEB::Action::Role::Item';

has '+item' => (
    isa      => 'NetHack::Item | Str',
    required => 1,
);

sub command {
    return TAEB->is_blind ? '.' : 'p';
}

sub respond_itemized_billing { return 'y'; }

sub respond_buy_item {
    my $self = shift;
    my $item = TAEB->new_item(shift);
    my $cost = shift;

    $item->cost_each($cost / $item->quantity);

    if (blessed($self->item) && $self->item->maybe_is($item)) {
        TAEB->log->action("Buying $item explicitly.");
        return 'y';
    }

    if (!blessed($self->item) && $self->item eq 'any') {
        TAEB->log->action("Buying $item because we're buying everything.");
        return 'y';
    }

    return 'n';
}

sub done {
    # XXX: hackish
    TAEB->enqueue_message('check', 'inventory');
    TAEB->enqueue_message('check', 'debt');
}

__PACKAGE__->meta->make_immutable;
no TAEB::OO;

1;

