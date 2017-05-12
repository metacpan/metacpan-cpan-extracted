package Reaction::UI::ViewPort::ListView;

use Reaction::Class;
use namespace::clean -except => [ qw(meta) ];
extends 'Reaction::UI::ViewPort::Collection::Grid';

with 'Reaction::UI::ViewPort::Collection::Role::Order';

__PACKAGE__->meta->make_immutable;

1;
