package Reaction::UI::ViewPort::Field::Container;

use Reaction::Class;

use namespace::clean -except => [ qw(meta) ];
extends 'Reaction::UI::ViewPort';

use MooseX::Types::Moose qw/Str ArrayRef/;

has label => (is => 'ro', isa => Str);
has name  => (is => 'ro', isa => Str, required => 1);
has fields => (is => 'ro', isa => ArrayRef, required => 1);

__PACKAGE__->meta->make_immutable;

1;

__END__;
