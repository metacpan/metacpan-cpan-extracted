package StateML::Object ;

use strict ;
use Carp qw( confess );

=head1 METHODS

=over

=cut

=item new

    $self->new( attr => "val", ... ) ;

Create a new object.

=cut

sub new {
    my $proto = shift ;
    my $class = ref $proto || $proto ;
    my $self = bless {
        @_,
    }, $class ;
    return $self ;
}


=item type

    $obj->type ;

Returns "MACHINE", "STATE", "ARC", "EVENT".

=cut


sub type {
    my $self = shift ;

    my $type = uc ref $self ;
    $type =~ s/.*:// ;
    return $type ;
}


sub _generate_id {
    my $self = shift ;
    my $class = ref $self ;
    no strict 'refs' ;
    $self->id( $self->type . " " . ++${"$class\::ID_COUNTER"} ) ;
}


=item class_ids

A list of class ids this class inherits from.

To set the list, this method takes a list of strings, each of which should
be one or more class_ids separated by a comma.  Trailing commas are allowed.

=cut

sub class_ids {
    my $self = shift;
    $self->{CLASS_IDS} = [ grep length, map split( /,/ ), @_ ] if @_;
    return unless $self->{CLASS_IDS};
    return @{$self->{CLASS_IDS}};
}


=item id

    $obj->id( "foo" ) ;
    $id = $obj->id ;

Returns the id string.  Creates a new unique one if not defined.

The id "" is not valid.

=cut

sub id {
    my $self = shift ;
    $self->{ID} = shift if @_ ;
    return unless defined wantarray;
    $self->_generate_id unless defined $self->{ID} ;
    confess "invalid id ''" unless length $self->{ID};
    return $self->{ID} ;
}


=item name

    $obj->name( "foo" ) ;
    $id = $obj->name ;

Returns the name string or the id string if the name is unset.
The name "" is valid.

The name is used for human readable documentation purposes, the id is
used for internal linking and for generated code.  The name is merely
a comment with semantic value.

=cut

sub name {
    my $self = shift ;
    $self->{NAME} = shift if @_ ;
    return defined $self->{NAME}
       ? $self->{NAME}
       : $self->id;
}


=item enum_id

    $enum_id = $obj->enum_id ;

Returns the same string as $obj->id, but cleaned up sufficiently to be
used in a C "enum" statement.

=cut

sub enum_id {
    my $self = shift ;
    my $oid = $self->id ;
    for ( $oid ) {
        $_ = "_$_" if /^[^a-zA-Z_]/ ;
        s/[^a-zA-Z0-9_]+/_/g ;
    }
    return $oid ;
}


=item machine

    $obj->machine( $machine ) ;
    $m = $obj->machine ;

Sets/gets the StateML::Machine object this object is a part of.

=cut

sub machine {
    my $self = shift ;
    $self->{MACHINE} = shift if @_ ;
    return $self->{MACHINE} ;
}


=item attribute

    $attr = $obj->attribute( $namespace_uri, $name ) ;

Returns the attribute identified by the XML namespace prefix and name.

    $attr = $obj->attribute( $namespace_uri, $name, $value ) ;

The namespace_uri is the XML concept of namespace identifier.

Checks up the class hierarchy if an attribute is not defined.

=cut

#If there is no attribute named "{$namespace_uri}$name", returns
#an attribute named $name if that exists.  Returns undef otherwise.

sub attribute {
    my $self = shift ;
    my ( $namespace_uri, $name, $value ) = @_ ;

    my $key = "{$namespace_uri}$name" ;
    my $a = $self->{ATTRS} ;
    if ( @_ == 3 ) {
        if ( defined $value ) {
            $a->{$key} = $value ;
        }
        else {
            delete $a->{$key} ;
        }
    }
    return $a->{$key}  if exists $a->{$key} && defined $a->{$key} ;

    for ( $self->class_ids ) {
        my $attr = $self->machine->object_by_id( $_ )->attribute( @_[0,1] );
        return $attr if defined $attr;
    }

    return undef ;
}

=item attributes

    %attrs = $obj->attributes( $namespace_uri );
    %attrs = $obj->attributes;

If a namespace URI is passed, returns attributes in that namespace and
no others with the localname of the attribute as the key (ie without the
namespace URI).

If no namespace URI is passed, returns all attributes with the URI encoded
in jclark notation.

Compiles a list of all attributes from the class hierarchy.

=cut

sub attributes {
    my $self = shift ;
    my ( $namespace_uri ) = @_ ;
    my $a = $self->{ATTRS} ;

    my %inherited_attrs = map {
            my $base_class = $self->machine->object_by_id( $_ );
            confess "base class $_ not found ", $self->{LOCATION}
                unless $base_class;
            $base_class->attributes( @_ );
        } $self->class_ids;

    if ( ! defined $namespace_uri ) {
        return ( %inherited_attrs, %$a );
    }

    $namespace_uri = "{$namespace_uri}" ;
    my $l = length $namespace_uri;
    return (
        %inherited_attrs,
        (
            map {
                my $name = substr( $_, $l ) ;
                ( $name => $a->{$_} ) ;
            } grep 0 == index( $_, $namespace_uri ), keys %$a
        ),
    );
}

=back

=cut


1 ;
