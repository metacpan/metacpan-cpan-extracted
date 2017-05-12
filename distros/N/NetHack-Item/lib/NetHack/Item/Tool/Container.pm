package NetHack::Item::Tool::Container;
{
  $NetHack::Item::Tool::Container::VERSION = '0.21';
}
use Moose;
extends 'NetHack::Item::Tool';

use constant subtype => 'container';

has contents => (
    traits    => ['Array'],
    is        => 'rw',
    isa       => 'ArrayRef[NetHack::Item]',
    default   => sub { [] },
    handles   => {
        add_item => 'push',
        items    => 'elements',
    },
);

has contents_known => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
);

around add_item => sub {
    my $orig = shift;
    my $self = shift;
    my $item = shift;

    return if $item->is_in_container && $item->container == $self;

    $self->$orig($item);

    $item->container($self);
};

sub remove_item {
    my $self = shift;
    my $item = shift;

    my $contents = $self->contents;

    for (my $i = 0; $i < @$contents; ) {
        if ($contents->[$i] == $item) {
            splice @$contents, $i, 1;
            $item->clear_container;
            last;
        }
        else {
            ++$i;
        }
    }

    return $item;
}

sub remove_quantity {
    my $self          = shift;
    my $item          = shift;
    my $quantity      = shift;
    my $item_quantity = $item->quantity;

    return $self->remove_item($item)
        if $item_quantity == $quantity;

    my $new_item = $item->fork_quantity($quantity);
    $new_item->clear_container;
    return $new_item;
}

around weight => sub {
    my $orig = shift;
    my $self = shift;

    return undef unless $self->contents_known;

    my $container_weight = $self->$orig;
    my $contents_weight = 0;

    my $modifier = sub { $_[0] };
    if ($self->identity eq 'bag of holding') {
        use integer;
        $modifier = sub { $_[0] * 2 }       if $self->is_cursed;
        $modifier = sub { 1 + ($_[0] / 2) } if $self->is_uncursed;
        $modifier = sub { 1 + ($_[0] / 4) } if $self->is_blessed;
    }

    for my $item ($self->items) {
        my $item_weight = $item->weight;
        return undef if !defined($item_weight);

        $contents_weight += $modifier->($item_weight);
    }

    if ($contents_weight && $self->identity eq 'bag of holding') {
        return undef if !defined($self->buc);
    }

    return $container_weight + $contents_weight;
};

__PACKAGE__->meta->make_immutable;
no Moose;

1;

