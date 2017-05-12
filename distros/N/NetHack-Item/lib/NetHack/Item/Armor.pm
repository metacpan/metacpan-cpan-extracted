package NetHack::Item::Armor;
{
  $NetHack::Item::Armor::VERSION = '0.21';
}
use Moose;
extends 'NetHack::Item';
with 'NetHack::Item::Role::Wearable';
with 'NetHack::Item::Role::Enchantable';
with 'NetHack::Item::Role::Damageable';

use constant subtypes => qw(helmet shirt bodyarmor cloak gloves shield boots);
use constant type => "armor";

sub base_ac { shift->collapse_spoiler_value('ac') }

sub specific_slots { [shift->subtype] }

sub ac {
    my $self = shift;
    my $base = $self->base_ac;
    return $base unless defined($base) && $self->enchantment_known;

    my $enchantment = $self->enchantment;
    return $base + $enchantment;
}

my %metals = map {$_ => 1} qw/metal iron mithril copper silver gold platinum/;

sub is_metallic {
    my $matl = shift->material;

    defined $matl ? ($metals{$matl} ? 1 : 0) : undef;
}

__PACKAGE__->meta->install_spoilers('mc');

__PACKAGE__->meta->make_immutable;
no Moose;

1;

