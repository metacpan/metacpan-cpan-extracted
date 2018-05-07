package Model::Envoy::Set;

use Moose::Role;

our $VERSION = '0.1';

=head1 Model::Envoy::Set

A role for creating, finding and listing Model::Envoy based objects. Similar in
philosophy to DBIx::Class::ResultSets.

=head2 Required Methods

There is one method you will need to implement in a class that uses this role:

=head3 namespace()

This should return the parent namespace of the Model::Envoy based classes you are 
creating.  For exampe, if you have My::Model::Foo and My::Model::Bar that both use
the Model::Envoy role, then you could define My::Models to use Model::Envoy::Set and it's
namespace method would return 'My::Model'.

=cut

# The parent namespace for your models is stored here:
requires 'namespace';

use Moose::Util::TypeConstraints;

has model => (
    is => 'rw',
    isa => 'Str',
    required => 1,
);

=head2 Methods

=head3 m($type)

Returns an Envoy::Set of the specified $type. So for a class My::Model::Foo

    my $set = My::Models->m('Foo');

=cut

sub m {

    my ( $class, $name ) = @_;

    my $namespace = $class->namespace;

    $name =~ s/^$namespace\:://;

    return $class->new( model => "$namespace::$name" );
}

=head3 build(%params)

Create a new instance of the Model::Envoy based class referenced by the set:

    my $instance = $set->build({
        attribute => $value,
        ...
    });

=cut

sub build {
    my( $self, $params, $no_rel ) = @_;

    if ( ! ref $params ) {
        die "Cannot build a ". $self->model ." from '$params'";
    }
    elsif( ref $params eq 'HASH' ) {
        return $self->model->new(%$params);
    }
    elsif( ref $params eq 'ARRAY' ) {
        die "Cannot build a ". $self->model ." from an Array Ref";
    }
    elsif( blessed $params && $params->isa( $self->model ) ) {
        return $params;
    }
    elsif( blessed $params && $params->isa( 'DBIx::Class::Core' ) ) {

        my $type = ( ( ref $params ) =~ / ( [^:]+ ) $ /x )[0];

        return $self->m( $type )->model->new_from_db($params, $no_rel);
    }
    else {
        die "Cannot coerce a " . ( ref $params ) . " into a " . $self->model;
    }
}

=head3 fetch(%params)

Retrieve an object from storage

    my $instance = $set->fetch( id => 1 );

=cut

sub fetch {
    my $self = shift;
    my %params;

    return undef unless @_;

    if ( @_ == 1 ) {

        my ( $id ) = @_;

        $params{id} = $id;
    }
    else {

        my ( $key, $value ) = @_;

        $params{$key} = $value;
    }

    if ( my $result = ($self->model->_schema->resultset( $self->model->dbic )
        ->search(\%params))[0] ) {

        return $self->model->new_from_db($result);
    }

    return undef;
}

=head3 list(%params)

Query storage and return a list of objects that matched the query

    my $instances = $set->list(
        color => 'green',
        size  => 'small',
        ...
    );

=cut

sub list {
    my $self = shift;

    return [
        map {
            $self->model->new_from_db($_);
        }
        $self->model->_schema->resultset( $self->model->dbic )->search(@_)
    ];
}

=head3 load_types(@names)

For now Model::Envoy does not slurp all the classes in a certain namespace
for use with $set->m().  Call load_types() at the start of your program instead:

    My::Models->load_types( qw( Foo Bar Baz ) );

=cut

sub load_types {
    my ( $self, @types ) = @_;

    my $namespace = $self->namespace;

    foreach my $type ( @types ) {

        die "invalid type name '$type'" unless $type =~ /^[a-z]+$/i;

        eval "use $namespace\::$type";
        die "Could not load model type '$type': $@" if $@;
    }
}

1;