package NetHack::ItemPool::Tracker::Amulet;
{
  $NetHack::ItemPool::Tracker::Amulet::VERSION = '0.21';
}
use Moose;
extends 'NetHack::ItemPool::Tracker';

use constant type => 'amulet';


__PACKAGE__->meta->make_immutable;
no Moose;

1;

