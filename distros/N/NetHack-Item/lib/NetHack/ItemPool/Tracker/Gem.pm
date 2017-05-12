package NetHack::ItemPool::Tracker::Gem;
{
  $NetHack::ItemPool::Tracker::Gem::VERSION = '0.21';
}
use Moose;
extends 'NetHack::ItemPool::Tracker';

use constant type => 'gem';


__PACKAGE__->meta->make_immutable;
no Moose;

1;

