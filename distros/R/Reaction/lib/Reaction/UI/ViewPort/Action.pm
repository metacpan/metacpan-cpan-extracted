package Reaction::UI::ViewPort::Action;

use Reaction::Class;

use MooseX::Types::URI qw/Uri/;
use MooseX::Types::Moose qw/Int Str/;
use MooseX::Types::Common::String qw/NonEmptySimpleStr/;

use namespace::clean -except => [ qw(meta) ];

extends 'Reaction::UI::ViewPort::Object::Mutable';
with 'Reaction::UI::ViewPort::Action::Role::OK';

has message => (is => 'rw', isa => Str);
has '+model' => (handles => [qw/error_message has_error_message/]);

#this has to fucking go. it BLOWS.
has method => (
  is => 'rw',
  isa => NonEmptySimpleStr,
  default => sub { 'post' }
);

has action => ( is => 'rw', isa => Uri );

has changed => (
  is => 'rw',
  isa => Int,
  reader => 'is_changed',
  default => sub{0}
);

sub can_apply {
  my ($self) = @_;
  foreach my $field ( @{ $self->fields } ) {
    return 0 if $field->needs_sync;
    # if e.g. a datetime field has an invalid value that can't be re-assembled
    # into a datetime object, the action may be in a consistent state but
    # not synchronized from the fields; in this case, we must not apply
  }
  return $self->model->can_apply;
}

sub do_apply {
  shift->model->do_apply;
}

after apply_child_events => sub {
  # interrupt here because fields will have been updated
  my ($self) = @_;
  $self->sync_action_from_fields;
};

sub sync_action_from_fields {
  my ($self) = @_;
  foreach my $field (@{$self->fields}) {
    $field->sync_to_action; # get the field to populate the $action if possible
  }
  $self->model->sync_all;
  foreach my $field (@{$self->fields}) {
    $field->sync_from_action; # get errors from $action if applicable
  }
}

__PACKAGE__->meta->make_immutable;

1;

__END__;

=head1 NAME

Reaction::UI::ViewPort::Action - Provide user with a form with OK, Apply and Close.

=head1 SYNOPSIS

  $controller->push_viewport('Reaction::UI::ViewPort::Action',
    model           => $interface_model_action,
    field_order     => [qw( firstname lastname )],
    excluded_fields => [qw( password )],
  );

=head1 DESCRIPTION

This subclass of L<Reaction::UI::ViewPort::Object::Mutable> is used for 
rendering a complete form supporting Apply, Close and OK.

=head1 ATTRIBUTES

=head2 message

=head2 model

Inherited from L<Reaction::UI::ViewPort::Object::Mutable>. Must be a
L<Reaction::InterfaceModel::Action>.

Also handles C<error_message> and C<has_error_message> methods.

=head2 method

post / get

=head2 changed

Returns true if a field has been edited.

=head1 METHODS

=head2 can_apply

Returns true if no field C<needs_sync> and the L</model> C<can_apply>.

=head2 do_apply

Delegates to C<do_apply> on the L</model>, which is a 
L<Reaction::InterfaceModel::Action>.

=head2 sync_action_from_fields

Firstly calls C<sync_to_action> on every L<Reaction::UI::ViewPort::Field::Mutable>
in L<fields|Reaction::UI::ViewPort::Object/fields>. Then it calls C<sync_all> on
the L<Reaction::InterfaceModel::Action> in L</model>. Next it will call
C<sync_from_action> on every field to repopulate them from the L</model>.

=head1 SUBCLASSING

  package MyApp::UI::ViewPort::Action;
  use Reaction::Class;
  use MooseX::Types::Moose qw( Int );

  use namespace::clean -except => 'meta';

  extends 'Reaction::UI::ViewPort::Action';

  has render_timestamp => (
    is       => 'ro',
    isa      => Int,
    default  => sub { time },
    required => 1,
  );

  has '+field_order' => (default => sub {[qw( firstname lastname )]});

  1;

=head1 SEE ALSO

L<Reaction::UI::ViewPort>

L<Reaction::UI::ViewPort::Object>

L<Reaction::UI::ViewPort::Object::Mutable>

L<Reaction::InterfaceModel::Action::Role::Apply>

L<Reaction::InterfaceModel::Action::Role::Close>

L<Reaction::InterfaceModel::Action::Role::OK>

=head1 AUTHORS

See L<Reaction::Class> for authors.

=head1 LICENSE

See L<Reaction::Class> for the license.

=cut

