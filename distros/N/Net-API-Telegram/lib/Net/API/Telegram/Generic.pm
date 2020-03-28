# -*- perl -*-
##----------------------------------------------------------------------------
## Telegram API - ~/lib/Net/API/Telegram/Generic.pm
## Version 0.1
## Copyright(c) 2019 Jacques Deguest
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2019/06/02
## Modified 2019/06/02
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Net::API::Telegram::Generic;
BEGIN
{
	use strict;
	use parent qw( Module::Generic );
    use Devel::StackTrace;
    use Data::Dumper;
    use Scalar::Util;
    use DateTime;
    use DateTime::TimeZone;
    use File::Temp;
    use File::Spec;
    ## For the JSON::true and JSON::false
    use JSON;
    use TryCatch;
	use Net::API::Telegram::Number;
	our( $VERSION ) = '0.1';
};

sub init
{
    my $self = shift( @_ );
    ## Get the init params always present and including keys like _parent and _field
    my $init = shift( @_ );
    my $class = ref( $self );
    if( Scalar::Util::blessed( $init ) )
    {
    	if( $init->isa( 'Net::API::Telegram' ) )
    	{
    		$self->{ '_parent' } = $init;
    		$self->{ '_debug' } = $init->debug;
    	}
    }
    else
    {
		$self->{_parent} = $init->{ '_parent' } || warn( "Property '_parent' is not provided in the init hash!\n" );
		$self->{_field} = $init->{ '_field' } || warn( "Property '_field' is not provided in the init hash!\n" );
		$self->{debug} = $init->{ '_debug' };
    }
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ );
    return( $self );
}

sub as_hash
{
    my $self = shift( @_ );
    my $class = ref( $self ) || return( $self->error( "This method \"as_hash\" must be called with an object, not using class \"$self\"." ) );
    my $anti_loop = shift( @_ ) || '_as_hash_anti_loop_' . time();
    my $hash = {};
    local $crawl = sub
    {
    	my $this = shift( @_ );
		if( Scalar::Util::blessed( $this ) )
		{
			## $self->_message( 3, "\tvalue to check '$this' is an object of type '", ref( $this ), "'." );
			#my $ref = $self->{ $k }->as_hash( $anti_loop );
			#return( $ref );
			if( $this->can( 'as_hash' ) )
			{
				## $self->_message( 3, "\t\tobject can 'as_hash'" );
				my $h = $this->as_hash( $anti_loop );
				## $self->_message( 3, "\t\tobject '", ref( $this ), "' returned value is: ", sub{ $self->dumper( $h ) } );
				return( $h ) if( length( $h ) );
			}
			elsif( overload::Overloaded( $this ) )
			{
				return( "$o" );
			}
			elsif( $this->can( 'as_string' ) )
			{
				return( $this->as_string );
			}
			else
			{
				warn( "Warning only: I have an object of class \"", ref( $this ), "\" ($this), but is not overloaded and does not have an as_string method, so I don't know what to do to get a string version of it.\n" );
			}
		}
		elsif( ref( $this ) eq 'ARRAY' )
		{
			## $self->_message( 3, "\tvalue to check '$this' is an array reference." );
			my $arr = [];
			foreach my $that ( @$this )
			{
				my $v = $crawl->( $that );
				## $self->_message( 3, "\t\tReturned value to add to array is '$v': ", sub{ $self->dumper( $v ) } );
				push( @$arr, $v ) if( length( $v ) );
			}
			## $self->_messagef( 3, "\treturning %d items in this array.", scalar( @$arr ) );
			return( $arr );
		}
		elsif( ref( $this ) eq 'HASH' )
		{
			## $self->_message( 3, "\tvalue to check '$this' is a hash reference." );
			return( $this ) if( exists( $this->{ $anti_loop } ) );
			$this->{ $anti_loop }++;
			my $ref = {};
			foreach my $k ( keys( %$this ) )
			{
				$ref->{ $k } = $crawl->( $this->{ $k } );
			}
			return( $ref );
		}
		else
		{
			## $self->_message( 3, "\tvalue to check '$this' is a scalar, returning it." );
			return( $this );
		}
    };
    
    foreach my $k ( keys( %$self ) )
    {
    	last if( exists( $self->{ $anti_loop } ) );
    	## Only process keys if their corresponding method exists in their package
    	if( defined( &{ "${class}::${k}" } ) )
    	{
    		## $self->_message( 3, "Getting data for $k" );
    		if( $self->_is_boolean( $k ) )
    		{
    			$hash->{ $k } = ( $self->{ $k } ? JSON::true : JSON::false );
    			## $self->_message( 3, "\tvalue set to boolean '$hash->{$k}'" );
    		}
    		else
    		{
				$hash->{ $k } = $crawl->( $self->{ $k } );
    		}
    	}
    }
    return( $hash );
}

