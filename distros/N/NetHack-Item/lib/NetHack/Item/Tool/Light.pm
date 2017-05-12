package NetHack::Item::Tool::Light;
{
  $NetHack::Item::Tool::Light::VERSION = '0.21';
}
use Moose;
extends 'NetHack::Item::Tool';
with 'NetHack::Item::Role::Lightable';

use constant subtype => 'light';

has is_partly_used => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
);

with 'NetHack::Item::Role::IncorporatesStats' => {
    attribute => 'is_partly_used',
    stat      => 'used',
};

__PACKAGE__->meta->make_immutable;
no Moose;

1;

