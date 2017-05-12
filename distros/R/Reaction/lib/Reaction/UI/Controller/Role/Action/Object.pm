package Reaction::UI::Controller::Role::Action::Object;

use Moose::Role -traits => 'MethodAttributes';

requires 'get_collection';

sub object :Action :CaptureArgs(1) {
  my ($self, $c, $key) = @_;
  if( my $object = $self->get_collection($c)->find($key) ){
    $c->stash(object => $object);
    return $object;
  }
  $c->res->status(404);
  return;
}

1;

__END__;

=head1 NAME

Reaction::UI::Controller::Role::Action::Object

=head1 DESCRIPTION

Provides an C<object> action, which attempts to find an item in a collection
and store it in the stash.

=head1 SYNOPSYS

    package MyApp::Controller::Foo;

    use base 'Reaction::Controller';
    use Reaction::Class;

    with(
      'Reaction::UI::Controller::Role::GetCollection',
      'Reaction::UI::Controller::Role::Action::Simple',
      'Reaction::UI::Controller::Role::Action::Object',
    );

    __PACKAGE__->config( action => {
      object => { Chained => 'base', PathPart => 'id' },
      foo_action => { Chained => 'object' },
    } );

    sub base :Chained('/base') :CaptureArgs(0) {
      ...
    }

    sub foo_action :Args(0){
      my($self, $c) = @_;
      $c->stash->{object}; #object is here....
    }

=head1 REQUIRED METHODS

The following methods must be provided by the consuming class:

=over4

=item C<get_collection>

=back

=head1 ACTIONS

=head2 object

Chain link, captures one argument. Attempts to find a single object by passing
the captured argument to the C<find> method of the collection returned by
C<get_collection>. If the object is found it is stored in the stash under the
C<object> key.

=head1 SEE ALSO

=over4

=item L<Reaction::UI::Controller>

=item L<Reaction::UI::Controller::Role::GetCollection>

=item L<Reaction::UI::Controller::Role::Action::Simple>

=item L<Reaction::UI::Controller::Role::Action::List>

=item L<Reaction::UI::Controller::Role::Action::View>

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