sub dumpto
{
    my $self  = shift( @_ );
    my( $data, $file ) = @_;
    local $Data::Dumper::Sortkeys = 1;
    local $Data::Dumper::Terse = 1;
    local $Data::Dumper::Indent = 1;
    local $Data::Dumper::Useqq = 1;
    my $fh = IO::File->new( ">$file" ) || die( "Unable to create file '$file': $!\n" );
    $fh->print( Data::Dumper::Dumper( $data ), "\n" );
    $fh->close;
    ## 606 so it can work under command line and web alike
    chmod( 0666, $file );
    return( 1 );
}

sub parent { return( shift->{_parent} ); }

sub TO_JSON
{
    my $self = shift( @_ );
    return( $self->can( 'as_string' ) ? $self->as_string : $self );
}

sub _download
{
	my $self = shift( @_ );
	my $id = shift( @_ ) || return( $self->error( "No file id was provided" ) );
	my $opts = {};
	$opts = shift( @_ ) if( ref( $_[0] ) eq 'HASH' );
	my $parent = $self->_parent;
	## https://core.telegram.org/bots/api#getfile
	my $file = $self->_parent->getFile({
		'file_id' => $id
	}) || return( $self->error( "Unable to get file information object for file id $id: ", $parent->error->message ) );
	my $path = $file->file_path;
	my $uri = URI->new( $parent->dl_uri );
	$uri->path( $uri->path . '/' . $path );
	my $datadir = File::Spec->tmpdir;
	my $tmpdir = File::Temp::tempdir( 'telegram-file-XXXXXXX', DIR => $datadir, CLEANUP => $parent->cleanup_temp );
	##( $fh, $file ) = tempfile( "data-XXXXXXX", SUFFIX => ".${ext}", DIR => $tmpdir );
	my $filepath = File::Temp::mktemp( "$tmpdir/data-XXXXXXX" );
	$filepath .= '.' . $opts->{ext} if( $opts->{ext} );
	my $req = JDev::HTTP::Request->new( 'GET' => $uri );
	my $res = $parent->agent->request( $req, $filepath );
	my $mime = $res->content_type;
	my $len = $res->content_length;
	if( !$self->is_success )
	{
		return( $self->error( sprintf( "Unable to download file \"$path\". Server returned error code %s (%s)", $res->code, $res->message ) ) );
	}
	if( $len != -s( $filepath ) )
	{
		warn( sprintf( "Warning only: The size in bytes returned by the server ($len) is different than the local file (%d)\n", -s( $filepath ) ) );
	}
	my $ext;
	if( !$opts->{ext} && length( $mime ) )
	{
		if( $mime =~ /\/([^\/]+)$/ )
		{
			my $ext = $1;
			rename( $filepath, "${filepath}.${ext}" );
			$filepath = "${filepath}.${ext}";
		}
	}
	return({
		'filepath' => $filepath,
		'mime' => $mime,
		'response' => $res,
		'size' => -s( $filepath ),
	});
}

sub _field { return( shift->_set_get( '_field', @_ ) ); }

sub _get_base_class
{
    my $self  = shift( @_ );
    my $class = shift( @_ );
    my $base  = __PACKAGE__;
    $base =~ s/\:\:Generic$//;
    my $pkg = ( $class =~ /^($base\:\:(?:[^\:]+)?)/ )[0];
}

