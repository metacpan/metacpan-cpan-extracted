package NetHack::ItemPool::Tracker::Armor;
{
  $NetHack::ItemPool::Tracker::Armor::VERSION = '0.21';
}
use Moose;
extends 'NetHack::ItemPool::Tracker';

use constant type => 'armor';


__PACKAGE__->meta->make_immutable;
no Moose;

1;

