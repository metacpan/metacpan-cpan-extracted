##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Generic.pm
## Version v0.100.2
## Copyright(c) 2020 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <@sitael.tokyo.deguest.jp>
## Created 2019/11/02
## Modified 2020/05/16
## 
##----------------------------------------------------------------------------
package Net::API::Stripe::Generic;
BEGIN
{
	use strict;
	use parent qw( Module::Generic );
	use Net::API::Stripe;
	use TryCatch;
    use Devel::Confess;
    use Want;
    our( $VERSION ) = 'v0.100.2';
};

sub init
{
    my $self = shift( @_ );
    ## Get the init params always present and including keys like _parent and _field
    my $init = shift( @_ );
    $self->{_parent} = $init->{_parent};
    $self->{_field} = $init->{_field};
    $self->{_error} = '';
    $self->{debug} = $init->{_debug};
    $self->{_dbh} = $init->{_dbh} if( exists( $init->{_dbh} ) && $init->{_dbh} );
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ );
    return( $self );
}

sub field { return( shift->_set_get_scalar( '_field', @_ ) ); }

sub parent { return( shift->_set_get_scalar( '_parent', @_ ) ); }

sub TO_JSON
{
    my $self = shift( @_ );
    return( $self->can( 'as_string' ) ? $self->as_string : $self );
}

# Used in Net::API::Stripe::Payment::Source and Net::API::Stripe::Connect::ExternalAccount::Card
sub _address_populate
{
	my $self = shift( @_ );
	my $addr = shift( @_ ) || return;
	## No 'state' property
	my $map =
	{
	line1 => 'line1',
	line2 => 'line2',
	city => 'city',
	state => 'state',
	postal_code => 'zip',
	country => 'country',
	};
	if( $self->_is_hash( $addr ) )
	{
		foreach my $k ( keys( %$map ) )
		{
			next unless( exists( $addr->{ $k } ) && length( $addr->{ $k } ) );
			my $sub = "address_" . $map->{ $k };
			$self->$sub( $addr->{ $k } );
		}
	}
	elsif( $self->_is_object( $addr ) && $addr->isa( 'Net::API::Stripe::Address' ) )
	{
		foreach my $k ( keys( %$map ) )
		{
			next unless( exists( $addr->{ $k } ) && length( $addr->{ $k } ) );
			my $sub = "address_" . $map->{ $k };
			$self->$sub( $addr->$k );
		}
	}
	else
	{
		return( $self->error( "I do not know what to do with '$addr'. I was expecting either a Net::API::Strie::Address or an hash reference." ) );
	}
}

sub _convert_measure
{
	my $self = shift( @_ );
	my $p = shift( @_ );
	my $num = $p->{value};
	return if( !length( $num ) );
	return( $self->error( "No \"from\" parameter was provided to convert number \"$num\"." ) ) if( !length( $p->{from} ) );
	my $inch_to_cm = 2.54;
	my $cm_to_inch = 0.39370078740157;
	my $ounce_to_gram = 28.34952;
	my $gram_to_ounce = 0.03527396583787;
	if( lc( $p->{from} ) eq 'inch' )
	{
		return( $num / $inch_to_cm );
	}
	elsif( lc( $p->{from} ) eq 'cm' || lc( $p->{from} ) eq 'centimetre' )
	{
		return( $num / $cm_to_inch );
	}
	elsif( lc( $p->{from} ) eq 'ounce' )
	{
		return( $num / $ounce_to_gram );
	}
	elsif( lc( $p->{from} ) eq 'gram' )
	{
		return( $num / $gram_to_ounce );
	}
	else
	{
		return( $self->error( "I do not know how to convert from \"$p->{from}\"" ) );
	}
}

sub _get_base_class
{
    my $self  = shift( @_ );
    my $class = shift( @_ );
    my $base  = __PACKAGE__;
    $base =~ s/\:\:Generic$//;
    my $pkg = ( $class =~ /^($base\:\:(?:[^\:]+)?)/ )[0];
}

