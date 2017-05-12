package NetHack::ItemPool::Tracker::Potion;
{
  $NetHack::ItemPool::Tracker::Potion::VERSION = '0.21';
}
use Moose;
extends 'NetHack::ItemPool::Tracker';

use constant type => 'potion';


__PACKAGE__->meta->make_immutable;
no Moose;

1;

