package Reaction::UI::Controller::Role::Action::List;

use Moose::Role -traits => 'MethodAttributes';
use Reaction::UI::ViewPort::Collection;

requires qw/get_collection setup_viewport/;

sub list :Action :Args(0) {
  my ($self, $c) = @_;
  my $collection = $c->stash->{collection} || $self->get_collection($c);
  $self->setup_viewport($c, { collection => $collection });
}

around _build_action_viewport_map => sub {
  my $orig = shift;
  my $map = shift->$orig( @_ );
  $map->{list} = 'Reaction::UI::ViewPort::Collection';
  return $map;
};

1;

__END__;

=head1 NAME

Reaction::UI::Controller::Role::Action::List - List action

=head1 DESCRIPTION

Provides a C<list> action, which sets up an L<Collection Viewport|Reaction::UI::Viewport::Collection>
using the collection contained in the C<collection> slot of the stash, if
present, or using the object returned by the method C<get_collection>.

=head1 SYNOPSYS

    package MyApp::Controller::Foo;

    use base 'Reaction::Controller';
    use Reaction::Class;

    with(
      'Reaction::UI::Controller::Role::GetCollection',
      'Reaction::UI::Controller::Role::Action::Simple',
      'Reaction::UI::Controller::Role::Action::List'
    );


    __PACKAGE__->config( action => {
      list => { Chained => 'base' },
    } );

    sub base :Chained('/base') :CaptureArgs(0) {
      ...
    }

=head1 ROLES CONSUMED

This role also consumes the following roles:

=over4

=item L<Reaction::UI::Controller::Role::Action::Simple>

=back

=head1 REQUIRED METHODS

The following methods must be provided by the consuming class:

=over4

=item C<get_collection>

=back

=head1 ACTIONS

=head2 list

Chain endpoint with no args, sets up the viewport with the appropriate action.

=head1 METHODS

=head2 _build_action_viewport_map

Extends to set the C<list> key in the map to L<Reaction::UI::ViewPort::Action>

=head1 SEE ALSO

=over4

=item L<Reaction::UI::Controller>

=item L<Reaction::UI::Controller::Role::GetCollection>

=item L<Reaction::UI::Controller::Role::Action::Simple>

=item L<Reaction::UI::Controller::Role::Action::View>

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
