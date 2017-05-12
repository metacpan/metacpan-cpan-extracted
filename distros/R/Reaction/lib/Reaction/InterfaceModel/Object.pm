package Reaction::InterfaceModel::Object;

use metaclass 'Reaction::Meta::InterfaceModel::Object::Class';
use Reaction::Meta::Attribute;
use Reaction::Class;

use namespace::clean -except => [ qw(meta) ];


has _action_class_map =>
  (is => 'rw', isa => 'HashRef', required => 1, default => sub{ {} },
   metaclass => 'Reaction::Meta::Attribute');

has _default_action_class_prefix =>
  (
   is => 'ro',
   isa => 'Str',
   lazy_build => 1,
   metaclass => 'Reaction::Meta::Attribute',
  );

#DBIC::Collection would override this to use result_class for example
sub _build__default_action_class_prefix {
  my $self = shift;
  ref $self || $self;
};

#just a little convenience
sub parameter_attributes {
  shift->meta->parameter_attributes;
};

#just a little convenience
sub domain_models {
  shift->meta->domain_models;
};
sub _default_action_class_for {
  my ($self, $action) = @_;
  confess("Wrong arguments") unless $action;
  #little trick in case we call it in class context!
  my $prefix = ref $self ?
    $self->_default_action_class_prefix :
      $self->_build__default_action_class_prefix;

  return join "::", $prefix, 'Action', $action;
};
sub _action_class_for {
  my ($self, $action) = @_;
  confess("Wrong arguments") unless $action;
  if (defined (my $class = $self->_action_class_map->{$action})) {
    return $class;
  }
  return $self->_default_action_class_for($action);
};
sub action_for {
  my ($self, $action, %args) = @_;
  confess("Wrong arguments") unless $action;
  my $class = $self->_action_class_for($action);
  %args = (
    %{$self->_default_action_args_for($action)},
    %args,
    %{$self->_override_action_args_for($action)},
  );
  return $class->new(%args);
};

#this really needs to be smarter, fine for CRUD, shit for anything else
# massive fucking reworking needed here, really
sub _default_action_args_for { {} };
sub _override_action_args_for { {} };

__PACKAGE__->meta->make_immutable;


1;

__END__;


=head1 NAME

Reaction::InterfaceModel::Object

=head1 SYNOPSIS

=head1 DESCRIPTION

InterfaceModel Object base class.

=head1 Attributes

=head2 _action_class_map

RW, isa HashRef - Returns an empty hashref by default. It will hold a series of actions
as keys with their corresponding action classes as values.

=head2 _default_action_class_prefix

RO, isa Str - Default action class prefix. Lazy build by default to the value
returned by C<_build_default_action_class_prefix> which is C<ref $self || $self>.

=head1 Methods

=head2 parameter_attributes

=head2 domain_models

Shortcuts for these same subs in meta. They will return attribute objects that are of
the correct type, L<Reaction::Meta::InterfaceModel::Object::ParameterAttribute> and
L<Reaction::Meta::InterfaceModel::Object::DomainModelAttribute>

=head2 _default_action_class_for $action

Provides the default package name for the C<$action> action-class.
It defaults to the value of C<_default_action_class_prefix> followed by
C<::Action::$action>

   #for MyApp::Foo, returns MyApp::Foo::Action::Create
   $obj->_default_action_class_for('Create');

=head2 _action_class_for $action

Return the action class for an action name. Will search
C<_action_class_map> or, if not found, use the value of
C<_default_action_class_for>

=head2 action_for $action, %args

Will return a new instance of C<$action>. If specified,
 %args will be passed through to C<new> as is.

=head2 _default_action_args_for

By default will return an empty hashref

=head2 _override_action_args_for

Returns empty hashref by default.

=head1 SEE ALSO

L<Reaction::InterfaceModel::ObjectClass>

=head1 AUTHORS

See L<Reaction::Class> for authors.

=head1 LICENSE

See L<Reaction::Class> for the license.

=cut
