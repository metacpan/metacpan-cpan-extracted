package NetHack::Item::Role::Wearable;
{
  $NetHack::Item::Role::Wearable::VERSION = '0.21';
}
use Moose::Role;

has is_worn => (
    traits    => ['Bool'],
    is        => 'rw',
    isa       => 'Bool',
    default   => 0,
    handles   => {
        wear   => 'set',
        remove => 'unset',
    },
);

with 'NetHack::Item::Role::IncorporatesStats' => {
    attribute => 'is_worn',
    stat      => 'worn',
    bool_stat => 1,
};

around is_worn => sub {
    my $orig = shift;
    my $self = shift;

    return $orig->($self) if !@_; # reader

    my $is_worn = shift;
    my $before = $self->is_worn;

    my $ret = $orig->($self, $is_worn, @_);

    if ($self->has_pool && $is_worn ^ $before) {
        my $slot;

        if ($self->type eq 'armor') {
            $slot = $self->subtype;
        }
        elsif ($self->type eq 'ring') {
            my $hand = $self->hand;

            die "When changing a ring's worn status, you must have the 'hand' attribute set" if !$hand;
            $slot = "${hand}_ring";
        }
        else {
            $slot = $self->type;
        }

        my $equipment = $self->pool->inventory->equipment;
        if ($is_worn) {
            my $existing = $equipment->$slot;
            $existing->is_worn(0) if $existing && $existing != $self;

            $equipment->$slot($self);
        }
        else {
            my $clearer = "clear_$slot";
            $equipment->$clearer;
        }
    }

    return $ret;
};

around can_drop => sub {
    my $orig = shift;
    my $self = shift;
    my %args = @_;

    return 0 if $self->is_worn && !$args{ignore_is_worn};
    return $orig->($self, @_);
};

no Moose::Role;

1;

