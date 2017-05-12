package Reaction::UI::Controller::Role::GetCollection;

use Moose::Role -traits => 'MethodAttributes';

has model_name => (isa => 'Str', is => 'rw', required => 1);
has collection_name => (isa => 'Str', is => 'rw', required => 1);

sub get_collection {
  my ($self, $c) = @_;
  my $model = $c->model( $self->model_name );
  confess "Failed to find Catalyst model named: " . $self->model_name
    unless $model;
  my $collection = $self->collection_name;
  if( my $meth = $model->can( $collection ) ){
    return $model->$meth;
  } elsif ( my $meta = $model->can('meta') ){
    if ( my $attr = $model->$meta->find_attribute_by_name($collection) ) {
      my $reader = $attr->get_read_method;
      return $model->$reader;
    }
  }
  confess "Failed to find collection $collection";
}

1;

__END__;

=head1 NAME

Reaction::UI::Controller::Role::GetCollection

=head1 DESCRIPTION

Provides a C<get_collection> method, which fetches an C<Collection> object
from a specified model.

=head1 SYNOPSYS

    package MyApp::Controller::Foo;

    use base 'Reaction::Controller';
    use Reaction::Class;

    with 'Reaction::UI::Controller::Role::GetCollection';

    __PACKAGE__->config( model_name => 'MyAppIM', collection_name => 'foos' );

    sub bar :Local {
      my($self, $c) = @_;
      my $obj = $self->get_collection($c)->find( $some_key );
    }

=head1 ATTRIBUTES

=head2 model_name

The name of the model this controller will use as it's data source. Should be a
name that can be passed to C<$C-E<gt>model>

=head2 collection_name

The name of the collection whithin the model that this Controller will be
utilizing.

=head1 METHODS

=head2 get_collection $c

Returns an instance of the collection this controller uses.

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
