package NetHack::Item::Scroll;
{
  $NetHack::Item::Scroll::VERSION = '0.21';
}
use Moose;
extends 'NetHack::Item';

use constant type => "scroll";

sub did_blank {
    my $self = shift;

    # convert to blank
    $self->_clear_tracker;
    $self->appearance("unlabeled scroll");
    $self->identity("scroll of blank paper");
}

__PACKAGE__->meta->install_spoilers('ink');

__PACKAGE__->meta->make_immutable;
no Moose;

1;

