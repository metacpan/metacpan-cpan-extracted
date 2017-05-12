package NetHack::ItemPool::Tracker::Other;
{
  $NetHack::ItemPool::Tracker::Other::VERSION = '0.21';
}
use Moose;
extends 'NetHack::ItemPool::Tracker';

use constant type => 'other';


__PACKAGE__->meta->make_immutable;
no Moose;

1;

