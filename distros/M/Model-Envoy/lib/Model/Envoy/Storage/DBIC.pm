package Model::Envoy::Storage::DBIC;

our $VERSION = '0.1.1';

=head1 Model::Envoy::Storage::DBIC

A Moose Role that adds a DBIx::Class persistence layer to your Moose class

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

=head2 Required Methods

There are two methods you will need to implement in a class that uses this role:

=head3 dbic()

This should return the name of the DBIx::Class ResultClass that your Model
uses for database storage.

=head3 _schema()

This must return a DBIx::Class schema object for other methods to use when
communicating with your database.

=cut

use Moose::Role;
use Scalar::Util 'blessed';

# The name of the DBIx::Class ResultClass is stored here:
requires 'dbic';

# Model needs to provide its own connection to the database:
requires '_schema';

# The actual ResultClass for the model object is stored here:
has '_dbic_result',
    is      => 'rw',
    isa     => 'Maybe[Object]',
    lazy    => 1,
    default => sub {
        my ( $self ) = @_;

        return $self->_schema->resultset( $self->dbic )->new({});
    };

=head2 Methods

=head3 new_from_db( $dbic_result, [$no_rel] )

Takes a DBIx::Class result object and, if it's class matches your class's dbic()
method, attempts to build a new instance of your class based on the $dbic_result
passed in.

The `no_rel` boolean option prevents the creation process from traversing
attributes marked as relationships, minimizing the amount of data pulled
from the database and the number of new class instances created.

Returns the class instance if successful.

=cut

sub new_from_db {
    my ( $class, $db_result, $no_rel ) = @_;

    return undef unless $db_result;

    die "cannot create a $class from a $db_result"
        unless blessed $db_result && $db_result->isa( $class->dbic );

    my $data  = {};

    my %relationships = map { $_->name => 1 } @{$class->_dbic_relationships};

    foreach my $attr ( grep { defined $db_result->$_ } map { $_->name } @{$class->_dbic_attrs} ) {

        next if $no_rel && exists $relationships{$attr};

        if ( blessed $db_result->$attr && $db_result->$attr->isa('DBIx::Class::ResultSet') ) {

            my $attribute  = $class->meta->find_attribute_by_name($attr);
            my $class_attr = $attribute->meta->find_attribute_by_name('moose_class');
            my $factory    = $class_attr ? $class_attr->get_value($attribute) : undef;

            $factory ||= ( $attribute->type_constraint->name =~ / (?:ArrayRef|Maybe) \[ (.+?) \] /x )[0];

            if ( $factory ) {

                $data->{$attr} = [ map { $factory->new_from_db( $_, 1 ) } $db_result->$attr ];
            }
        }
        else {
            $data->{$attr} = $db_result->$attr;
        }

    }

    return $class->new( _dbic_result => $db_result, %$data );
}

=head3 db_save()

Performs either an insert or an update for the model, depending on whether
there is already a record for it in the database.

Returns the calling object for convenient chaining.

=cut

sub db_save {
    my ( $self ) = @_;

    my $dbic_result = $self->_dbic_result;

    $self->_schema->txn_do( sub {

        # First update/insert non-relationships
        $self->_populate_dbic_result;

        if ( $dbic_result->in_storage ) {
            $dbic_result->update;
        }
        else {
            $dbic_result->insert;
        }

        # Then, once we're sure the record exists, update relationships
        for my $attr ( @{$self->_dbic_relationships} ) {

            $self->_db_save_relationship( $attr );
        }

        $dbic_result->update;

    });

    return $self;
}

sub _db_save_relationship {
    my ( $self, $attr ) = @_;

    my $dbic_result = $self->_dbic_result;

    my $name  = $attr->name;
    my $type  = $attr->meta->get_attribute('rel')->get_value($attr);
    my $value = $self->_value_to_db( $self->$name );

    if ( $type eq 'many_to_many' ) {
        my $setter = 'set_' . $name;
        $dbic_result->$setter( $value );
    }
    elsif ( $type eq 'has_many' ) {

        $dbic_result->find_or_create_related( $name => $_ )
            foreach ( map { { $_->get_columns } } @$value );
    }
    else {
        $dbic_result->set_from_related( $name => $value );
    }
}

=head3 db_delete()

Deletes the persistent copy of the current model from the database, if has
been stored there.

Returns nothing.

=cut

sub db_delete {
    my ( $self ) = @_;

    if ( $self->_dbic_result->in_storage ) {
        $self->_dbic_result->delete;
    }

    return;
}

=head3 in_storage()

Uses DBIx::Class's internal mechanisms to determine if this model
is tied to a record in the database.

Returns a true value if it is, otherwise returns a false value.

=cut

sub in_storage {
    my ( $self ) = @_;

    return $self->_dbic_result->in_storage;
}

sub _dbic_attrs {
    my ( $self ) = @_;

    return [
        grep { $_->does('DBIC') }
        $self->meta->get_all_attributes
    ];
}

sub _dbic_columns {
    my ( $self ) = @_;

    return [
        grep { $_->does('DBIC') && ! $_->is_relationship }
        $self->meta->get_all_attributes
    ];
}

sub _dbic_relationships {
    my ( $self ) = @_;

    return [
        grep { $_->does('DBIC') && $_->is_relationship }
        $self->meta->get_all_attributes
    ];
}

sub _populate_dbic_result {
    my ( $self ) = @_;

    for my $attr ( @{$self->_dbic_columns} ) {

        my $name  = $attr->name;
        my $value = $self->_value_to_db( $self->$name );

        $self->_dbic_result->$name( $value );
    }
}

sub _value_to_db {
    my ( $self, $value ) = @_;

        if ( ref $value eq 'ARRAY' ) {

            return [ map { $self->_value_to_db($_) } @$value ];
        }
        elsif ( blessed $value && $value->can('does') && $value->does('Model::Envoy::Storage::DBIC') ) {

            $value->_populate_dbic_result;
            return $value->_dbic_result;
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