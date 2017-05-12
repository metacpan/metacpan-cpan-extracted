package Reaction::UI::ViewPort::Action::Role::Apply;

use Reaction::Role;
use MooseX::Types::Moose qw/Str CodeRef/;

requires 'do_apply';
has apply_label => (is => 'rw', isa => Str, lazy_build => 1);
has on_apply_callback => (is => 'rw', isa => CodeRef);

sub _build_apply_label { 'apply' }

sub can_apply { 1 }

sub apply {
  my $self = shift;
  if ($self->can_apply && (my $result = $self->do_apply)) {
    $self->on_apply_callback->($self => $result) if $self->has_on_apply_callback;
    return 1;
  } else {
    if( my $coderef = $self->can('close_label') ){
      $self->$coderef( $self->close_label_cancel );
    }
    return 0;
  }
};

around accept_events => sub { ( 'apply', shift->(@_) ) };

1;

__END__

=head1 NAME

Reaction::UI::ViewPort::Action::Role::Apply - Integrate an Apply event into the ViewPort

=head1 SYNOPSIS

  package MyApp::UI::ViewPort::SomeAction;
  use Reaction::Class;

  use namespace::clean -except => 'meta';

  extends 'Reaction::UI::ViewPort::Object::Mutable';
  with    'Reaction::UI::ViewPort::Action::Role::Apply';

  ...
  1;

=head1 DESCRIPTION

This role integrates an C<apply> event into the consuming viewport that will call the
required L</do_apply> role.

=head1 REQUIRED METHODS

=head2 do_apply

Will be called when an L</apply> event comes in.

=head1 ATTRIBUTES

=head2 apply_label

Defaults to 'apply', returned by L</_build_apply_label>.

=head2 on_apply_callback

CodeRef. Will be called after L</apply> if L</can_apply> and L</do_apply> return
true. See L</apply> for argument details.

=head1 METHODS

=head2 can_apply

Returns true by default. Determines if L</do_apply> can be called.

=head2 apply

Calls a user-supplied C<do_apply> and if it is successful runs the
C<on_apply_callback> passing C<$self> and the result of C<do_apply> as args.

=head1 INTERNAL METHODS

=head2 _build_apply_label

Defaults to C<apply>.

=head1 SEE ALSO

L<Reaction::UI::ViewPort::Action::Role::Close>

L<Reaction::UI::ViewPort::Action::Role::OK>

=head1 AUTHORS

See L<Reaction::Class> for authors.

=head1 LICENSE

See L<Reaction::Class> for the license.

=cut

