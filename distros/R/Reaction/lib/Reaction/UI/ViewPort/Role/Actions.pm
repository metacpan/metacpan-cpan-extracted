package Reaction::UI::ViewPort::Role::Actions;

use Reaction::Role;
use Reaction::UI::ViewPort::URI;

use namespace::clean -except => [ qw(meta) ];

has actions => (
  is => 'ro',
  isa => 'ArrayRef',
  lazy_build => 1
);

has action_order => (
  is => 'ro',
  isa => 'ArrayRef'
);

has action_filter => (
  isa => 'CodeRef', is => 'ro',
);

has action_prototypes => (
  is => 'ro',
  isa => 'HashRef',
  required => 1,
  default => sub{ {} }
);

has computed_action_order => (
  is => 'ro',
  isa => 'ArrayRef',
  lazy_build => 1
);

sub _filter_action_list {
    my $self = shift;
    my $actions = [keys %{$self->action_prototypes}];
    return $self->has_action_filter ?
        $self->action_filter->($actions, $self->model)
        : $actions;
}

sub _build_computed_action_order {
  my $self = shift;
  my $ordered = $self->sort_by_spec(
    ($self->has_action_order ? $self->action_order : []),
    $self->_filter_action_list
  );
  return $ordered;
}

sub _build_actions {
  my ($self) = @_;
  my (@act, $i);
  my $ctx = $self->ctx;
  my $loc = $self->location;
  my $target = $self->model;

  foreach my $proto_name ( @{ $self->computed_action_order } ) {
    my $proto = $self->action_prototypes->{$proto_name};
    my $uri = $proto->{uri} or confess('uri is required in prototype action');
    my $label = exists $proto->{label} ? $proto->{label} : $proto_name;
    my $layout = exists $proto->{layout} ? $proto->{layout} : 'uri';

    my $action = Reaction::UI::ViewPort::URI->new(
      location => join ('-', $loc, 'action', $i++),
      uri => ( ref($uri) eq 'CODE' ? $uri->($target, $ctx) : $uri ),
      display => ( ref($label) eq 'CODE' ? $label->($target, $ctx) : $label ),
      layout => $layout,
    );
    push(@act, $action);
  }
  return \@act;
}

1;

__END__;

=head1 NAME

Reaction::UI::ViewPort::Role::Actions

=head1 DESCRIPTION

A role to ease attaching actions to L<Reaction::InterfaceModel::Object>s

=head1 ATTRIBUTES

=head2 actions

Read-only, lazy-building ArrayRef of URI objects pointing to actions.

=head2 action_prototypes

A HashRef of prototypes for building the Action links. The prototypes should be
composed like these:

    my %action_prototypes = (
      example_action => { label => 'Example Action', uri => $uri_obj },
    );

    #or you can get fancy and do something like what is below:
    sub make_label{
      my($im, $ctx) =  @_; #InterfaceModel::Object/Collection, Catalyst Context
      return 'label_text';
    }
    sub make_uri{
      my($im, $ctx) =  @_; #InterfaceModel::Object/Collection, Catalyst Context
      return return $ctx->uri_for('some_action');
    }
    my %action_prototypes = (
      example_action => { label => \&make_label, uri => \&make_uri },
    );

=head2 action_order

User-provided ArrayRef with how the actions should be ordered eg

     action_order => [qw/view edit delete/]

=head2 computed_action_order

Read-only lazy-building ARRAY ref. The final computed action order. This may
differ from the C<action_order> provided if you any actions were not included
in that list.

=head1 METHODS

=head2 _build_actions

Cycle through the C<computed_action_order> and create a new
L<ViewPort::URI|Reaction::UI::ViewPort::URI> object for each action using the
provided prototypes.

=head2 _build_computed_action_order

Compute the final action ordering by using the provided C<action_order> as a
spec to order all the present actions (the keys of C<action_prototypes>)

=head1 ACTION PROTOTYPES

Action prototypes are simply hashrefs that must contain a C<uri> key and may
contain a C<label> key. The label can be anything that the display attribute of
L<ViewPort::URI|Reaction::UI::ViewPort::URI> will accept, usually a scalar or a
ViewPort. The value for C<uri> may be either a scalar, a L<URI> object (or
anything that C<ISA URI>).

Additionally, both C<label> and C<uri> can be CODE refs. In this case, the code
will be executed at C<_build_actions> time and will recieve two arguments, the
value returned by C<model> and the value returned by C<ctx> in that order. Both
of these methods should be implemented in the consuming class. By convention,
model refers to the target of the action, an C<InterfaceModel::Object> in the
case of a member action and an C<InterfaceModel::Collection> in the case of a
Collection action. C<ctx> should be the current Catalyst context.

=head1 AUTHORS

See L<Reaction::Class> for authors.

=head1 LICENSE

See L<Reaction::Class> for the license.

=cut
