#!/usr/bin/perl
# $Id$
# $Author$
# $HeadURL$
# $Date$
# $Revision$
use warnings;
use strict;
{

    package OOP::Perlish::Class::Accessor;
    our $VERSION = 0.0100;
    use warnings;
    use strict;
    use Scalar::Util qw(weaken blessed);
    use Carp qw(confess);
    use Data::Dumper;
    use OOP::Perlish::Class::Abstract; # for implementation method exclusion 

    ##########************************************************************************##########
    #!!!!!!!!! BEGIN    Inherit constructor from OOP::Perlish::Class; and overload methods associated
    #!!!!!!!!! with accessors (because we are accessors...)
    ##########************************************************************************##########

    ############################################################################################
    ## We override ____OOP_PERLISH_CLASS_REQUIRED_FIELDS, _accessors, ___inherit_accessors, and
    ## ___OOP_PERLISH_CLASS__ACCESSORS below
    ############################################################################################
    use base 'OOP::Perlish::Class';

    ############################################################################################
    ## We must override __OOP_PERLISH_CLASS__REQUIRED_FIELDS because we will not initialize required fileds
    ## via _accessors in the normal way
    ############################################################################################
    sub ____OOP_PERLISH_CLASS_REQUIRED_FIELDS
    {
        return ( [qw(name type)] );
    }

    ############################################################################################
    ## We are accessors, we cannot inherit them
    ############################################################################################
    sub ____inherit_accessors
    {
        return;
    }

    ############################################################################################
    ## We are accessors, we cannot have accessors. 
    ############################################################################################
    sub ____OOP_PERLISH_CLASS_ACCESSORS
    {
        return {};
    }

    ############################################################################################
    ## We are accessors, we cannot have accessors.
    ############################################################################################
    sub _accessors
    {
        return;
    }

    ##########************************************************************************##########
    #!!!!!!!!! END    overloads/inheritance from OOP::Perlish::Class
    ##########************************************************************************##########

    ############################################################################################
    ## get/set the value stored in this accessor.
    ############################################################################################
    sub value
    {
        my ( $self, @values ) = @_;

        if( @values && ( $self->readonly() && $self->self()->{__initialized} ) ) {
            carp( 'Cannot set ' . $self->name() . 'With ' . Dumper( \@values ) . 'Because it is readonly and we\'re already initialized' );
        }

        if(@values) {
            $self->__set_value(@values);
        }
        return $self->__get_value();
    }

    ############################################################################################
    ## determine if a value (even undef) has been set on this accessor for a specific instance
    ############################################################################################
    sub is_set
    {
        my ($self) = @_;
        return(  (defined($self->self()->{___fields}->{ $self->name() }->{_Set})) ? $self->self()->{___fields}->{ $self->name() }->{_Set} : -1 );
    }

    ############################################################################################
    ## get/set whether this should be treated as readonly after initialization
    ############################################################################################
    sub readonly
    {
        my ( $self, $readonly ) = @_;

        if( defined($readonly) && !exists( $self->{_readonly} ) ) {
            $self->{_readonly} = $readonly;
        }
        $self->{_readonly} = undef unless( $self->{_readonly} );
        return $self->{_readonly};
    }

    ############################################################################################
    ## get/set the type of the data stored in this
    ############################################################################################
    sub type
    {
        my ( $self, $type ) = @_;
        $type = uc($type);
        if($type) {
            confess("Invalid type specified") unless( $self->__valid_type_lookup($type) );

            if( !$self->{_Type} ) {
                $self->{_Type} = $type;
                $self->base_type($type);
            }
        }
        return $self->{_Type} if( defined( $self->{_Type} ) );
        return;
    }

    ############################################################################################
    ## get/set '$self' of this accessor to be used by ->validator() subroutines that need to see the class
    ## for which we are an accessor of, rather than this accessor class itself.
    ## In principal, this should only be set by the class which defines this accessor, but this is not enforced.
    ############################################################################################
    sub self
    {
        my ( $self, $class_self ) = @_;

        if( defined $class_self ) {
            confess('argument to ->self() is not a blessed reference') unless( ref($class_self) && blessed($class_self) );

            weaken($class_self);    # weaken to avoid cyclic reference leaks
            $self->{_class_self} = $class_self if( defined($class_self) );
        }
        return $self->{_class_self} if( defined( $self->{_class_self} ) );
        return;
    }

    ############################################################################################
    ## get/set the name of this accessor
    ############################################################################################
    sub name
    {
        my ( $self, $name ) = @_;

        if( defined($name) ) {
            $self->{_name} = $name;
        }
        return $self->{_name} if( defined( $self->{_name} ) );
        return;
    }

    ############################################################################################
    ## get/set whether this is a required attribute to the constructor
    ############################################################################################
    sub required
    {
        my ( $self, $required ) = @_;

        if( defined($required) ) {
            $self->{_required} = $required;
        }
        return $self->{_required} if( defined( $self->{_required} ) );
        return;
    }

    ############################################################################################
    ## get/set the default value
    ############################################################################################
    sub default    ## no critic (ProhibitBuiltinHomonyms)
    {
        my ( $self, @values ) = @_;

        if( @values && !$self->default_is_set() ) {
            $self->{_default_is_set} = 1;
            if( !defined( $values[0] ) && scalar @values == 1 ) {
                $self->{_default} = undef;
                return;
            }
            ( $self->{_default} ) = $self->reference( $self->__dereference_always(@values) );
        }
        if( defined( $self->{_default} ) ) {
            return $self->dereference( $self->{_default} );
        }

        return;
    }

    ############################################################################################
    ## Specify whether we will permit direct mutation of this reference
    ############################################################################################
    sub mutable
    {
        my ($self, $mutable) = @_;

        if(defined($mutable)) {
            $self->{_mutable} = $mutable;
        }

        if(defined($self->{_mutable})) { # && $self->type() && $self->type() =~ m/REF/i) {
            return $self->{_mutable};
        }
        return 0;
    }

    ############################################################################################
    ## Check if default value has been set
    ############################################################################################
    sub default_is_set
    {
        my ($self) = @_;

        return $self->{_default_is_set};
    }

    ############################################################################################
    ## get the basetype of either the type of this object, or the type passed as an argument
    ############################################################################################
    sub base_type
    {
        my ( $self, $type ) = @_;
        $type ||= $self->type();

        return $self->__valid_type_lookup($type) if( $self->__valid_type_lookup($type) );
    }

    ############################################################################################
    ## based on the type, and basetype of this object, dereferences (if necessary) the data
    ## so that the requester obtains what they expect.
    ############################################################################################
    sub dereference
    {
        my ( $self, $ref ) = @_;

        for( $self->type() ) {
            /REF/i && do {
                ## Re-reference with temporary storage to protect encapsulation unless defined as mutable
                if(! $self->mutable()) { 
                    /HASH/ && ref($ref) eq 'HASH' && do {
                        my %tmp = ( %{ $ref } );
                        return \%tmp;
                    };
                    /ARRAY/ && ref($ref) eq 'ARRAY' && do {
                        my @tmp = ( @{ $ref } );
                        return \@tmp;
                    };
                    /SCALAR/ && ref($ref) eq 'SCALAR' && do {
                        my $tmp = ${$ref};
                        return \$tmp;
                    };
                }
                return $ref;
            };
            /CODE/i && do {
                return $ref;
            };
            /OBJECT/ && do {
                return $ref;
            };
            /HASH/ && do {
                return %{$ref} if( ref($ref) eq 'HASH' );
            };
            /ARRAY/ && do {
                return @{$ref} if( ref($ref) eq 'ARRAY' );
            };
            /SCALAR/ && do {
                return ${$ref} if( ref($ref) eq 'SCALAR' );
            };
        }
        return $ref;
    }

    ############################################################################################
    ## based on the basetype and type of this object, created a reference to it for insertion into $self
    ############################################################################################
    sub reference
    {
        my ( $self, @stuff ) = @_;

        for( $self->type() ) {
            /^REF/ && do {
                return $stuff[0];
            };
            /CODE/i && do {
                return $stuff[0];
            };
            /GLOB/ && do {
                return $stuff[0];
            };
            /REGEXP/i && do {
                return $stuff[0];
            };
            /OBJECT/ && do {
                return $stuff[0];
            };
            /HASH/ && do {
                return { (@stuff) };
            };
            /ARRAY/ && do {
                return \@stuff;
            };
            /SCALAR/ && do {
                return \$stuff[0];
            };
        }
        return;  @stuff;
    }

    ############################################################################################
    ## set/get the validator sub-routine used for set operations of this accessor
    ############################################################################################
    sub validator
    {
        my ( $self, $validator ) = @_;

        if( $validator && ref($validator) ) {
            for( ref($validator) ) {
                /CODE/i && do {
                    return ( $self->{_Validator} = $validator );
                };
                /REGEXP/i && do {
                    return ( $self->{_Validator} = $self->__regexp_sub_factory($validator) );
                };
            }
            return ( $self->{_Validator} = sub {return} );
        }
        else {
            return $self->{_Validator};
        }
    }

    ############################################################################################
    ## get/set the classes an object must "is-a" to be valid as a value for this accessor
    ############################################################################################
    sub object_isa
    {
        my ( $self, $classes ) = @_;

        if($classes) {
            $classes = [$classes] unless( ref($classes) );
            $self->{_Object_Classes} = [ @{$classes} ];
        }
        return @{ $self->{_Object_Classes} } if( defined( $self->{_Object_Classes} ) );
    }

    ############################################################################################
    ## get/set the methods an object must "can" to be valid as a value for this accessor
    ############################################################################################
    sub object_can
    {
        my ( $self, $interfaces ) = @_;

        if($interfaces) {
            $interfaces = [$interfaces] unless( ref($interfaces) );
            $self->{_Object_Interfaces} = [ @{$interfaces} ];
        }
        return @{ $self->{_Object_Interfaces} } if( defined( $self->{_Object_Interfaces} ) );
    }

    ############################################################################################
    ## get/set the classes (packages) that an object must be like
    ############################################################################################
    sub implements
    {
        my ( $self, $classes ) = @_;

        if($classes) {
            $classes = [$classes] unless( ref($classes) );
            $self->{_Object_Implements} = [ @{$classes} ];
        }
        return @{ $self->{_Object_Implements} } if( defined( $self->{_Object_Implements} ) );
    }

    ##########************************************************************************##########
    #!!!!!!!!! Internal foo
    ##########************************************************************************##########

    ############################################################################################
    ## Lookup a type and determin if its a) valid, and b) if it has a basetype
    ############################################################################################
    sub __valid_type_lookup
    {
        my ( $self, $type ) = @_;

        my %valid_types_map = (
                                SCALAR => 'SCALARREF',
                                ARRAY  => 'ARRAYREF',
                                HASH   => 'HASHREF',
                                CODE   => 'CODEREF',
                                REF    => 'REF',
                                GLOB   => 'GLOBREF',
                                OBJECT => 'OBJECT',
                                Regexp => 'REGEXP',
                                # TODO:  CLASS  => 'CLASS',
                              );
        my %valid_types_lut = reverse %valid_types_map;

        if( exists( $valid_types_map{$type} ) ) {
            return $type;
        }
        elsif( exists( $valid_types_lut{$type} ) ) {
            return $valid_types_lut{$type};
        }
        else {
            return;
        }
    }

    ############################################################################################
    ## Verify that a value specified as a default is valid for the accessor; this allows post-validation in object instantiation
    ############################################################################################
    sub __validate_default
    {
        my ($self) = @_;

        return unless( exists( $self->{_default} ) && $self->default_is_set() );

        my @orig_values  = $self->__dereference_always( $self->{_default} );
        my @valid_values = $self->__validate( $self->{_default} );

        if( !@valid_values ) {
            confess( 'Invalid default value ' . ( (@orig_values) ? Dumper( \@orig_values ) : '`undef\'' ) . ' for field ' . $self->name() );
        }

        $self->{_default} = $self->reference(@valid_values);
        return;
    }

    ############################################################################################
    ## Jump through requisite hoops to set a value; marking _Set appropriately for is_set method
    ############################################################################################
    sub __set_value
    {
        my ( $self, @values ) = @_;

        if( @values && !( $self->readonly() && $self->self()->{__initialized} ) ) {
            ## Handle explicit setting to undef; bypass validation, bypass everything.
            $self->self()->{___fields}->{ $self->name() }->{_Set} = 1;
            if( !defined( $values[0] ) && scalar @values == 1 ) {
                $self->self()->{___fields}->{ $self->name() }->{_Value} = undef;
                return;
            }
            $self->self()->{___fields}->{ $self->name() }->{_Set} = 0 unless($self->__validate(@values));
            $self->self()->{___fields}->{ $self->name() }->{_Value} = $self->reference( $self->__validate(@values) );
        }
        return;
    }

    ############################################################################################
    ## return empty references if our type is a *REF
    ############################################################################################
    sub __appropriate_undef_value
    {
        my ($self) = @_;
        if($self->type() =~ m/REF/) {
            return $self->reference();
        }
        elsif($self->type() eq 'SCALAR') {
            return undef;
        }
        else {
            return( () );
        }
    }
 

    ############################################################################################
    ## Jump through requisite hoops to obtain a value; either set or default
    ############################################################################################
    sub __get_value
    {
        my ($self) = @_;

        if($self->is_set() == 1 ) {
            if( ! defined( $self->self()->{___fields}->{ $self->name() }->{_Value} ) ) {
                return $self->__appropriate_undef_value();
            } else { 
                return $self->dereference( $self->self()->{___fields}->{ $self->name() }->{_Value} );
            }
        }
        elsif( $self->is_set() == 0 ) {
            return $self->__appropriate_undef_value();
        }
        elsif( $self->is_set() == -1 && ! $self->default_is_set() ) {
            return $self->__appropriate_undef_value();
        }
        elsif( $self->default_is_set() ) {
            return $self->__appropriate_undef_value() unless(defined( $self->default() ) );
            return $self->default();
        }
        return $self->reference();
    }


    ############################################################################################
    ## Perform the extra validation required of objects (polymorphism/inheritance)
    ############################################################################################
    sub __validate_obj_type
    {
        my ( $self, $thing ) = @_;

        return unless( ref($thing) );
        return unless( blessed($thing) );

        if( $self->object_isa() ) {
            for my $class ( $self->object_isa() ) {
                return unless( $thing->isa($class) );
            }
        }
        if( $self->object_can() ) {
            for my $method ( $self->object_can() ) {
                return unless( $thing->can($method) );
            }
        }
        if( $self->implements() ) {
            for my $class ( $self->implements() ) {
                return unless( $self->__validate_class_implementation( $class, $thing ) );
            }
        }
        return 1;
    }

    ############################################################################################
    ## Verify that a class implements interfaces (excluding interfaces from OOP::Perlish::Class itself)
    ############################################################################################
    sub __validate_class_implementation
    {
        my ( $self, $class, $thing ) = @_;

        my @interfaces;

        no strict 'refs';
        if( scalar keys %{ '::' . $class . '::' } == 0 ) {
            eval "require $class";
            confess("$@") if("$@");
        }
        use strict;

        ### XXX: Hash slice assignment for lookup
        my %oop_perlish_class_interfaces;
        @oop_perlish_class_interfaces{ OOP::Perlish::Class::Abstract->new()->_all_methods() } = undef;

        my $class_ref = bless( {}, $class );

        if( $class_ref->can('_all_methods') ) {
            @interfaces = grep { ! exists( $oop_perlish_class_interfaces{$_} ) } $class_ref->_all_methods();
        }
        else {
            @interfaces = grep { ! exists( $oop_perlish_class_interfaces{$_} ) } $self->_all_methods($class);
        }
        confess("No interfaces from $class") unless(@interfaces);

        for my $method (@interfaces) {
            return unless( $thing->can($method) );
        }
        return 1;
    }

    ############################################################################################
    ## Verify that the underlying type of a reference is correct for the type of this accessor
    ############################################################################################
    sub __validate_ref_type
    {
        my ( $self, $thing ) = @_;

        if( $self->type() eq 'OBJECT' ) {
            return unless( $self->__validate_obj_type($thing) );
        }
        else {
            return unless( ref($thing) eq $self->base_type() );
        }
        return 1;
    }

    ############################################################################################
    ## Validate that the type of the thing passed to this object is a valid type for our storage.
    ############################################################################################
    sub __validate_type
    {
        my ( $self, @values ) = @_;

        ## Don't validate_ref_type for REF type (backwards sounding I know; but if we are a REF type, we don't care about the underlying _type_)
        ## We also cannot fail an array, unfortunately, because it could be an array containing one member, a reference to something...
        if( ( ref( $values[0] ) && scalar(@values) == 1 ) && $self->type() !~ m/(?:^REF|ARRAY)/ ) {
            return unless( $self->__validate_ref_type( $values[0] ) );
        }

        if( $self->type() =~ m/REF|CODE|REGEXP|OBJECT/ && $self->type() !~ m/(?:^REF|SCALAR|ARRAY|HASH)/ ) {
            return unless( $self->__validate_ref_type( $values[0] ) && scalar(@values) == 1 );
        }

        for( $self->type() ) {
            /^REF/ && do { return unless( scalar @values == 1 && ref( $values[0] ) ); };
            /HASH/ && do { return unless( scalar @values % 2 == 0 || ref( $values[0] ) eq 'HASH' ); };
            /SCALAR/ && do { return unless( scalar @values == 1 ); };
            /GLOB/ && do { return unless( scalar @values == 1 && ref( $values[0] ) eq 'GLOB' ) };
        }

        return 1;
    }

    ############################################################################################
    ## Test the validity of data using the validator of this accessor
    ############################################################################################
    sub __validate
    {
        my ( $self, @values ) = @_;

        return unless(@values);
        return unless( $self->__validate_type(@values) );

        if( defined( $self->validator() ) ) {
            return $self->validator()->( $self->self(), $self->__dereference_always(@values) );
        }
        else {
            return $self->__dereference_always(@values);
        }
    }

    ############################################################################################
    ## This will indescriminately dereference a type to its base type; it is used because it simplifies validation
    ############################################################################################
    sub __dereference_always
    {
        my ( $self, @input ) = @_;

        my @values = ();

        if( scalar @input == 1 && ref( $input[0] ) && ref( $input[0] ) eq $self->base_type() ) {
            my $tmp_type = $self->type();
            my $buf_type = $self->base_type();

            $self->{_Type} = $buf_type;
            @values        = $self->dereference( $input[0] );
            $self->{_Type} = $tmp_type;
        }
        else {
            @values = @input;
        }
        return @values;
    }

    ############################################################################################
    ## Return a subroutine which will correctly validate via regexp the data of the specified type.
    ############################################################################################
    sub __regexp_sub_factory
    {
        my ( $self, $regexp ) = @_;

        my $possible_method;
        $possible_method = '__regexp_sub_impl_' . lc( $self->type() );

        if( $self->can($possible_method) ) {
            return $self->$possible_method($regexp);
        }

        $possible_method = '__regexp_sub_impl_' . lc( $self->base_type() );
        if( $self->can($possible_method) ) {
            return $self->$possible_method($regexp);
        }
        return sub {return};
    }

    ############################################################################################
    ## "free" regexp subroutine for hashes
    ############################################################################################
    sub __regexp_sub_impl_hash
    {
        my ( $self, $regexp ) = @_;

        return sub {
            my ( $this, %args ) = @_;

            my $re         = $regexp;
            my %valid_args = ();
            return unless( keys %args );
            while( my ( $key, $val ) = each %args ) {
                $val =~ /($re)/ && do {
                    $valid_args{$key} = $1;
                  }
            }
            return %valid_args if( scalar keys %args == scalar keys %valid_args );
            return;
        };
    }

    ############################################################################################
    ## "free" regexp subroutine for arrays
    ############################################################################################
    sub __regexp_sub_impl_array
    {
        my ( $self, $regexp ) = @_;

        return sub {
            my ( $this, @args ) = @_;

            my $re         = $regexp;
            my @valid_args = ();
            return unless(@args);
            for(@args) {
                return unless( defined($_) );
                /($re)/x && do {
                    push @valid_args, $1;
                };
            }
            return @valid_args if( scalar @args == scalar @valid_args );
            return;
        };
    }

    ############################################################################################
    ## "free" regexp subroutine for scalar
    ############################################################################################
    sub __regexp_sub_impl_scalar
    {
        my ( $self, $regexp ) = @_;

        return sub {
            my ( $this, $arg ) = @_;
            my $re        = $regexp;
            my $valid_arg = undef;

            return unless( defined($arg) );
            $arg =~ m/($re)/ && do {
                $valid_arg = $1;
                return unless( defined($valid_arg) );
                return $valid_arg;
            };
            return;
        };
    }

    ############################################################################################
    ## "free" regexp subroutine for objects (uses ref for string representation)
    ############################################################################################
    sub __regexp_sub_impl_object
    {
        my ( $self, $regexp ) = @_;

        return sub {
            my ( $this, $obj ) = @_;

            return unless( defined $obj );
            return $obj if( ref($obj) =~ m/$regexp/ );
            return;
        };
    }
}
1;
__END__

