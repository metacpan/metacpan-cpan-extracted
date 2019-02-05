package Model::Envoy::Storage::DBIC;

our $VERSION = '0.5.3';

use Moose;
use Scalar::Util 'blessed';
use MooseX::ClassAttribute;

extends 'Model::Envoy::Storage';

=head1 Model::Envoy::Storage::DBIC

A Moose Role that adds a DBIx::Class persistence layer to your Moose class

=head2 Configuration

    with 'Model::Envoy' => { storage => {
        'DBIC' => {
            schema => sub {
                ... connect to database here ...
            }
        }
    } };

The only configuration option for this plugin is a 'schema' method that returns a
C<DBIx::Class:Schema> based object with an open connection to the database. This method
will be passed a reference to your class as its only argument.

=head3 C<dbic()>

This is a method you will need to implement in each C<Model::Envoy> object
that use this storage plugin. It should return the name of the DBIx::Class ResultClass
that your Model uses for database storage.

=head2 Traits

This role implements one trait:

=head3 DBIC

Marking an attribute on your object with the 'DBIC' trait tells this role that it is
backed by a DBIx::Class ResultClass column of the same name.  It also allows for
a few custom options you can apply to that attribute:

=over

=item primary_key => 1

Indicates that this attribute corresponds to the primary key for the database record

=item rel => 'rel_type'

Indicates that the attribute is a relationship to another model or a list of models. Possible
values for this option are

=over

=item belongs_to

=item has_many

=item many_to_many

=back

=item mm_rel => 'bridge_name'

For many-to-many relationships it is necessary to indicate what class
provides the linkage between the two ends of the relationship ( the linking class
maps to the join table in the database).

=back

=head2 Plugin Methods

=head3 build( $dbic_result, [$no_rel] )

Takes a DBIx::Class result object and, if it's class matches your class's dbic()
method, attempts to build a new instance of your class based on the $dbic_result
passed in.

The `no_rel` boolean option prevents the creation process from traversing
attributes marked as relationships, minimizing the amount of data pulled
from the database and the number of new class instances created.

Returns the class instance if successful.

=head3 save()

Performs either an insert or an update for the model, depending on whether
there is already a record for it in the database. This method will propogate
changes from your DBIx::Class record back to your model, to account for DBIC
plugins you may be using that fiddle with column values on insert or update.

Returns the calling object for convenient chaining.

=head3 delete()

Deletes the persistent copy of the current model from the database, if has
been stored there.

Returns nothing.

=head3 in_storage()

Uses DBIx::Class's internal mechanisms to determine if this model
is tied to a record in the database.

Returns a true value if it is, otherwise returns a false value.

=cut

class_has 'schema' => (
    is  => 'rw',
    isa => 'DBIx::Class::Schema',
);

# The actual ResultClass for the model object is stored here:
has '_dbic_result',
    is      => 'rw',
    isa     => 'Maybe[Object]',
    lazy    => 1,
    default => sub {
        my ( $self ) = @_;

        return $self->schema->resultset( $self->model->dbic )->new({});
    };


sub configure {
    my ( $plugin_class, $envoy_class, $conf ) = @_;

    $plugin_class->schema(
        ref $conf->{schema} eq 'CODE' ? $conf->{schema}->($envoy_class) : $conf->{schema}
    );

    $conf->{_configured} = 1;
}


sub build {
    my ( $class, $model_class, $db_result, $no_rel ) = @_;

    return undef
        unless $db_result
            && blessed $db_result
            && $db_result->isa( $model_class->dbic );

    my $data  = $class->_data_for_model( $model_class, $db_result, $no_rel );
    my $model = $model_class->new( %$data );

    $model->get_storage( __PACKAGE__ )->_dbic_result( $db_result );

    return $model;
}

sub fetch {
    my $self        = shift;
    my $model_class = shift;
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

    if ( my $result = ($self->schema->resultset( $model_class->dbic )
        ->search(\%params))[0] ) {

        return $model_class->build($result);
    }

    return undef;
}

sub list {
    my $self = shift;
    my $model_class = shift;

    my $conditions = ref $_[0]
        ? $_[0]
        : { @_ };

    return [
        map { $model_class->build($_) }
            $self->schema->resultset( $model_class->dbic )->search( $conditions )
    ];
}

sub save {
    my ( $self ) = @_;

    my $dbic_result = $self->_dbic_result;

    $self->schema->txn_do( sub {

        # First update/insert non-relationships
        $self->_populate_dbic_result;

        if ( $dbic_result->in_storage ) {
            $dbic_result->update;
        }
        # get_from_storage can be noisy due to
        # https://rt.cpan.org/Public/Bug/Display.html?id=104839
        elsif ( my $copy = $dbic_result->get_from_storage ) {
            $dbic_result->in_storage(1);
            $dbic_result->update();
        }
        else {
            $dbic_result->insert;
        }

        # Then, once we're sure the record exists, update relationships
        for my $attr ( @{$self->_dbic_relationships} ) {

            $self->_db_save_relationship( $attr );
        }

        $dbic_result->update;

        # Finally, propogate any storage-layer changes back to model
        $self->update_model( $dbic_result );

    });

    return $self;
}

