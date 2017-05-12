package NetHack::Item::Weapon;
{
  $NetHack::Item::Weapon::VERSION = '0.21';
}
use Moose;
extends 'NetHack::Item';
with 'NetHack::Item::Role::Damageable';
with 'NetHack::Item::Role::EnchantBUC';

use constant type => "weapon";

has is_poisoned => (
    traits => [qw/IncorporatesUndef/],
    is     => 'rw',
    isa    => 'Bool',
);

with 'NetHack::Item::Role::IncorporatesStats' => {
    attribute => 'is_poisoned',
    stat      => 'poisoned',
};

around can_drop => sub {
    my $orig = shift;
    my $self = shift;

    return 0 if $self->is_wielded && $self->is_cursed;
    $self->$orig(@_);
};

__PACKAGE__->meta->make_immutable;
no Moose;

1;

