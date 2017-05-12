package Reaction::UI::ViewPort::Field;

use Reaction::Class;
use aliased 'Reaction::InterfaceModel::Object';
use aliased 'Reaction::Meta::InterfaceModel::Object::ParameterAttribute';

use MooseX::Types::Moose qw/Str/;

use namespace::clean -except => [ qw(meta) ];
extends 'Reaction::UI::ViewPort';

has value        => (is => 'rw', lazy_build => 1);
has name         => (is => 'rw', isa => Str, lazy_build => 1);
has label        => (is => 'rw', isa => Str, lazy_build => 1);
has value_string => (is => 'rw', isa => Str, lazy_build => 1);

has model     => (is => 'ro', isa => Object,             required => 1);
has attribute => (is => 'ro', isa => ParameterAttribute, required => 1);

sub _build_name { shift->attribute->name };

sub _build_label {
  join(' ', map { ucfirst } split('_', shift->name));
}

sub _build_value {
  my ($self) = @_;
  my $reader = $self->attribute->get_read_method;
  return $self->model->$reader;
}

sub _model_has_value {
  my ($self) = @_;
  my $predicate = $self->attribute->get_predicate_method;

  if (!$predicate || $self->model->$predicate
      # || ($self->attribute->is_lazy
      #    && !$self->attribute->is_lazy_fail)
    ) {
    # edenc -- uncommented the lazy checks above
    # model->$predicate returns false if the value isn't set
    # but has a lazy builder

    # either model attribute has a value now or can build it
    return 1;
  }
  return 0;
}

sub _build_value_string {
  my ($self) = @_;
  # XXX need the defined test because the IM lazy builds from
  # the model and DBIC can have nullable fields and DBIC doesn't
  # have a way to tell us that doesn't force value inflation (extra
  # SELECTs for belongs_to) so basically we're screwed.
  return ($self->_model_has_value && defined($self->_build_value)
            ? $self->_value_string_from_value
            : $self->_empty_string_value);
}

sub _value_string_from_value {
  shift->value;
}

sub _empty_string_value { '' }

sub value_is_required {
  my $self = shift;
  $self->model->attribute_is_required($self->attribute);
}

__PACKAGE__->meta->make_immutable;


1;
__END__;

=head1 NAME

Reaction::UI::ViewPort::Field

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head2 model

=head2 attribute

=head2 value

=head2 name

=head2 label

=head2 value_string

=head1 AUTHORS

See L<Reaction::Class> for authors.

=head1 LICENSE

See L<Reaction::Class> for the license.

=cut
