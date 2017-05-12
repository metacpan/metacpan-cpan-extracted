package NetHack::ItemPool::Tracker::Food;
{
  $NetHack::ItemPool::Tracker::Food::VERSION = '0.21';
}
use Moose;
extends 'NetHack::ItemPool::Tracker';

use constant type => 'food';


__PACKAGE__->meta->make_immutable;
no Moose;

1;

