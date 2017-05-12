package Reaction::UI::ViewPort::Field::DateTime;

use Scalar::Util 'blessed';
use Reaction::Class;
use Reaction::Types::DateTime ();

use namespace::clean -except => [ qw(meta) ];
extends 'Reaction::UI::ViewPort::Field';

use MooseX::Types::Moose qw/Str/;

has '+value' => (isa => Reaction::Types::DateTime::DateTime());

has value_string_default_format => (
  isa => Str, is => 'rw', required => 1, default => sub { "%F %H:%M:%S" }
);

around _value_string_from_value => sub {
  my $orig = shift;
  my $self = shift;
  my $format = $self->value_string_default_format;
  return $self->$orig(@_)->strftime($format);
};

__PACKAGE__->meta->make_immutable;


1;
