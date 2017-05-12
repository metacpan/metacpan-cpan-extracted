package NetHack::Item::Role::Enchantable;
{
  $NetHack::Item::Role::Enchantable::VERSION = '0.21';
}
use Moose::Role;

has enchantment => (
    is        => 'rw',
    isa       => 'Str',
    predicate => 'enchantment_known',
);

with 'NetHack::Item::Role::IncorporatesStats' => {
    attribute    => 'enchantment',
    defined_stat => 1,
};

sub numeric_enchantment {
    my $self = shift;
    my $enchantment = $self->enchantment;

    return $enchantment unless defined $enchantment;
    return $1 if $enchantment =~ m{^\+(\d+)$};
    return $enchantment;
}

no Moose::Role;

1;

