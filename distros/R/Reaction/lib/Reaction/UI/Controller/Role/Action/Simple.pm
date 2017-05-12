package Reaction::UI::Controller::Role::Action::Simple;

use Moose::Role -traits => 'MethodAttributes';

requires 'push_viewport';
requires 'merge_config_hashes';

has action_viewport_map => (isa => 'HashRef', is => 'rw', lazy_build => 1);
has action_viewport_args => (isa => 'HashRef', is => 'rw', lazy_build => 1);

sub _build_action_viewport_map { {} }

sub _build_action_viewport_args { {} }

sub setup_viewport {
  my ($self, $c, $vp_args) = @_;
  my $action_name = $c->stack->[-1]->name;
  my $vp = $self->action_viewport_map->{$action_name};
  my $args = $self->merge_config_hashes(
    $vp_args || {},
    $self->action_viewport_args->{$action_name} || {} ,
  );
  return $self->push_viewport($vp, %$args);
}

1;

__END__;

=head1 NAME

Reaction::UI::Controller::Role::Action::Simple

=head1 DESCRIPTION

Provides a C<setup_viewport> method, which makes it easier to setup and
configure a viewport in controller actions.

=head1 SYNOPSYS

    package MyApp::Controller::Foo;

    use base 'Reaction::Controller';
    use Reaction::Class;

    with 'Reaction::UI::Controller::Role::Action::Simple';

    __PACKAGE__->config(
      action_viewport_map => { bar => 'Reaction::UI::Viewport::Object' },
      action_viewport_args => { location => 'custom-location' },
    );

    sub bar :Local {
      my($self, $c) = @_;
      my $obj = $self->get_collection($c)->find( $some_key );
      $self->setup_viewport($c, { model => $obj });
    }

=head1 ATTRIBUTES

=head2 action_viewport_map

=over 4

=item B<_build_action_viewport_map> - Returns empty hashref by default.

=item B<has_action_viewport_map> - Auto generated predicate

=item B<clear_action_viewport_map>- Auto generated clearer method

=back

Read-write lazy building hashref. The keys should match action names in the
Controller and the value should be the ViewPort class that this action should
use.

=head2 action_viewport_args

Read-write lazy building hashref. Additional ViewPort arguments for the action
named as the key in the controller.

=over 4

=item B<_build_action_viewport_args> - Returns empty hashref by default.

=item B<has_action_viewport_args> - Auto generated predicate

=item B<clear_action_viewport_args>- Auto generated clearer method

=back

=head1 METHODS

=head2 setup_viewport $c, \%vp_args

Accepts two arguments, context, and a hashref of viewport arguments. It will
automatically determine the action name using the catalyst stack and call
C<push_viewport> with the ViewPort class name contained in the
C<action_viewport_map> with a set of options determined by merging C<$vp_args>
and the arguments contained in C<action_viewport_args>, if any.

=head1 SEE ALSO

=over4

=item L<Reaction::UI::Controller>

=item L<Reaction::UI::Controller::Role::Action::Simple>

=item L<Reaction::UI::Controller::Role::Action::Object>

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
