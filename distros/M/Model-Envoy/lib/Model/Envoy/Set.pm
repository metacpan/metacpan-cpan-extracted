package Model::Envoy::Set;

use MooseX::Role::Parameterized;
use Module::Runtime 'use_module';
use Moose::Util::TypeConstraints;

our $VERSION = '0.3.0';

=head1 Model::Envoy::Set

A role for creating, finding and listing Model::Envoy based objects. Similar in
philosophy to DBIx::Class::ResultSets.

=head2 Synopsis

    package My::Models;

    use Moose;
    with 'Model::Envoy::Set' => { namespace => 'My::Envoy' };


    ....then later...

    my $widget = My::Models->m('Widget')->fetch( id => 2 );

    $widget->name('renamed');
    $widget->save;


=head2 Configuration

When incorporating this role into your class, you will need to specify the perl namespace where
your model classes reside per the synopsis above. 

=head2 Methods

=head3 m($type)

Returns an Envoy::Set of the specified $type. So for a class My::Model::Foo

    my $set = My::Models->m('Foo');

=head3 build(\%params)

Create a new instance of the Model::Envoy based class referenced by the set:

    my $instance = $set->build({
        attribute => $value,
        ...
    });

=head3 fetch(%params)

Retrieve an object from storage

    my $model = $set->fetch( id => 1 );

=head3 list(%params)

Query storage and return a list of objects that matched the query

    my $models = $set->list(
        color => 'green',
        size  => 'small',
        ...
    );

=head3 get_storage($storage_package)

Passes back the storage plugin specified by C<$storage_package> being used by the set's model type.
Follows the same namespace resolution process as the C<Model::Envoy> method of the same name.

=head3 load_types(@names)

For now Model::Envoy does not slurp all the classes in a certain namespace
for use with $set->m().  Call load_types() at the start of your program instead:

    My::Models->load_types( qw( Foo Bar Baz ) );

=cut


parameter namespace => (
    isa      => 'Str',
    required => 1,
);

role {

    my $namespace = shift->namespace;

    method '_namespace' => sub {
        $namespace;
    };
};

has model_class => (
    is => 'rw',
    isa => 'Str',
    required => 1,
);

sub m {
    my ( $class, $name ) = @_;

    my $namespace = $class->_namespace;

    $name =~ s/^$namespace\:://;

    return $class->new( model_class => "$namespace\::$name" );
}

sub build {
    my( $self, $params, $no_rel ) = @_;

    return $self->model_class->build($params,$no_rel);
}
sub fetch {
    my $self = shift;

    return undef unless @_;
    return $self->model_class->_dispatch('fetch', @_ );
}

sub list {
    my $self = shift;

    return $self->model_class->_dispatch('list', @_ );

}

sub get_storage {
    my $self = shift;

    $self->model_class->get_storage(@_);
}

sub load_types {
    my ( $self, @types ) = @_;

    my $namespace = $self->_namespace;

    foreach my $type ( @types ) {

        die "invalid type name '$type'" unless $type =~ /^[a-z]+$/i;

        use_module("$namespace\::$type")
            or die "Could not load model type '$type'";
    }
}

1;