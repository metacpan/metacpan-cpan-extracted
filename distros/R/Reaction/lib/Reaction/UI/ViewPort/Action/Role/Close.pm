package Reaction::UI::ViewPort::Action::Role::Close;

use Reaction::Role;
use MooseX::Types::Moose qw/Str CodeRef/;
with 'Reaction::UI::ViewPort::Action::Role::Apply';

has close_label => (is => 'rw', isa => Str, lazy_build => 1);
has on_close_callback => (is => 'rw', isa => CodeRef);
has close_label_close => (is => 'rw', isa => Str, lazy_build => 1);
has close_label_cancel => (is => 'rw', isa => Str, lazy_build => 1);

sub _build_close_label { shift->_build_close_label_close }
sub _build_close_label_close { 'close' }
sub _build_close_label_cancel { 'cancel' }

sub can_close { 1 }

sub close {
  my $self = shift;
  return unless $self->has_on_close_callback;
  $self->on_close_callback->($self);
}

around apply => sub {
  my $orig = shift;
  my $self = shift;
  my $success = $self->$orig(@_);
  $self->close_label( $self->close_label_cancel ) unless $success;
  return $success;
};

# can't do a close-type operation if there's nowhere to go afterwards
around accept_events => sub {
  my $orig = shift;
  my $self = shift;
  ( ($self->has_on_close_callback ? ('close') : ()), $self->$orig(@_) );
};

1;

__END__

=head1 NAME

Reaction::UI::ViewPort::Action::Role::Close - Integrate Close and Apply events into ViewPort

=head1 SYNOPSIS

  package MyApp::UI::ViewPort::SomeAction;
  use Reaction::Class;

  use namespace::clean -except => 'meta';

  extends 'Reaction::UI::ViewPort::Object::Mutable';
  with    'Reaction::UI::ViewPort::Action::Role::Close';

  ...
  1;

=head1 DESCRIPTION

This role integrates a C<close> event and inherits an
L<apply|Reaction::UI::ViewPort::Action::Role::Close/apply>
event into the consuming viewport.

=head1 ATTRIBUTES

=head2 close_label

Defaults to returned string value of L</_build_close_label> (C<close>).

=head2 close_label_close

Defaults to returned string value of L</_build_close_label_close> (C<close>).

=head2 close_label_cancel

This label is only shown when C<changed> is true. It is initialised
with the returned string value of L</_build_close_label_cancel>.

Default: 'cancel'

=head2 on_close_callback

CodeRef. If set will be called on L</close>.

=head1 METHODS

=head2 close

Calls L</on_close_callback> if one is set.

=head2 can_close

Returns true.

=head2 apply

Extends L<Reaction::UI::ViewPort::Action::Role::Apply/apply> and sets
the L</close_label> to L</close_label_cancel> if the original call to
C<apply> was not successfull.

Returns the result of the original C<apply> call.

=head2 accept_events

Extends L<Reaction::UI::ViewPort::Action::Role::Apply/accept_events>
with the C<close> event if an L</on_close_callback> was provided.

=head1 SEE ALSO

L<Reaction::UI::ViewPort::Action::Role::Apply>

L<Reaction::UI::ViewPort::Action::Role::OK>

=head1 AUTHORS

See L<Reaction::Class> for authors.

=head1 LICENSE

See L<Reaction::Class> for the license.

=cut
