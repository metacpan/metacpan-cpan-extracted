package Reaction::UI::ViewPort::Field::Integer;

use Reaction::Class;
use namespace::clean -except => [ qw(meta) ];
use MooseX::Types::Moose qw/Int/;

extends 'Reaction::UI::ViewPort::Field';

has '+value' => (isa => Int);

__PACKAGE__->meta->make_immutable;

1;
