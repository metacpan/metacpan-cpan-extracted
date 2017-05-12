package NetHack::Item::Amulet;
{
  $NetHack::Item::Amulet::VERSION = '0.21';
}
use Moose;
extends 'NetHack::Item';
with 'NetHack::Item::Role::Wearable';

use constant type => 'amulet';
use constant specific_slots => ['amulet'];

__PACKAGE__->meta->make_immutable;
no Moose;

1;

