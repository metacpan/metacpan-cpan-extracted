package NetHack::Item::Tool::Trap;
{
  $NetHack::Item::Tool::Trap::VERSION = '0.21';
}
use Moose;
extends 'NetHack::Item::Tool';

use constant subtype => 'trap';

__PACKAGE__->meta->make_immutable;
no Moose;

1;

