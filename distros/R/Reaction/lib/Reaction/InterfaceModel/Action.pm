package Reaction::InterfaceModel::Action;

use Reaction::Meta::InterfaceModel::Action::Class;
use metaclass 'Reaction::Meta::InterfaceModel::Action::Class';

use Reaction::Meta::Attribute;
use Reaction::Class;

use namespace::clean -except => [ qw(meta) ];

sub _debug { $ENV{REACTION_IM_ACTION_DEBUG} }

has error_message => (
  is => 'rw',
  isa => 'Str',
  metaclass => 'Reaction::Meta::Attribute'
);
has target_model => (
  is => 'ro',
  required => 1,
  metaclass => 'Reaction::Meta::Attribute'
);

has ctx => (
  isa => 'Catalyst',
  is => 'ro',
  lazy_fail => 1,
  metaclass => 'Reaction::Meta::Attribute',
  weak_ref => 1,
);

sub parameter_attributes {
  shift->meta->parameter_attributes;
}

sub parameter_hashref {
  my ($self) = @_;
  my %params;
  foreach my $attr ($self->parameter_attributes) {
    my $reader = $attr->get_read_method;
    my $predicate = $attr->get_predicate_method;
    warn "${\$attr->name} has default: ${\$attr->has_default}" if _debug();
    next if defined($predicate) && !$self->$predicate
         && ($attr->is_lazy_fail || !$attr->has_default);
    $params{$attr->name} = $self->$reader;
  }
  return \%params;
}

sub can_apply {
  my ($self) = @_;
  foreach my $attr ($self->parameter_attributes) {
    my $predicate = $attr->get_predicate_method;
    if ($self->attribute_is_required($attr)) {
      confess "No predicate for required attribute ${\$attr->name} for ${self}"
        unless $predicate;
      if( !$self->$predicate && ($attr->is_lazy_fail || !$attr->has_default) ) {
        warn "${\$attr->name} is required but hasn't been set" if _debug();
        return 0;
      }
    }
    if ($attr->has_valid_values) {
      unless ($predicate && !($self->$predicate)) {
        my $reader = $attr->get_read_method;
        unless( $attr->check_valid_value($self, $self->$reader) ) {
          warn "\${\$self->$reader} isn't a valid value for ${\$attr->name}" if _debug();
          return 0;
        }
      }
    }
  }
  return 1;
};
sub error_for {
  my ($self, $attr) = @_;
  confess "No attribute passed to error_for" unless defined($attr);
  unless (ref($attr)) {
    my $meta = $self->meta->find_attribute_by_name($attr);
    confess "Can't find attribute ${attr} on $self" unless $meta;
    $attr = $meta;
  }
  return $self->error_for_attribute($attr);
};
sub error_for_attribute {
  my ($self, $attr) = @_;
  my $reader = $attr->get_read_method;
  my $predicate = $attr->get_predicate_method;
  if ($self->attribute_is_required($attr)) {
    unless ($self->$predicate) {
      return $attr->name." is required";
    }
  }
  if ($self->$predicate && $attr->has_valid_values) {
    unless ($attr->check_valid_value($self, $self->$reader)) {
      return "Not a valid value for ".$attr->name;
    }
  }
  return; # ok
};
sub attribute_is_required {
  my ($self, $attr) = @_;
  return $attr->is_required;
};

sub sync_all { }

__PACKAGE__->meta->make_immutable;


1;

=head1 NAME

Reaction::InterfaceModel::Action

=head1 SYNOPSIS

=head1 DESCRIPTION

=head2 target_model

=head2 ctx

=head2 parameter_attributes

=head1 SEE ALSO

L<Reaction::Meta::Attribute>

=head1 AUTHORS

See L<Reaction::Class> for authors.

=head1 LICENSE

See L<Reaction::Class> for the license.

=cut
