package Model::Envoy;

use Moose::Role;

our $VERSION = '0.1';

=head1 Model::Envoy

A Moose Role that can be used to build a model layer that keeps business logic separate from your storage layer.

=head2 Synopsis

    package My::Envoy::Widget;

        use Moose;
        with 'Model::Envoy';

        use My::DB;

        sub dbic { 'My::DB::Result::Widget' }

        my $schema;

        sub _schema {
            $schema ||= My::DB->db_connect(...);
        }

        has 'id' => (
            is => 'ro',
            isa => 'Num',
            traits => ['DBIC'],
            primary_key => 1,

        );

        has 'name' => (
            is => 'rw',
            isa => 'Maybe[Str]',
            traits => ['DBIC'],
        );

        has 'no_storage' => (
            is => 'rw',
            isa => 'Maybe[Str]',
        );

        has 'parts' => (
            is => 'rw',
            isa => 'ArrayRef[My::Envoy::Part]',
            traits => ['DBIC','Envoy'],
            rel => 'has_many',
        );

    package My::Envoy::Models;

    use Moose;
    with 'Model::Envoy::Set';

    sub namespace { 'My::Envoy' }


    ....then later...

    my $widget = My::Envoy::Models->m('Widget')->build({
        id => 1
        name => 'foo',
        no_storage => 'bar',
        parts => [
            {
                id => 2,
                name => 'baz',
            },
        ],
    })


=head2 Traits

=head3 DBIC

See `Model::Envoy::Storage::DBIC`;

=head3 Envoy

This trait is handy for class attributes that represent other Model::Envoy
enabled classes (or arrays of them).  It will allow you to pass in hashrefs
(or arrays of hashrefs) to those attributes and have them automagically elevated
into an instance of the intended class.

=head2 Methods

=head3 save()

Save the instance to your persistent storage layer.

=cut


with 'Model::Envoy::Storage::DBIC';

sub save {
    my ( $self ) = @_;

    $self->db_save;

    return $self;
}

=head3 update($hashref)

Given a supplied hashref of attributes, bulk update the attributes of your instance object.

=cut

sub update {
    my ( $self, $hashref ) = @_;

    foreach my $attr ( $self->_get_all_attributes ) {

        my $name = $attr->name;

        if ( exists $hashref->{$name} ) {

            $self->$name( $hashref->{$name} );
        }
    }

    return $self;
}

=head3 delete()

Remove the instance from your persistent storage layer.

=cut

sub delete {
    my ( $self ) = @_;

    $self->db_delete();

    return 1;
}

=head3 dump()

Provide an unblessed copy of the datastructure of your instance object.

=cut

sub dump {
    my ( $self ) = @_;

    return {
        map  { $_ => $self->_dump_property( $self->$_ ) }
        grep { defined $self->$_ }
        map  { $_->name }
        $self->_get_all_attributes
    };
}

sub _dump_property {
    my ( $self, $value ) = @_;

    return $value if ! ref $value;

    return [ map { $self->_dump_property($_) } @$value ] if ref $value eq 'ARRAY';

    return { map { $_ => $self->_dump_property( $value->{$_} ) } keys %$value } if ref $value eq 'HASH';

    return $value->dump if $value->can('does') && $value->does('Model::Envoy');

    return undef;
}

sub _get_all_attributes {
    my ( $self ) = @_;

    return grep { $_->name !~ /^_/ } $self->meta->get_all_attributes;
}

package Model::Envoy::Meta::Attribute::Trait::Envoy;
use Moose::Role;
Moose::Util::meta_attribute_alias('Envoy');

use Moose::Util::TypeConstraints;

has moose_class => (
    is  => 'ro',
    isa => 'Str',
);

around '_process_options' => sub { _install_types(@_) };

sub _install_types {
    my ( $orig, $self, $name, $options ) = @_;

    return unless grep { $_ eq __PACKAGE__ } @{$options->{traits} || []};

    unless( find_type_constraint('Array_of_Hashref') ) {

        subtype 'Array_of_HashRef',
            as 'ArrayRef[HashRef]';
    }
    unless ( find_type_constraint('Array_of_Object') ) {

        subtype 'Array_of_Object',
            as 'ArrayRef[Object]';
    }
    if ( $options->{isa} =~ / ArrayRef \[ (.+?) \]/x ) {
        $options->{moose_class} = $1;
        $options->{isa} = $self->_coerce_array($1);
    }
    elsif( $options->{isa} =~ / Maybe  \[ (.+?) \]/x ) {
        $options->{moose_class} = $1;
        $options->{isa} = $self->_coerce_maybe($1);
    }
    else {
        $self->_coerce_class($options->{isa});
    }

    $options->{coerce} = 1;

    return $self->$orig($name,$options);
}

sub _coerce_array {
    my ( $self, $class ) = @_;

    my $type = ( $class =~ / ( [^:]+ ) $ /x )[0];

    unless( find_type_constraint("Array_of_$type") ) {

        subtype "Array_of_$type",
            as "ArrayRef[$class]";

        coerce   "Array_of_$type",
            from "Array_of_Object",
            via  { [ map { $class->new_from_db($_) } @{$_} ] },

            from 'Array_of_HashRef',
            via  { [ map { $class->new($_) } @{$_} ] };
    }

    return "Array_of_$type";
}

sub _coerce_maybe {
    my ( $self, $class ) = @_;
    my $type = ( $class =~ /\:\:([^:]+)$/ )[0];

    unless( find_type_constraint("Maybe_$type") ) {

        subtype "Maybe_$type",
            as "Maybe[$class]";

        coerce   "Maybe_$type",
            from 'Object',
            via  { $class->new_from_db($_) },

            from 'HashRef',
            via { $class->new($_) };
    }

    return "Maybe_$type";
}

sub _coerce_class {
    my ( $self, $class ) = @_;
    my $type = ( $class =~ /\:\:([^:]+)$/ )[0];

    coerce   $class,
        from 'Object',
        via  { $class->new_from_db($_) },

        from 'HashRef',
        via { $class->new($_) };
}

package Moose::Meta::Attribute::Custom::Trait::Envoy;
    sub register_implementation {
        'MooseX::Meta::Attribute::Trait::Envoy'
    };

1;