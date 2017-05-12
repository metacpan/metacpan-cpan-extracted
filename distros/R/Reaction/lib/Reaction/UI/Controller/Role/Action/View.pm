package Reaction::UI::Controller::Role::Action::View;

use Moose::Role -traits => 'MethodAttributes';
use Reaction::UI::ViewPort::Object;

requires 'setup_viewport';

sub view :Action :Args(0) {
  my ($self, $c) = @_;
  $self->setup_viewport($c, { model => $c->stash->{object} });
}

around _build_action_viewport_map => sub {
  my $orig = shift;
  my $map = shift->$orig( @_ );
  $map->{view} = 'Reaction::UI::ViewPort::Object';
  return $map;
};

1;

__END__;

=head1 NAME

Reaction::UI::Controller::Role::Action::View - View action

=head1 DESCRIPTION

Provides a C<view> action, which sets up an L<Object Viewport|Reaction::UI::Viewport::Object>
using the object located in the C<object> slot of the C<stash>.

=head1 SYNOPSYS

    package MyApp::Controller::Foo;

    use base 'Reaction::Controller';
    use Reaction::Class;

    with(
      'Reaction::UI::Controller::Role::GetCollection',
      'Reaction::UI::Controller::Role::Action::Simple',
      'Reaction::UI::Controller::Role::Action::Object',
      'Reaction::UI::Controller::Role::Action::View'
    );

    __PACKAGE__->config( action => {
      object => { Chained => 'base' },
      view => { Chained => 'object' },
    } );

    sub base :Chained('/base') :CaptureArgs(0) {
      ...
    }


=head1 ROLES CONSUMED

This role also consumes the following roles:

=over4

=item L<Reaction::UI::Controller::Role::Action::Simple>

=back

=head1 ACTIONS

=head2 view

Chain endpoint with no args, sets up the viewport with the appropriate viewport.

=head1 METHODS

=head2 _build_action_viewport_map

Extends to set the C<view> key in the map to L<Reaction::UI::ViewPort::Object>

=head1 SEE ALSO

=over4

=item L<Reaction::UI::Controller>

=item L<Reaction::UI::Controller::Role::GetCollection>

=item L<Reaction::UI::Controller::Role::Action::Simple>

=item L<Reaction::UI::Controller::Role::Action::List>

=item L<Reaction::UI::Controller::Role::Action::Object>

=item L<Reaction::UI::Controller::Role::Action::Create>

=item L<Reaction::UI::Controller::Role::Action::Update>

=item L<Reaction::UI::Controller::Role::Action::Delete>

=item L<Reaction::UI::Controller::Role::Action::DeleteAll>

=back

=head1 AUTHORS

See L<Reaction::Class> for authors.

=head1 LICENSE

See L<Reaction::Class> for the license.

=cut
