package NetHack::Item::Role::Chargeable;
{
  $NetHack::Item::Role::Chargeable::VERSION = '0.21';
}
use Moose::Role;

has recharges => (
    is        => 'rw',
    isa       => 'Int',
    predicate => 'recharges_known',
    clearer   => '_clear_recharges',
);
sub inc_recharges { $_[0]->recharges($_[0]->recharges + 1) }

has charges => (
    is        => 'rw',
    isa       => 'Int',
    predicate => 'charges_known',
    clearer   => 'set_charges_unknown',
);
sub subtract_charges { $_[0]->charges($_[0]->charges - $_[1]) }

has charges_spent_this_recharge => (
    traits    => ['Counter'],
    is        => 'rw',
    isa       => 'Int',
    default   => 0,
    handles   => {
        add_charges_spent_this_recharge   => 'inc',
        reset_charges_spent_this_recharge => 'reset',
    },
);

has times_recharged => (
    traits    => ['Counter'],
    is        => 'rw',
    isa       => 'Int',
    default   => 0,
    handles   => {
        inc_times_recharged => 'inc',
    },
);

sub spend_charge {
    my $self = shift;
    my $count = shift || 1;

    $self->add_charges_spent_this_recharge($count);

    return unless $self->charges_known;

    $self->subtract_charges($count);
    if ($self->charges < 0) {
        $self->charges(0);
    }

    return $self->charges;
}

sub recharge {
    my $self = shift;

    $self->set_charges_unknown;
    $self->inc_times_recharged;
    $self->reset_charges_spent_this_recharge;
    $self->inc_recharges if $self->recharges_known;
}

sub chance_to_recharge {
    my $self = shift;

    return undef if !$self->recharges_known;

    my $n = $self->recharges;

    # can always recharge at 0 recharges
    return 100 if $n == 0;

    # can recharge /oW only once
    return 0 if $self->has_identity
             && $self->identity eq 'wand of wishing';

    # can recharge all tools except magic marker indefinitely
    return 100 if $self->type eq 'tool'
               && $self->identity ne 'magic marker';

    # (n/7)^3
    return 100 - int(100 * (($n/7) ** 3));
}

after incorporate_stats => sub {
    my $self  = shift;
    # Counter sets the default to 0 for you, but we want it to be undef
    $self->_clear_recharges;
};

with 'NetHack::Item::Role::IncorporatesStats' => {
    attribute    => 'charges',
    defined_stat => 1,
};

with 'NetHack::Item::Role::IncorporatesStats' => {
    attribute    => 'recharges',
    defined_stat => 1,
};

around is_evolution_of => sub {
    my $orig = shift;
    my $new = shift;
    my $old = shift;

    if ($new->does(__PACKAGE__) && $old->does(__PACKAGE__)) {
        if ($old->recharges_known && $new->recharges_known) {
            # lost recharges?
            return 0 if $old->recharges > $new->recharges;

            # gained charges without a recharge?
            if ($old->charges_known && $new->charges_known) {
                return 0 if $old->recharges == $new->recharges
                        && $old->charges < $new->charges;
            }
        }
    }

    return $orig->($new, $old);
};

no Moose::Role;

1;