sub _data_for_model {
    my ( $class, $model_class, $db_result, $no_rel ) = @_;

    my $data      = {};
    my %relationships = map { $_->name => 1 } @{$class->_dbic_relationships($model_class)};

    foreach my $attr ( grep { defined $db_result->$_ } map { $_->name } @{$class->_dbic_attrs($model_class)} ) {

        next if $no_rel && exists $relationships{$attr};

        if ( blessed $db_result->$attr && $db_result->$attr->isa('DBIx::Class::ResultSet') ) {
            my $attribute  = $model_class->meta->find_attribute_by_name($attr);
            my $class_attr = $attribute->meta->find_attribute_by_name('moose_class');
            my $factory    = $class_attr ? $class_attr->get_value($attribute) : undef;

            $factory ||= ( $attribute->type_constraint->name =~ / (?:ArrayRef|Maybe) \[ (.+?) \] /x )[0];

            if ( $factory ) {

                $data->{$attr} = [ map { $factory->build( $_, 1 ) } $db_result->$attr ];
            }
        }
        else {
            $data->{$attr} = $db_result->$attr;
        }

    }

    return $data;
}

sub _db_save_relationship {
    my ( $self, $attr ) = @_;

    my $dbic_result = $self->_dbic_result;

    my $name  = $attr->name;
    my $type  = $attr->meta->get_attribute('rel')->get_value($attr);
    my $value = $self->model->$name;

    if ( $type eq 'many_to_many' ) {
        my $setter  = 'set_' . $name;
        my $records = $self->_value_to_db( $value );
        $dbic_result->$setter( $self->_value_to_db( $value ) );

        for ( my $i=0; $i < @$value; $i++ ) {
            $value->[$i]->get_storage('DBIC')->update_model($records->[$i]);
        }
    }
    elsif ( $type eq 'has_many' ) {

        foreach my $model ( @$value ) {
            my $result = $self->_value_to_db( $model );

            # update_or_create_related can be noisy due to
            # https://rt.cpan.org/Public/Bug/Display.html?id=104839
            my $data = { $result->get_columns };
            $result = $dbic_result->update_or_create_related( $name => {
                map  { $_ => $data->{$_} }
                grep { defined $data->{$_} } 
                keys %$data
            } );

            $model->get_storage('DBIC')->update_model($result);
        }
    }
}

sub update_model {
    my ( $self, $dbic_result ) = @_;

    $self->model->update( $self->_data_for_model( ref $self->model, $dbic_result ) );
}

sub delete {
    my ( $self ) = @_;

    if ( $self->_dbic_result->in_storage ) {
        $self->_dbic_result->delete;
    }

    return;
}

sub in_storage {
    my ( $self ) = @_;

    return $self->_dbic_result->in_storage;
}

class_has '_cached_dbic_attrs' => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub { {} },
);

sub _dbic_attrs {
    my ( $self, $model ) = @_;

    $model //= $self->model;

    my $model_class = ref $model;
    $model_class ||= $model;

    if ( ! $self->_cached_dbic_attrs->{ $model_class } ) {

        $self->_cached_dbic_attrs->{ $model_class } = [
            grep { $_->does('DBIC') }
            $model->meta->get_all_attributes
        ];
    }

    return $self->_cached_dbic_attrs->{ $model_class }

}

sub _dbic_columns {
    my ( $self, $model ) = @_;

    $model //= $self->model;

    return [
        grep { $_->does('DBIC') && ! $_->is_relationship }
        $model->meta->get_all_attributes
    ];
}

sub _dbic_relationships {
    my ( $self, $model ) = @_;

    $model //= $self->model;

    return [
        grep { $_->does('DBIC') && $_->is_relationship }
        $model->meta->get_all_attributes
    ];
}

sub _dbic_fk_relationships {
    my ( $self, $model ) = @_;

    return [
        grep {
            my $type  = $_->meta->get_attribute('rel')->get_value($_);
            $type eq 'belongs_to' ? 1 : 0;
        }
        @{$self->_dbic_relationships($model)}
    ];
}

sub _populate_dbic_result {
    my ( $self ) = @_;

    for my $attr ( @{$self->_dbic_columns}, @{$self->_dbic_fk_relationships} ) {

        my $name  = $attr->name;
        my $value = $self->_value_to_db( $self->model->$name );

        $self->_dbic_result->$name( $value );
    }
}

sub _value_to_db {
    my ( $self, $value ) = @_;

        if ( ref $value eq 'ARRAY' ) {

            return [ map { $self->_value_to_db($_) } @$value ];
        }
        elsif ( blessed $value && $value->can('does') && $value->does('Model::Envoy') ) {

            my $dbic = $value->get_storage(ref $self);

            $dbic->_populate_dbic_result;
            return $dbic->_dbic_result;
        }

        return $value;
}

package MooseX::Meta::Attribute::Trait::DBIC;
use Moose::Role;
Moose::Util::meta_attribute_alias('DBIC');

use Moose::Util::TypeConstraints 'enum';

has rel => (
    is  => 'ro',
    isa => enum(['belongs_to','has_many','many_to_many']),
    predicate => 'is_relationship'
);

has mm_rel => (
    is  => 'ro',
    isa => 'Str',
    predicate => 'is_many_to_many',
);

has primary_key => (
    is  => 'ro',
    isa => 'Bool',
    predicate => 'is_primary_key'
);

package Moose::Meta::Attribute::Custom::Trait::EDBIC;
    sub register_implementation { 
        'MooseX::Meta::Attribute::Trait::DBIC'
    };

1;