package Reaction::UI::ViewPort::Field::Number;

use Reaction::Class;
use namespace::clean -except => [ qw(meta) ];
use MooseX::Types::Moose qw/Num/;

extends 'Reaction::UI::ViewPort::Field';

has '+value' => (isa => Num);

__PACKAGE__->meta->make_immutable;

1;