## Overriding Module::Generic
sub _instantiate_object
{
	my $self = shift( @_ );
	my $field = shift( @_ );
	return( $self->{ $field } ) if( exists( $self->{ $field } ) && Scalar::Util::blessed( $self->{ $field } ) && !$self->_is_array( $self->{ $field } ) );
	my $class = shift( @_ );
	my $this;
	my $h = 
	{
		'_parent' => $self->{_parent},
		'_field' => $field,
		'_debug' => $self->{debug},
	};
	$h->{_dbh} = $self->{_dbh} if( $self->{_dbh} );
	my $o;
	try
	{
		## https://stackoverflow.com/questions/32608504/how-to-check-if-perl-module-is-available#comment53081298_32608860
		# my $class_file = join( '/', split( /::/, $class ) ) . '.pm';
		## if( CORE::exists( $INC{ $class_file } ) || defined( *{"${class}::"} ) )
		# if( Class::Load::is_class_loaded( $class ) )
# 		if( defined( ${"${class}::VERSION"} ) || scalar( @{"$class::ISA"} ) )
# 		{
# 			$self->message( 3, "Module $class seems to be already loaded." );
# 		}
# 		else
# 		{
# 			my $rc = eval( "require $class;" );
# 			$self->message( 3, "Tried to load $class and got returned value $rc" );
# 		}
		my $rc = eval{ $self->_load_class( $class ); };
		# print( STDERR __PACKAGE__, "::_instantiate_object(): Error while loading module $class? $@\n" );
		# $self->message( 3, "Error while loading module $class? $@" );
		return( $self->error( "Unable to load module $class: $@" ) ) if( $@ );
		if( $class->isa( 'Module::Generic::Dynamic' ) )
		{
			$o = @_ ? $class->new( @_ ) : $class->new;
			$o->{debug} = $self->{debug};
			$o->{_parent} = $self->{_parent};
			$o->{_field} = $field;
		}
		else
		{
			$o = @_ ? $class->new( $h, @_ ) : $class->new( $h );
		}
		return( $self->pass_error( "Unable to instantiate an object of class $class: ", $class->error ) ) if( !defined( $o ) );
	}
	catch( $e ) 
	{
		return( $self->error({ code => 500, message => $e }) );
	}
	return( $o );
}

sub _object_type_to_class
{
	my $self = shift( @_ );
	my $type = shift( @_ ) || return( $self->error( "No object type was provided" ) );
	my $ref  = $Net::API::Stripe::TYPE2CLASS;
	$self->messagef( 3, "\$TYPE2CLASS has %d elements", scalar( keys( %$ref ) ) );
	return( $self->error( "No object type '$type' known to get its related class for field $self->{_field}" ) ) if( !exists( $ref->{ $type } ) );
	return( $ref->{ $type } );
}

sub _set_get_hash
{
	my $self = shift( @_ );
	my $field = shift( @_ );
	my $o;
	if( @_ || !$self->{ $field } )
	{
		my $class = $field;
		$class =~ tr/-/_/;
		$class =~ s/\_{2,}/_/g;
		$class = ref( $self ) . '::' . join( '', map( ucfirst( lc( $_ ) ), split( /\_/, $class ) ) );
		# require Devel::StackTrace;
		# my $trace = Devel::StackTrace->new;
		# $self->message( 3, "Called for field '$field' with arguments: '", join( "', '", @_ ), "' and trace ", $trace->as_string );
		$o = $self->_set_get_hash_as_object( $field, $class, @_ );
		$o->debug( $self->debug );
		$self->{ $field } = $o;
	}
	$o = $self->{ $field };
	if( want( 'OBJECT' ) )
	{
		return( $o );
	}
	my $hash = $o->{_data};
	return( $hash );
}

## Overiden
sub _set_get_number
{
    my $self  = shift( @_ );
    my $field = shift( @_ );
    if( @_ )
    {
    	$self->{ $field } = Module::Generic::Number->new( shift( @_ ) );
    }
    return( $self->{ $field } );
}

sub _set_get_object_array
{
    my $self  = shift( @_ );
    my $field = shift( @_ );
    my $class = shift( @_ );
    @_ = () if( scalar( @_ ) == 1 && !defined( $_[0] ) );
    if( @_ )
    {
    	my $ref = shift( @_ );
    	return( $self->error( "I was expecting an array ref, but instead got '$ref'" ) ) if( !$self->_is_array( $ref ) );
    	my $arr = [];
    	for( my $i = 0; $i < scalar( @$ref ); $i++ )
    	{
    		# $self->message( 3, "Instantiate object from class \"$class\" with value $ref->[$i]" );
			my $o = defined( $ref->[$i] ) ? $self->_instantiate_object( $field, $class, $ref->[$i] ) : $self->_instantiate_object( $field, $class );
			return( $self->error( "Unable to instantiate an object of class $class: ", $class->error ) ) if( !defined( $o ) );
			# $self->message( 3, "Adding object \"$o\" to the resulting stack." );
			push( @$arr, $o );
    	}
    	$self->{ $field } = $arr;
    }
	return( $self->{ $field } );
}

sub _set_get_object_variant
{
	my $self = shift( @_ );
    my $field = shift( @_ );
    ## The class precisely depends on what we find looking ahead
    ## my $class = shift( @_ );
	if( @_ )
	{
		local $process = sub
		{
			my $ref = shift( @_ );
			my $type = $ref->{object} || return( $self->error( "No object type could be found in hash: ", sub{ $self->_dumper( $ref ) } ) );
			my $class = $self->_object_type_to_class( $type );
			$self->message( 3, "Object type $type has class $class" );
			my $o = $self->_instantiate_object( $field, $class, $ref );
			$self->{ $field } = $o;
			## return( $class->new( %$ref ) );
			## return( $self->_set_get_object( 'object', $class, $ref ) );
		};
		
		if( ref( $_[0] ) eq 'HASH' )
		{
			my $o = $process->( @_ ) 
		}
		## AN array of objects hash
		elsif( ref( $_[0] ) eq 'ARRAY' )
		{
			my $arr = shift( @_ );
			my $res = [];
			foreach my $data ( @$arr )
			{
				my $o = $process->( $data ) || return( $self->error( "Unable to create object: ", $self->error ) );
				push( @$res, $o );
			}
			$self->{ $field } = $res;
		}
	}
	return( $self->{ $field } );
}

