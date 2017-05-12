package NetHack::Item::Armor::Boots;
{
  $NetHack::Item::Armor::Boots::VERSION = '0.21';
}
use Moose;
extends 'NetHack::Item::Armor';

use constant subtype => 'boots';

__PACKAGE__->meta->make_immutable;
no Moose;

1;