# sub _instantiate_object
# {
# 	my $self = shift( @_ );
#     my $field = shift( @_ );
#     my $class = shift( @_ );
# 	my $h = 
# 	{
# 		'_parent' => $self->{ '_parent' },
# 		'_field' => $field,
# 		'_debug' => $self->{ '_debug' },
# 	};
# 	$h->{ '_dbh' } = $self->{ '_dbh' } if( $self->{ '_dbh' } );
# 	$self->{_parent}->_load( [ $class ] ) || return( $self->error( $self->{_parent}->error->message ) );
# 	my $o = @_ ? $class->new( $h, @_ ) : $class->new( $h );
# 	return( $self->error( "Unable to instantiate an object of class $class: ", $class->error ) ) if( !defined( $o ) );
# 	return( $o );
# }

sub _instantiate_object
{
	my $self = shift( @_ );
	my $name = shift( @_ );
	return( $self->{ $name } ) if( exists( $self->{ $name } ) && Scalar::Util::blessed( $self->{ $name } ) );
	my $class = shift( @_ );
	# print( STDERR __PACKAGE__, "::_instantiate_object() called for name '$name' and class '$class'\n" );
	# $self->message( 3, "called for name '$name' and class '$class'." );
	my $this;
	my $h = 
	{
		'_parent' => $self->{_parent},
		'_field' => $name,
		'_debug' => $self->{debug},
	};
	$h->{_dbh} = $self->{_dbh} if( $self->{_dbh} );
	my $o;
	try
	{
		## https://stackoverflow.com/questions/32608504/how-to-check-if-perl-module-is-available#comment53081298_32608860
		eval( "require $class;" ) unless( defined( *{"${class}::"} ) );
		# print( STDERR __PACKAGE__, "::_instantiate_object(): Error while loading module $class? $@\n" );
		# $self->message( 3, "Error while loading module $class? $@" );
		return( $self->error( "Unable to load module $class: $@" ) ) if( $@ );
		$o = @_ ? $class->new( $h, @_ ) : $class->new( $h );
		return( $self->pass_error( "Unable to instantiate an object of class $class: ", $class->error ) ) if( !defined( $o ) );
	}
	catch( $e ) 
	{
		# print( STDERR __PACKAGE__, "::_instantiate_object() An error occured while loading module $class for name '$name': $e\n" );
		return( $self->error({ code => 500, message => $e }) );
	}
	# $self->message( 3, "Returning newly generated object $o with structure: ", $self->dumper( $o ) );
	return( $o );
}

sub _is_boolean { return( 0 ); }

sub _message { return( shift->SUPER::message( @_ ) ); }

sub _messagef { return( shift->SUPER::messagef( @_ ) ); }

sub _object_type_to_class
{
	my $self = shift( @_ );
	my $type = shift( @_ ) || return( $self->error( "No object type was provided" ) );
	my $ref  = $Net::API::Telegram::TYPE2CLASS;
	$self->_messagef( 3, "\$TYPE2CLASS has %d elements", scalar( keys( %$ref ) ) );
	return( $self->error( "No object type '$type' known to get its related class for field $self->{_field}" ) ) if( !exists( $ref->{ $type } ) );
	return( $ref->{ $type } );
}

sub _parent { return( shift->_set_get( '_parent', @_ ) ); }

sub _set_get_hash
{
	my $self = shift( @_ );
	my $field = shift( @_ );
	my $class = $field;
	$class =~ tr/-/_/;
	$class =~ s/\_{2,}/_/g;
	$class = join( '', map( ucfirst( lc( $_ ) ), split( /\_/, $class ) ) );
	return( $self->_set_get_hash_as_object( $field, $class, @_ ) );
}

sub _set_get_number
{
    my $self  = shift( @_ );
    my $field = shift( @_ );
    if( @_ )
    {
    	$self->{ $field } = Net::API::Telegram::Number->new( shift( @_ ) );
    }
    return( $self->{ $field } );
}

sub _set_get_number_or_object
{
    my $self  = shift( @_ );
    my $field = shift( @_ );
    my $class = shift( @_ );
    if( @_ )
    {
    	if( ref( $_[0] ) eq 'HASH' || Scalar::Util::blessed( $_[0] ) )
    	{
    		return( $self->_set_get_object( $field, $class, @_ ) );
    	}
    	else
    	{
    		return( $self->_set_get_number( $field, @_ ) );
    	}
    }
    return( $self->{ $field } );
}

