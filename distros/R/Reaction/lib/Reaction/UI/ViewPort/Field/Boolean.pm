package Reaction::UI::ViewPort::Field::Boolean;

use Reaction::Class;
extends 'Reaction::UI::ViewPort::Field';

use namespace::clean -except => [ qw(meta) ];
use MooseX::Types::Moose qw/Bool/;

has '+value' => (isa => Bool);

override _empty_string_value => sub { 0 };

__PACKAGE__->meta->make_immutable;

1;
