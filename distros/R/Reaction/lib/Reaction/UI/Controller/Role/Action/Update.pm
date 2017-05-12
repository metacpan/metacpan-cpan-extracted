package Reaction::UI::Controller::Role::Action::Update;

use Moose::Role -traits => 'MethodAttributes';
use Reaction::UI::ViewPort::Action;

requires qw/make_context_closure setup_viewport/;

sub update :Action :Args(0) {
  my ($self, $c) = @_;
  my $target = $c->stash->{object};
  my %vp_args = ( model => $target->action_for('Update') );

  if( $self->can('on_update_apply_callback') ){
    my $apply = sub { $self->on_update_apply_callback( @_) };
    $vp_args{on_apply_callback} = $self->make_context_closure( $apply );
  }
  if( $self->can('on_update_close_callback') ){
    my $close = sub { $self->on_update_close_callback( @_) };
    $vp_args{on_close_callback} = $self->make_context_closure( $close );
  }

  $self->setup_viewport( $c, \%vp_args );
}

around _build_action_viewport_map => sub {
  my $orig = shift;
  my $map = shift->$orig( @_ );
  $map->{update} = 'Reaction::UI::ViewPort::Action';
  return $map;
};

1;

__END__;

=head1 NAME

Reaction::UI::Controller::Role::Action::Update - Update action

=head1 DESCRIPTION

Provides a C<update> action, which sets up an L<Action Viewport|Reaction::UI::Viewport::Action>
by calling C<action_for> on the object located in the C<object> slot of the
C<stash>.

=head1 SYNOPSYS

    package MyApp::Controller::Foo;

    use base 'Reaction::Controller';
    use Reaction::Class;

    with(
      'Reaction::UI::Controller::Role::GetCollection',
      'Reaction::UI::Controller::Role::Action::Simple',
      'Reaction::UI::Controller::Role::Action::Object',
      'Reaction::UI::Controller::Role::Action::Update'
    );

    __PACKAGE__->config( action => {
      object => { Chained => 'base' },
      update => { Chained => 'object' },
    } );

    sub base :Chained('/base') :CaptureArgs(0) {
      ...
    }

    sub on_update_apply_callback{ #optional callback
      my($self, $c, $vp, $result) = @_;
      ...
    }

    sub on_update_close_callback{ #optional callback
      my($self, $c, $vp) = @_;
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

=item C<make_context_closure>

=back

=head1 ACTIONS

=head2 update

Chain endpoint with no args, sets up the viewport with the appropriate action.
If the methods C<on_update_apply_callback> and C<on_update_close_callback> are
present in the consuming class, they will be used as callbacks in the viewport.

=head1 METHODS

=head2 _build_action_viewport_map

Extends to set the C<delete> key in the map to L<Reaction::UI::ViewPort::Action>

=head1 SEE ALSO

=over4

=item L<Reaction::UI::Controller>

=item L<Reaction::UI::Controller::Role::GetCollection>

=item L<Reaction::UI::Controller::Role::Action::Simple>

=item L<Reaction::UI::Controller::Role::Action::List>

=item L<Reaction::UI::Controller::Role::Action::View>

=item L<Reaction::UI::Controller::Role::Action::Object>

=item L<Reaction::UI::Controller::Role::Action::Create>

=item L<Reaction::UI::Controller::Role::Action::Delete>

=item L<Reaction::UI::Controller::Role::Action::DeleteAll>

=back

=head1 AUTHORS

See L<Reaction::Class> for authors.

=head1 LICENSE

See L<Reaction::Class> for the license.

=cut
