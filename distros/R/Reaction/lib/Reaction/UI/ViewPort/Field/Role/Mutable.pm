package Reaction::UI::ViewPort::Field::Role::Mutable;

use Reaction::Role::Parameterized;

use aliased 'Reaction::InterfaceModel::Action';
use aliased 'Reaction::Meta::InterfaceModel::Action::ParameterAttribute';
use MooseX::Types::Moose qw/Int Str/;
use namespace::clean -except => [ qw(meta) ];

=pod

15:24  mst:» I'm not sure I understand why the +foo is overwriting my after'ed clear_value
15:24  mst:» but I would argue it shouldn't do that
15:25 @doy:» because has '+foo' is creating an entirely new attribute
15:25 @doy:» and just copying the meta-attribute's attributes into it
15:25 @doy:» so it's creating a new clearer sub in the subclass
15:27  rafl:» mst: for that case, i tend to just parameterize the role on whatever i might want to override in its attribute definitions

=cut

parameter value_type => (
    predicate => 'has_value_type'
);

role {

my $p = shift;

has model     => (is => 'ro', isa => Action, required => 1);
has attribute => (is => 'ro', isa => ParameterAttribute, required => 1);

has value      => (
  is => 'rw', lazy_build => 1, trigger => sub { shift->adopt_value },
  $p->has_value_type? (isa => $p->value_type) : ()
);

has needs_sync => (is => 'rw', isa => Int, default => 0); #should be bool?

has message => (is => 'rw', isa => Str, clearer => 'clear_message');

has is_modified => ( #sould be bool?
  is => 'ro', writer => '_set_modified',
  required => 1, default => 1, init_arg => undef
);

after clear_value => sub {
  my $self = shift;
  $self->clear_message if $self->has_message;
  $self->needs_sync(1);
};

sub adopt_value {
  my ($self) = @_;
  $self->clear_message if $self->has_message;
  $self->needs_sync(1); # if $self->has_attribute;
}


sub can_sync_to_action {
  my $self = shift;

  # if field is already sync'ed, it can be sync'ed again
  # this will make sync_to_action no-op if needs_sync is 0
  return 1 unless $self->needs_sync;
  my $attr = $self->attribute;

  if ($self->has_value) {
    my $value = $self->value;
    if (my $tc = $attr->type_constraint) {
      $value = $tc->coercion->coerce($value) if ($tc->has_coercion);
      if (defined (my $error = $tc->validate($value))) {
        $self->message($error);
        return;
      }
    }
  } else {
    if( $self->model->attribute_is_required($attr) ){
      if(my $error = $self->model->error_for($self->attribute) ){
        $self->message( $error );
      }
      return;
    }
  }
  return 1;
};


sub sync_to_action {
  my ($self) = @_;

  # don't sync if we're already synced
  return unless $self->needs_sync;

  # if we got here, needs_sync is 1
  # can_sync_to_action will do coercion checks, etc.
  return unless $self->can_sync_to_action;

  my $attr = $self->attribute;

  if ($self->has_value) {
    my $value = $self->value;
    if (my $tc = $attr->type_constraint) {
      #this will go away when we have moose dbic. until then though...
      $value = $tc->coercion->coerce($value) if ($tc->has_coercion);
    }
    my $writer = $attr->get_write_method;
    confess "No writer for attribute" unless defined($writer);
    $self->model->$writer($value);
  } else {
    my $predicate = $attr->get_predicate_method;
    confess "No predicate for attribute" unless defined($predicate);
    if ($self->model->$predicate) {
      my $clearer = $attr->get_clearer_method;
      confess "${predicate} returned true but no clearer for attribute"
        unless defined($clearer);
      $self->model->$clearer;
    }
  }
  $self->needs_sync(0);
};
sub sync_from_action {
  my ($self) = @_;
  return if $self->needs_sync;
  if( !$self->has_message ){
    if(my $error = $self->model->error_for($self->attribute) ){
      $self->message( $error );
    }
  }
};

around accept_events => sub { ('value', shift->(@_)) };

};


1;

=head1 NAME

Reaction::UI::ViewPort::Role::Actions

=head1 DESCRIPTION

A role to ease attaching actions to L<Reaction::InterfaceModel::Object>s

=head1 ATTRIBUTES

=head2 needs_sync

=head2 message

=head2 model

=head2 attribute

=head2 value

=head1 METHODS

=head2 accept_events

=head2 sync_from_action

=head2 sync_to_action

=head2 adopt_value

=head1 AUTHORS

See L<Reaction::Class> for authors.

=head1 LICENSE

See L<Reaction::Class> for the license.

=cut
