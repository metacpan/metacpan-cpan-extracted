package Reaction::UI::ViewPort::Field::RelatedObject;

use Reaction::Class;
use Scalar::Util 'blessed';
use MooseX::Types::Moose qw/Str/;

use namespace::clean -except => [ qw(meta) ];
extends 'Reaction::UI::ViewPort::Field';

has value_map_method => (
  isa => Str, is => 'ro', required => 1, default => sub { 'display_name' },
);

around _value_string_from_value => sub {
  my $orig = shift;
  my $self = shift;
  my $meth = $self->value_map_method;
  return $self->$orig(@_)->$meth;
};

__PACKAGE__->meta->make_immutable;


1;