sub _set_get_scalar_or_object_variant
{
    my $self  = shift( @_ );
    my $field = shift( @_ );
    if( @_ )
    {
    	if( ref( $_[0] ) eq 'HASH' || ref( $_[0] ) eq 'ARRAY' )
    	{
    		return( $self->_set_get_object_variant( $field, @_ ) );
    	}
    	else
    	{
    		return( $self->_set_get_scalar( $field, @_ ) );
    	}
    }
	if( !$self->{ $field } && want( 'OBJECT' ) )
	{
		my $null = Module::Generic::Null->new( $o, { debug => $self->{debug}, has_error => 0 });
		rreturn( $null );
	}
	return( $self->{ $field } );
}

sub _set_get_uri
{
    my $self  = shift( @_ );
    my $field = shift( @_ );
    if( @_ )
    {
		my $str = $self->SUPER::_set_get_uri( $field, @_ );
		# $self->message( 3, "URI is $str, making it absolute." );
		if( defined( $str ) && Scalar::Util::blessed( $str ) )
		{
			$self->{ $field } = $str->abs( $self->_parent->api_uri );
			# $self->message( 3, "URI is now ", $self->{ $field } );
		}
    }
    return( $self->{ $field } );
}

sub _will { return( shift->SUPER::will( @_ ) ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Generic - A Stripe Generic Module

=head1 VERSION

    v0.100.2

=head1 DESCRIPTION

This is a module inherited by all other L<Net::API::Stripe> modules. Its purpose is to provide some shared methods and special object instantiation procedure with some key properties set such as I<_parent> and I<_field>.

=head1 CONSTRUCTOR

=over 4

=item B<new>( %ARG )

Creates a new L<Net::API::Stripe::Fraud> object.
It may also take an hash like arguments, that also are method of the same name.

Possible parameters are:

=over 8

=item I<_parent> The parent calling object

=item I<_field> The field or property name this object is associated with

=item I<_error>

=item I<debug> Integer. A debug level.

=item I<_dbh> A Database handler, if any

=item I<_init_strict_use_sub> Boolean set for method B<init> in L<Module::Generic>. When set to true, only parameters that have a corresponding method will be accepted.

=back

=back

=head1 METHODS

=over 4

=item B<field> Set/get the field to which this object is associated

=item B<parent> Set/get the parent (caller) of this object.

=item B<TO_JSON> Returns a stringified version of this object if the method B<as_string> exists or is inherited, otherwise it just returns the object itself.

=item B<_address_populate>

Provided with an L<Net::API::Stripe::Address> object, and this will set the fields line, line2, city, postal_code, state and country to address_line, address_line2, address_city, address_zip, address_state and address_country.

This is used in L<Net::API::Stripe::Payment::Source> and L<Net::API::Stripe::Connect::ExternalAccount::Card>

=item B<_get_base_class> Get the base class of the object

=item B<_instantiate_object>( field, class )

Provided with a field aka property name and a class name and this method creates an object.

If the object is already instantiated, it returns it.

Otherwise, it will attempt to load the given class using B<_load_class> from L<Module::Generic> or return undef and set an error if an error occurred.

=item B<_object_type_to_class>( type )

Provided with a Stripe object type such as I<charge> or I<invoice> or I<customer>, this method will return the equivalent L<Net::API::Stripe> module package name.

=item B<_set_get_hash>( field, hash )

Provided with a field (aka property) name and a hash reference, and this method will call method B<_set_get_hash_as_object> from L<Module::Generic> to create an hash whose properties can be accessed as methods of an object. So:

    $o->name

instead of:

    $o->{name}

=item B<_set_get_number>( field, number )

Provided with a field (aka property) and a number, this will create a new L<Module::Generic::Number> object for the associated field I<field>

=item B<_set_get_object_array>( field, class, array reference )

Provided with a field (aka property) name, a class (package name) and an array reference, and this method will instantiate an object for each array entry.

It returns an array reference for this field

=item B<_set_get_object_variant>( field, hash or array reference )

Provided with a field (aka property) name and an hash or array reference and this method will instantiate an object if the data provided is an hash reference or it will instantiate an array of objects if the data provided is an array reference.

=item B<_set_get_scalar_or_object_variant>( field, scalar, hash or array reference )

Provided with a scalar, an hash reference or an array reference and this will set the value for this field accordingly.

If this is just a scalar, the scalar value will be set for the I<field>. If the data is an hash reference or an array reference, the same operation is done as in method B<_set_get_object_variant>

=item B<_set_get_uri>( field, uri )

Provided with a field (aka a property) and an uri and this will create an L<URI> object for this I<field>

=item B<_will>

Calls B<will> from the module L<Module::Generic>

=back

=head1 HISTORY

=head2 v0.100.0

Initial version

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Net::API::Stripe>, L<Module::Generic>, L<Module::Generic::Number>, L<JSON>, L<URI>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2019-2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
