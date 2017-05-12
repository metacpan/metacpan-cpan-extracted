package Reaction::UI::ViewPort::Field::Mutable::Boolean;

use Reaction::Class;

use namespace::clean -except => [ qw(meta) ];
extends 'Reaction::UI::ViewPort::Field::Boolean';

with 'Reaction::UI::ViewPort::Field::Role::Mutable::Simple';
sub adopt_value_string {
  my ($self) = @_;
  $self->value($self->value_string||0);
};
sub BUILD {
  my($self) = @_;
  $self->value(0) unless $self->_model_has_value;
};

# yeah, bool fields have to always be required
# otherwise we ever cant get false
# for reference, take a peek in Field::Role::Mutable::Simple's
# is_modified logic
sub value_is_required { 1 }

__PACKAGE__->meta->make_immutable;


1;
