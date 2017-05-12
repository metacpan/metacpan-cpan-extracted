package NetHack::Item::Armor::Gloves;
{
  $NetHack::Item::Armor::Gloves::VERSION = '0.21';
}
use Moose;
extends 'NetHack::Item::Armor';

use constant subtype => 'gloves';

__PACKAGE__->meta->make_immutable;
no Moose;

1;