sub _set_get_object_array2
{
    my $self  = shift( @_ );
    my $field = shift( @_ );
    my $class = shift( @_ );
    if( @_ )
    {
    	my $this = shift( @_ );
    	return( $self->error( "I was expecting an array ref, but instead got '$this'" ) ) if( ref( $this ) ne 'ARRAY' );
    	my $arr1 = [];
    	foreach my $ref ( @$this )
    	{
    		return( $self->error( "I was expecting an embeded array ref, but instead got '$ref'." ) ) if( ref( $ref ) ne 'ARRAY' );
			my $arr = [];
			for( my $i = 0; $i < scalar( @$ref ); $i++ )
			{
				my $o;
				if( defined( $ref->[$i] ) )
				{
					return( $self->error( "Parameter provided for adding object of class $class is not a reference." ) ) if( !ref( $ref->[$i] ) );
					if( Scalar::Util::blessed( $ref->[$i] ) )
					{
						my $pack = $ref->[$i]->isa( $class );
						if( $pack )
						{
							$o->{_parent} = $self->{_parent};
							$o->{_debug} = $self->{_debug};
							$o->{_dbh} = $self->{_dbh} if( $self->{_dbh} );
							$o = $ref->[$i];
						}
						else
						{
							return( $self->error( "Object provided ($pack) is not a $class object" ) );
						}
					}
					elsif( ref( $ref->[$i] ) eq 'HASH' )
					{
						$o = $self->_instantiate_object( $field, $class, $ref->[$i] );
					}
					else
					{
						$self->error( "Warning only: data provided to instaantiate object of class $class is not a hash reference" );
					}
				}
				else
				{
					$o = $self->_instantiate_object( $field, $class );
				}
				return( $self->error( "Unable to instantiate an object of class $class: ", $class->error ) ) if( !defined( $o ) );
				push( @$arr, $o );
			}
			push( @$arr1, $arr );
    	}
    	$self->{ $field } = $arr1;
    }
	return( $self->{ $field } );
}

sub _set_get_object_array
{
    my $self  = shift( @_ );
    my $field = shift( @_ );
    my $class = shift( @_ );
    if( @_ )
    {
    	my $ref = shift( @_ );
    	return( $self->error( "I was expecting an array ref, but instead got '$ref'" ) ) if( ref( $ref ) ne 'ARRAY' );
    	my $arr = [];
    	for( my $i = 0; $i < scalar( @$ref ); $i++ )
    	{
    		$self->_message( 3, "Calling method $class->$field with value '", $ref->[$i], "'" );
    		## Either the value provided is not defined, and we just instantiate an empty object, or 
    		## the value is a hash and we instantiate a new object with those parameters, or
    		## we have been provided an existing object
			## my $o = defined( $ref->[$i] ) ? $class->new( $h, $ref->[$i] ) : $class->new( $h );
			my $o;
			if( defined( $ref->[$i] ) )
			{
				return( $self->error( "Parameter provided for adding object of class $class is not a reference." ) ) if( !ref( $ref->[$i] ) );
				if( Scalar::Util::blessed( $ref->[$i] ) )
				{
					my $pack = $ref->[$i]->isa( $class );
					if( $pack )
					{
						$o->{_parent} = $self->{_parent};
						$o->{_debug} = $self->{debug};
						$o->{_dbh} = $self->{_dbh} if( $self->{_dbh} );
						$o = $ref->[$i];
					}
					else
					{
						return( $self->error( "Object provided ($pack) is not a $class object" ) );
					}
				}
				elsif( ref( $ref->[$i] ) eq 'HASH' )
				{
					#$o = $class->new( $h, $ref->[$i] );
					$o = $self->_instantiate_object( $field, $class, $ref->[$i] );
				}
				else
				{
					$self->error( "Warning only: data provided to instaantiate object of class $class is not a hash reference" );
				}
			}
			else
			{
				$o = $self->_instantiate_object( $field, $class );
			}
			return( $self->error( "Unable to instantiate an object of class $class: ", $class->error ) ) if( !defined( $o ) );
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
			my $type = $ref->{ 'object' } || return( $self->error( "No object type could be found in hash: ", sub{ $self->_dumper( $ref ) } ) );
			my $class = $self->_object_type_to_class( $type );
			$self->_message( 3, "Object type $type has class $class" );
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

1;

__END__

