package NetHack::Item::Role::EnchantBUC;
{
  $NetHack::Item::Role::EnchantBUC::VERSION = '0.21';
}
use Moose::Role;

with 'NetHack::Item::Role::Enchantable';

# if we know the enchantment and BUC isn't set, then set it to uncursed
after enchantment => sub {
    my $self = shift;
    return if !@_;

    $self->is_uncursed(1) if !$self->buc;
};

no Moose::Role;

1;

