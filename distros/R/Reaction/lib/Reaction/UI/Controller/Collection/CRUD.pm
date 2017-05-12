package Reaction::UI::Controller::Collection::CRUD;

use Moose;
BEGIN { extends 'Reaction::UI::Controller::Collection'; }

use aliased 'Reaction::UI::ViewPort::ListView';

__PACKAGE__->config(
  action => {
    create => { Chained => 'base', },
    delete_all => { Chained => 'base', },
    update => { Chained => 'object', },
    delete => { Chained => 'object', },
  },
);

with(
  'Reaction::UI::Controller::Role::Action::Create',
  'Reaction::UI::Controller::Role::Action::Update',
  'Reaction::UI::Controller::Role::Action::Delete',
  'Reaction::UI::Controller::Role::Action::DeleteAll',
);

around _build_action_viewport_map => sub {
  my $orig = shift;
  my $map = shift->$orig( @_ );
  $map->{list} = ListView;
  return $map;
};

sub _build_default_member_actions {
  [ @{shift->next::method(@_)}, qw/update delete/ ];
}

sub _build_default_collection_actions {
  [ @{shift->next::method(@_)}, qw/create delete_all/ ];
}

##DEFAULT CALLBACKS

sub on_delete_all_close_callback {
  my($self, $c) = @_;
  $self->redirect_to($c, 'list');
}

sub on_create_apply_callback {
  my ($self, $c, $vp, $result) = @_;
  if( $self->can('after_create_callback') ){
    $c->log->debug("'after_create_callback' has been replaced with 'on_create_apply_callback' and is deprecated.");
    shift @_;
    return $self->after_create_callback(@_);
  }
  return $self->redirect_to
    ( $c, 'update', [ @{$c->req->captures}, $result->id ] );
}

sub on_create_close_callback {
  my($self, $c, $vp) = @_;
  $self->redirect_to( $c, 'list' );
}

sub on_update_close_callback {
  my($self, $c) = @_;
  #this needs a better solution. currently thinking about it
  my @cap = @{$c->req->captures};
  pop(@cap); # object id
  $self->redirect_to($c, 'list', \@cap);
}

sub on_delete_close_callback {
  my($self, $c) = @_;
  #this needs a better solution. currently thinking about it
  my @cap = @{$c->req->captures};
  pop(@cap); # object id
  $self->redirect_to($c, 'list', \@cap);
}

#### DEPRECATED METHODS

sub get_model_action {
  my ($self, $c, $name, $target) = @_;
  if( $c->debug ){
    my ($package,undef,$line,$sub_name,@rest) = caller(1);
    my $message = "The method 'get_model_action', called from sub '${sub_name}' in package ${package} at line ${line} is deprecated.";
    $c->log->debug( $message );
  }
  return $target->action_for($name, ctx => $c);
}

sub basic_model_action {
  my ($self, $c, $vp_args) = @_;
  if( $c->debug ){
    my ($package,undef,$line,$sub_name,@rest) = caller(1);
    my $message = "The method 'basic_model_action', called from sub '${sub_name}' in package ${package} at line ${line} is deprecated.";
    $c->log->debug( $message );
  }
  my $stash = $c->stash;
  my $target = delete $vp_args->{target};
  $target ||= ($stash->{object} || $stash->{collection} || $self->get_collection($c));

  my $action_name = join('', map{ ucfirst } split('_', $c->stack->[-1]->name));
  my $model = $self->get_model_action($c, $action_name, $target);
  return $self->basic_page($c, { model => $model, %{$vp_args||{}} });
}

1;

__END__

=head1 NAME

Reaction::UI::Controller::Collection::CRUD - Basic CRUD functionality for Reaction::InterfaceModel data

=head1 DESCRIPTION

Controller class which extends L<Reaction::UI::Controller::Collection> to 
provide basic Create / Update / Delete / DeleteAll actions.

Building on the base of the Collection controller this controller allows you to
easily create complex and highly flexible CRUD functionality for your 
InterfaceModel models by providing a simple way to render and process your
custom InterfaceModel Actions and customize built-ins.

=head1 ROLES CONSUMED

This role also consumes the following roles:

=over4

=item L<Reaction::UI::Controller::Role::Action::Create>

=item L<Reaction::UI::Controller::Role::Action::Update>

=item L<Reaction::UI::Controller::Role::Action::Delete>

=item L<Reaction::UI::Controller::Role::Action::DeleteAll>

=back

=head1 METHODS

=head2 get_model_action $c, $action_name, $target_im

DEPRECATED. Get an instance of the C<$action_name> 
L<InterfaceModel::Action|Reaction::InterfaceModel::Action> for model C<$target>
This action is suitable for passing to an 
C<Action|Reaction::UI::ViewPort::Action> viewport

=head2 basic_model_action $c, \%vp_args

DEPRECTAED extension to C<basic_page> which automatically instantiates an 
L<InterfaceModel::Action|Reaction::InterfaceModel::Action> with the right
data target using C<get_model_action>

=head2 after_create_callback $c, $vp, $result

When a <create> action is applied, move the user to the new object's,
C<update> page.

=head2 _build_action_viewport_map

Map C<list> to L<ListView|Reaction::UI::ViewPort::ListView>.

=head2 _build_default_member_actions

Add C<update> and C<delete> to the list of default actions.

=head2 _build_default_collection_actions

Add C<create> and C<delete_all> to the list of default actions.

=head1 ACTIONS

=head2 create

Chained to C<base>. See L<Reaction::UI::Controller::Role::Action::Create>

=head2 delete_all

Chained to C<base>. See L<Reaction::UI::Controller::Role::Action::DeleteAll>

=head2 update

Chained to C<object>. See L<Reaction::UI::Controller::Role::Action::Update>

=head2 delete

Chained to C<object>. See L<Reaction::UI::Controller::Role::Action::Delete>

=head1 SEE ALSO

L<Reaction::UI::Controller::Collection>, L<Reaction::UI::Controller>

=head1 AUTHORS

See L<Reaction::Class> for authors.

=head1 LICENSE

See L<Reaction::Class> for the license.

=cut
