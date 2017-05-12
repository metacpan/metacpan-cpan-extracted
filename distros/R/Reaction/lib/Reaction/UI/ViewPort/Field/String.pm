package Reaction::UI::ViewPort::Field::String;

use Reaction::Class;
use namespace::clean -except => [ qw(meta) ];
use MooseX::Types::Moose qw/Str/;

extends 'Reaction::UI::ViewPort::Field';

has '+value' => (isa => Str);

__PACKAGE__->meta->make_immutable;

1;
