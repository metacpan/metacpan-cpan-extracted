package Reaction::UI::ViewPort::Field::Collection;

use Reaction::Class;
use Scalar::Util 'blessed';

use namespace::clean -except => [ qw(meta) ];
extends 'Reaction::UI::ViewPort::Field::Array';

has value => (
  is => 'rw', lazy_build => 1,
  isa => 'Reaction::InterfaceModel::Collection'
);

sub _build_value_names {
  my $self = shift;
  my $meth = $self->value_map_method;
  my @names = map { blessed($_) ? $_->$meth : $_ } $self->value->members;
  return [ sort @names ];
}

__PACKAGE__->meta->make_immutable;


1;
