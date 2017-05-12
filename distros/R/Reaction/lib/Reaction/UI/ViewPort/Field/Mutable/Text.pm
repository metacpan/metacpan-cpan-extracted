package Reaction::UI::ViewPort::Field::Mutable::Text;

use Reaction::Class;

use namespace::clean -except => [ qw(meta) ];
extends 'Reaction::UI::ViewPort::Field::Text';

with 'Reaction::UI::ViewPort::Field::Role::Mutable::Simple';
sub adopt_value_string {
  my ($self) = @_;
  $self->value($self->value_string);
};

__PACKAGE__->meta->make_immutable;


1;