=head1 NAME

=head1 VERSION

=head1 SYNOPSIS

=head1 METHODS

=head2 Accessor definition methods

=over

=item default

Get/set the accessor's default value

=item implements

Get/set required methods for an object to be considered valid; this is different from "object_can" in that it takes class names to source for method names rather than requiring you to specify the interfaces explicitely.

=item mutable

Get/Set whether or not the returned reference should be mutable or not.

=item name

Get/Set the name of this accessor

=item object_can

Get/set required methods for an object to be considered valid; this is different from "implements" in that you must explicitely list method names.

=item object_isa

Get/set required parent classes for an object to be considered valid.

=item readonly

Get/set boolean for whether or not the accessor shall be considered read-only after initialization has completed.

=item required

Get/set boolean for whether or not the accessor is required to have a (valid) value passed to the constructor.

=item self

Get/set a reference to the object on which this accessor object is associated.

=item type

Get/set the type of value this accessor will handle.

=item validator

Get/set a validation regular expression or subroutine.

=item value

Get/set the value for the currently defined $self instance of this accessor.

=back

=head2 Utilities and meta-data methods

=over

=item default_is_set

Get boolean value of whether or not a default value has been set.

=item dereference

Dereference a value by type

=item base_type

Get the accessors base type

=item is_set

Get boolean value of whether or not a value (even undef) has been set on this accessor

=item reference

Get a reference to the type of object.

=back

=head1 AUTHOR

Jamie Beverly, C<< <jbeverly at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-foo-bar at rt.cpan.org>,
or through
the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=OOP-Perlish-Class>.  I will be
notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc OOP::Perlish::Class


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=OOP-Perlish-Class>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/OOP-Perlish-Class>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/OOP-Perlish-Class>

=item * Search CPAN

L<http://search.cpan.org/dist/OOP-Perlish-Class/>

=back


=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2009 Jamie Beverly

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
