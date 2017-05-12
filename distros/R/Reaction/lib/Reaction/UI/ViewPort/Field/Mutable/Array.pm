package Reaction::UI::ViewPort::Field::Mutable::Array;

use Reaction::Class;

use namespace::clean -except => [ qw(meta) ];
extends 'Reaction::UI::ViewPort::Field::Array';

with 'Reaction::UI::ViewPort::Field::Role::Mutable';

around value => sub {
  my $orig = shift;
  my $self = shift;
  return $orig->($self) unless @_;
  my $value = defined $_[0] ? $_[0] : [];
  $orig->($self, (ref $value eq 'ARRAY' ? $value : [ $value ]));
};

# value_string doesn't make sense in an Array field
override _value_string_from_value => sub { shift->_empty_string_value };

__PACKAGE__->meta->make_immutable;

1;

