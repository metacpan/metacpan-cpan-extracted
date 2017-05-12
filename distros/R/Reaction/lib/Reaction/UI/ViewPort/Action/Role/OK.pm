package Reaction::UI::ViewPort::Action::Role::OK;

use Reaction::Role;
use MooseX::Types::Moose qw/Str/;
with 'Reaction::UI::ViewPort::Action::Role::Close';

has ok_label => (is => 'rw', isa => Str, lazy_build => 1);

sub _build_ok_label { 'ok' }

sub ok {
  my $self = shift;
  $self->close(@_) if $self->apply(@_);
}

around accept_events => sub {
  my $orig = shift;
  my $self = shift;
  ( ($self->has_on_close_callback ? ('ok') : ()), $self->$orig(@_) );
};

1;

__END__

=head1 NAME

Reaction::UI::ViewPort::Action::Role::OK - Integrate OK, Apply and Close events

=head1 SYNOPSIS

  package MyApp::UI::ViewPort::SomeAction;
  use Reaction::Class;

  use namespace::clean -except => 'meta';

  extends 'Reaction::UI::ViewPort::Object::Mutable';
  with    'Reaction::UI::ViewPort::Action::Role::OK';

  ...
  1;

=head1 DESCRIPTION

This role integrates an C<ok> event and inherits a 
L<close|Reaction::UI::ViewPort::Action::Role::Close/close>
and an L<apply|Reaction::UI::ViewPort::Action::Role::Apply/apply>
event into the consuming viewport.

=head1 ATTRIBUTES

=head2 ok_label

Defaults to C<ok>. String is built by L</_build_ok_label>.

=head1 METHODS

=head2 ok

Calls C<apply>, and then C<close> if successful.

=head2 accept_events

Extends L<Reaction::UI::ViewPort::Action::Role::Close/accept_events> with the
event C<ok> if an L<on_close_callback|Reaction::UI::ViewPort::Action::Role::Close/on_close_callback>
was provided.

=head1 INTERNAL METHODS

=head2 _build_ok_label

Returns the string representing the label for the OK action. Defaults to C<ok>.

=head1 SEE ALSO

L<Reaction::UI::ViewPort::Action::Role::Apply>

L<Reaction::UI::ViewPort::Action::Role::Close>

=head1 AUTHORS

See L<Reaction::Class> for authors.

=head1 LICENSE

See L<Reaction::Class> for the license.

=cut
