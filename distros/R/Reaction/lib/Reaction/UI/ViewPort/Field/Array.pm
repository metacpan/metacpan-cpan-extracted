package Reaction::UI::ViewPort::Field::Array;

use Reaction::Class;
use Scalar::Util 'blessed';

extends 'Reaction::UI::ViewPort::Field';

use namespace::clean -except => [ qw(meta) ];

use MooseX::Types::Moose qw/Str ArrayRef/;;

has '+value' => (isa => ArrayRef);

has value_names => (isa => ArrayRef, is => 'ro', lazy_build => 1);
has value_map_method => (
  isa => Str, is => 'ro', required => 1, default => sub { 'display_name' },
);

sub _build_value_names {
  my $self = shift;
  my $meth = $self->value_map_method;
  my @names = map { blessed($_) ? $_->$meth : $_ } @{ $self->value };
  return [ sort @names ];
}

sub _empty_value { [] }

__PACKAGE__->meta->make_immutable;


1;
