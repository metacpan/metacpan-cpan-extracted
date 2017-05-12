package Reaction::Meta::InterfaceModel::Action::ParameterAttribute;

use Reaction::Class;
use Scalar::Util 'blessed';

use namespace::clean -except => [ qw(meta) ];
extends 'Reaction::Meta::Attribute';


has valid_values => (
  isa => 'CodeRef',
  is => 'rw',
  predicate => 'has_valid_values'
);
sub new {
  my $self = shift->SUPER::new(@_); # work around immutable
  if(!$self->has_valid_values and $self->has_type_constraint) {
    my $tc = $self->type_constraint;
    if($tc->isa('Moose::Meta::TypeConstraint::Enum')) {
      $self->valid_values(sub { $tc->values });
    }
  }
  return $self;
}

sub check_valid_value {
  my ($self, $object, $value) = @_;
  confess "Can't check_valid_value when no valid_values set"
    unless $self->has_valid_values;
  confess join " - ", blessed($object), $self->name
    unless ref $self->valid_values;
  my $valid = $self->valid_values->($object, $self);
  if ($self->type_constraint
      && ($self->type_constraint->name eq 'ArrayRef'
          || $self->type_constraint->is_subtype_of('ArrayRef'))) {
    confess "Parameter type is array ref but passed value isn't"
      unless ref($value) eq 'ARRAY';
    return [ map { $self->_check_single_valid($valid => $_) } @$value ];
  } else {
    return $self->_check_single_valid($valid => $value);
  }
};
sub _check_single_valid {
  my ($self, $valid, $value) = @_;
  return undef unless defined($value);
  if (ref $valid eq 'ARRAY') {
    return $value if grep { $_ eq $value } @$valid;
  } else {
    $value = $value->ident_condition if blessed($value);
    return $valid->find($value);
  }
  return undef; # XXX this is an assumption that undef is never valid
};
sub all_valid_values {
  my ($self, $object) = @_;
  confess "Can't call all_valid_values on an attribute without valid_values"
    unless $self->has_valid_values;
  my $valid = $self->valid_values->($object, $self);
  return ((ref $valid eq 'ARRAY')
          ? @$valid
          : $valid->all);
};
sub valid_value_collection {
  my ($self, $object) = @_;
  confess "Can't call valid_value_collection on an attribute without valid_values"
    unless $self->has_valid_values;
  my $valid = $self->valid_values->($object, $self);
  confess "valid_values returned an arrayref, not a collection"
    if (ref $valid eq 'ARRAY');
  return $valid;
};

__PACKAGE__->meta->make_immutable(inline_constructor => 0);


1;

=head1 NAME

Reaction::Meta::InterfaceModel::Action::ParameterAttribute

=head1 DESCRIPTION

=head1 METHODS

=head2 new

=head2 valid_values

=head2 has_valid_values

=head2 check_valid_value

=head2 all_valid_values

=head2 valid_value_collection

=head2 reader

=head2 writer

=head1 SEE ALSO

L<Reaction::Meta::Attribute>

=head1 AUTHORS

See L<Reaction::Class> for authors.

=head1 LICENSE

See L<Reaction::Class> for the license.

=cut
