package NetHack::Item::Armor::Shirt;
{
  $NetHack::Item::Armor::Shirt::VERSION = '0.21';
}
use Moose;
extends 'NetHack::Item::Armor';

use constant subtype => 'shirt';

__PACKAGE__->meta->make_immutable;
no Moose;

1;

