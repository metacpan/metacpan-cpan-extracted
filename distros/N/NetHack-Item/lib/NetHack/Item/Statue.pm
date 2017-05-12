package NetHack::Item::Statue;
{
  $NetHack::Item::Statue::VERSION = '0.21';
}
use Moose;
extends 'NetHack::Item';

use constant type => "statue";

__PACKAGE__->meta->install_spoilers(qw/monster/);

__PACKAGE__->meta->make_immutable;
no Moose;

1;


