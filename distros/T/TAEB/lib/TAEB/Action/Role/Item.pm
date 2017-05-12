package TAEB::Action::Role::Item;
use MooseX::Role::Parameterized;

parameter items => (
    isa        => 'ArrayRef[Str]',
    default    => sub { ['item'] },
);

role {
    my $p = shift;
    my $items = $p->items;

    has $items => (
        is       => 'ro',
        isa      => 'NetHack::Item',
        provided => 1,
    );

    has current_item => (
        is       => 'rw',
        isa      => 'NetHack::Item',
        lazy     => 1,
        default  => sub {
            my $self = shift;
            my $item_attr = $items->[0];
            return $self->$item_attr;
        },
    );

    method exception_missing_item => sub {
        my $self = shift;
        return unless blessed $self->current_item;

        TAEB->log->action("We don't have item " . $self->current_item
                        . ", escaping.", level => 'warning');
        TAEB->inventory->remove($self->current_item->slot);
        TAEB->enqueue_message(check => 'inventory');
        $self->aborted(1);
        return "\e\e\e";
    };
};

no MooseX::Role::Parameterized;

1;

