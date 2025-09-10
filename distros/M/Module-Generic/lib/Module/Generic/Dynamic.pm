##----------------------------------------------------------------------------
## Module Generic - ~/lib/Module/Generic/Dynamic.pm
## Version v1.3.0
## Copyright(c) 2025 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2021/03/20
## Modified 2025/09/10
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Module::Generic::Dynamic;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Module::Generic );
    use warnings::register;
    use vars qw( $AUTOLOAD $VERSION $DEBUG );
    use Config;
    use Module::Generic::Global ':const';
    use Scalar::Util ();
    our $DEBUG = 0;
    our $VERSION = 'v1.3.0';
};

use strict;
no warnings 'redefine';

sub new
{
    my $this = shift( @_ );
    my $class = ref( $this ) || $this;
    my $self = bless( {} => $class );
    my $data = $self->{_data} = {};
    # A Module::Generic object standard parameter
    $self->{_data_repo} = '_data';
    my $hash = {};
    @_ = () if( scalar( @_ ) == 1 && !defined( $_[0] ) );
    if( scalar( @_ ) == 1 && ( Scalar::Util::reftype( $_[0] ) // '' ) eq 'HASH' )
    {
        $hash = shift( @_ );
        $self->{debug} = $DEBUG if( $DEBUG && !CORE::exists( $hash->{debug} ) );
    }
    elsif( @_ )
    {
        CORE::warn( "Parameter provided is not an hash reference: '", join( "', '", @_ ), "'\n" ) if( $this->_warnings_is_enabled );
    }

    if( HAS_THREADS )
    {
        if( threads->tid != 0 )
        {
            warn( "Module::Generic::Dynamic is not thread-safe and should not be called from a thread." ) if( $this->_warnings_is_enabled );
        }
    }

    my $make_clean_field = sub
    {
        my $k = shift( @_ );
        my $clean_field = $k;
        $clean_field =~ tr/-/_/;
        $clean_field =~ s/\_{2,}/_/g;
        $clean_field =~ s/[^a-zA-Z0-9\_]+//g;
        $clean_field =~ s/^\d+//g;
        return( $clean_field );
    };

    my $make_class = sub
    {
        my $k = shift( @_ );
        my $new_class = $k;
        $new_class =~ tr/-/_/;
        $new_class =~ s/\_{2,}/_/g;
        $new_class = join( '', map( ucfirst( lc( $_ ) ), split( /\_/, $new_class ) ) );
        $new_class = "${class}\::${new_class}";
        # Sanitise the key which will serve as a method name
        my $clean_field = $make_clean_field->( $k );
        my $perl = <<EOT;
package $new_class;
BEGIN
{
    use strict;
    use Module::Generic;
    use parent -norequire, qw( Module::Generic::Dynamic );
};

1;

EOT
        local $@;
        my $rc = eval( $perl );
        die( "Unable to dynamically create module $new_class: $@" ) if( $@ );
        return( $new_class, $clean_field );
    };


    local $@;
    foreach my $k ( sort( keys( %$hash ) ) )
    {
        if( defined( $hash->{ $k } ) && ref( $hash->{ $k } ) eq 'HASH' )
        {
            my( $new_class, $clean_field ) = $make_class->( $k );
            next unless( length( $clean_field ) );
            eval( "sub ${new_class}::${clean_field} { return( shift->_set_get_object( '$clean_field', '$new_class', \@_ ) ); }" );
            die( $@ ) if( $@ );
            my $rv = $self->$clean_field( $hash->{ $k } );
            return( $self->pass_error ) if( !defined( $rv ) && $self->error );
        }
        # elsif( ref( $hash->{ $k } ) eq 'ARRAY' )
        elsif( defined( $hash->{ $k } ) && $self->_is_array( $hash->{ $k } ) )
        {
            my( $new_class, $clean_field ) = $make_class->( $k );
            # We take a peek at what we have to determine how we will handle the data
            my $mode = lc( scalar( @{$hash->{ $k }} ) ? ref( $hash->{ $k }->[0] ) : '' );
            if( $mode eq 'hash' )
            {
                my $all = [];
                foreach my $this ( @{$hash->{ $k }} )
                {
                    my $o = $this->{_looping} ? $this->{_looping} : $new_class->new( $this );
                    $this->{_looping} = $o;
                    CORE::push( @$all, $o );
                }
                eval( "sub ${new_class}::${clean_field} { return( shift->_set_get_object_array_object( '$clean_field', '$new_class', \@_ ) ); }" );
            }
            else
            {
                eval( "sub ${new_class}::${clean_field} { return( shift->_set_get_array_as_object( '$clean_field', \@_ ) ); }" );
            }
            die( $@ ) if( $@ );
            my $rv = $self->$clean_field( $hash->{ $k } );
            return( $self->pass_error ) if( !defined( $rv ) && $self->error );
        }
        # New/Improved: Handle other ref types with guesses
        elsif( defined( $hash->{ $k } ) && ref( $hash->{ $k } ) eq 'CODE' )
        {
            my $clean_field = $make_clean_field->( $k );
            next unless( length( $clean_field ) );
            my $func_name = '_set_get_code';
            my $pl = "sub ${class}::${clean_field} { return( shift->${func_name}( '$clean_field', \@_ ) ); }";
            eval( $pl );
            die( $@ ) if( $@ );
            my $rv = $self->$clean_field( $hash->{ $k } );
            return( $self->pass_error ) if( !defined( $rv ) && $self->error );
        }
        elsif( defined( $hash->{ $k } ) && $self->_is_object( $hash->{ $k } ) )
        {
            my $clean_field = $make_clean_field->( $k );
            next unless( length( $clean_field ) );
            my( $func_name, $pl );

            if( $hash->{ $k }->isa('JSON::PP::Boolean') ||
                $hash->{ $k }->isa('Module::Generic::Boolean') )
            {
                $func_name = '_set_get_boolean';
                $pl = "sub ${class}::${clean_field} { return( shift->${func_name}( '$clean_field', \@_ ) ); }";
            }
            elsif( $hash->{ $k }->isa('Module::Generic::File') )
            {
                $func_name = '_set_get_file';
                $pl = "sub ${class}::${clean_field} { return( shift->${func_name}( '$clean_field', \@_ ) ); }";
            }
            elsif( $hash->{ $k }->isa('Module::Generic::Array') )
            {
                $func_name = '_set_get_array_as_object';
                $pl = "sub ${class}::${clean_field} { return( shift->${func_name}( '$clean_field', \@_ ) ); }";
            }
            elsif( $hash->{ $k }->isa('Module::Generic::Number') )
            {
                $func_name = '_set_get_number';
                $pl = "sub ${class}::${clean_field} { return( shift->${func_name}( '$clean_field', \@_ ) ); }";
            }
            else
            {
                my $obj_class = ref( $hash->{ $k } );
                $func_name = '_set_get_object';
                $pl = "sub ${class}::${clean_field} { return( shift->${func_name}( '$clean_field', '$obj_class', \@_ ) ); }";
            }
            eval( $pl );
            die( $@ ) if( $@ );
            my $rv = $self->$clean_field( $hash->{ $k } );
            return( $self->pass_error ) if( !defined( $rv ) && $self->error );
        }
        elsif( defined( $hash->{ $k } ) && $self->_is_glob( $hash->{ $k } ) )
        {
            my $clean_field = $make_clean_field->( $k );
            next unless( length( $clean_field ) );
            my $func_name = '_set_get_glob';
            my $pl = "sub ${class}::${clean_field} { return( shift->${func_name}( '$clean_field', \@_ ) ); }";
            eval( $pl );
            die( $@ ) if( $@ );
            my $rv = $self->$clean_field( $hash->{ $k } );
            return( $self->pass_error ) if( !defined( $rv ) && $self->error );
        }
        elsif( !ref( $hash->{ $k } // '' ) )
        {
            my $clean_field = $make_clean_field->( $k );
            # Possibly there is no acceptable characters to make a field out of it
            next unless( length( $clean_field ) );
            my $func_name = '_set_get_scalar_as_object';

            if( $clean_field =~ /(^|\b)date|datetime|created|modified($|\b)/ )
            {
                $func_name = '_set_get_datetime';
            }
            elsif( $clean_field =~ /(^|\b)(uri|url)($|\b)/ || 
                ( defined( $hash->{ $k } ) && $hash->{ $k } =~ /^https?\:\/{2}/ ) )
            {
                $func_name = '_set_get_uri';
            }
            # New: UUID (field suggests ID + value matches standard UUID format)
            elsif( $clean_field =~ /(^id$|id$|_id$)/ &&
                ( defined( $hash->{ $k } ) && $self->_is_uuid( $hash->{ $k } ) ) )
            {
                $func_name = '_set_get_uuid';
            }
            # New: IP (field suggests IP + value matches simple IPv4; extend for IPv6 if needed)
            elsif( $clean_field =~ /ip(_addr(ess)?)?$/i &&
                ( defined( $hash->{ $k } ) && $self->_is_ip( $hash->{ $k } ) ) )
            {
                $func_name = '_set_get_ip';
            }
            # New: Version (field suggests version + value matches semver-like pattern)
            elsif( $clean_field =~ /version$/i &&
                ( defined( $hash->{ $k } ) && $self->_is_version( $hash->{ $k } ) ) )
            {
                $func_name = '_set_get_version';
            }
            # New: Boolean (field suggests flag + value is boolean-ish)
            # We have to be careful for pseudo boolean value like 'yes', 'no', 'true', 'false', because using _set_get_boolean will replace those by a Module::Generic::Boolean value that stringifies to '0' or '1', and nothing else...
            elsif( $clean_field =~ /^(is|has|enable|active|valid|disabled|inactive)/i &&
                ( ( defined( $hash->{ $k } ) && $hash->{ $k } =~ /^(?:0|1)$/i ) || !defined( $hash->{ $k } ) || !length( $hash->{ $k } // '' ) ) )
            {
                $func_name = '_set_get_boolean';
            }
            # New: File/path (field suggests file/path + value looks like a path)
            # This needs improvement, or it might catch false positive...
            elsif( $clean_field =~ /(file|path)$/i &&
                defined( $hash->{ $k } ) &&
                $self->_looks_like_path( $hash->{ $k } ) )
            {
                $func_name = '_set_get_file';
            }
            elsif( $clean_field =~ /(count|size|quantity)$/i &&
                   defined( $hash->{ $k } ) && $self->_is_integer( $hash->{ $k } ) )
            {
                $func_name = '_set_get_number';
            }
            # New: Number (after other checks; use looks_like_number for certainty)
            elsif( $self->_is_number( $hash->{ $k } ) )
            {
                $func_name = '_set_get_number';
            }
            my $pl = "sub ${class}::${clean_field} { return( shift->${func_name}( '$clean_field', \@_ ) ); }";
            # my $pl = q[sub ${class}::${clean_field} { print( STDERR "Got here\n" ); }];
            eval( $pl );
            die( $@ ) if( $@ );
            my $rv = $self->$clean_field( $hash->{ $k } );
            return( $self->pass_error ) if( !defined( $rv ) && $self->error );
        }
        else
        {
            # Fallback for unknown refs: use generic _set_get to store safely
            my $clean_field = $make_clean_field->( $k );
            next unless( length( $clean_field ) );
            my $func_name = '_set_get';
            my $pl = "sub ${class}::${clean_field} { return( shift->${func_name}( '$clean_field', \@_ ) ); }";
            eval( $pl );
            die( $@ ) if( $@ );
            my $rv = $self->$clean_field( $hash->{ $k } );
            return( $self->pass_error ) if( !defined( $rv ) && $self->error );
        }
    }
    return( $self );
}

sub FREEZE
{
    my $self = CORE::shift( @_ );
    my $serialiser = CORE::shift( @_ ) // '';
    my $class = CORE::ref( $self );
    my %hash  = %$self;
    # Return an array reference rather than a list so this works with Sereal and CBOR
    # On or before Sereal version 4.023, Sereal did not support multiple values returned
    CORE::return( [$class, \%hash] ) if( $serialiser eq 'Sereal' && Sereal::Encoder->VERSION <= version->parse( '4.023' ) );
    # But CBOR and Storable want a list with the first element being the serialised element
    CORE::return( $class, \%hash );
}

sub STORABLE_freeze { CORE::return( CORE::shift->FREEZE( @_ ) ); }

sub STORABLE_thaw { CORE::return( CORE::shift->THAW( @_ ) ); }

# NOTE: CBOR will call the THAW method with the stored classname as first argument, the constant string CBOR as second argument, and all values returned by FREEZE as remaining arguments.
# NOTE: Storable calls it with a blessed object it created followed with $cloning and any other arguments initially provided by STORABLE_freeze
sub THAW
{
    my( $self, undef, @args ) = @_;
    my $ref = ( CORE::scalar( @args ) == 1 && CORE::ref( $args[0] ) eq 'ARRAY' ) ? CORE::shift( @args ) : \@args;
    my $class = ( CORE::defined( $ref ) && CORE::ref( $ref ) eq 'ARRAY' && CORE::scalar( @$ref ) > 1 ) ? CORE::shift( @$ref ) : ( CORE::ref( $self ) || $self );
    my $hash = CORE::ref( $ref ) eq 'ARRAY' ? CORE::shift( @$ref ) : {};
    my $new;
    # Storable pattern requires to modify the object it created rather than returning a new one
    if( CORE::ref( $self ) )
    {
        foreach( CORE::keys( %$hash ) )
        {
            $self->{ $_ } = CORE::delete( $hash->{ $_ } );
        }
        $new = $self;
    }
    else
    {
        $new = CORE::bless( $hash => $class );
    }
    CORE::return( $new );
}

sub TO_JSON
{
    my $self = CORE::shift( @_ );
    my $ref  = { %$self };
    CORE::delete( $ref->{_data} );
    CORE::delete( $ref->{_data_repo} );
    CORE::return( $ref );
}

sub AUTOLOAD
{
    my( $method ) = our $AUTOLOAD =~ /([^:]+)$/;
    no overloading;
    my $self = shift( @_ );
    my $class = ref( $self ) || $self;
    my $args = \@_;

    if( HAS_THREADS )
    {
        if( threads->tid != 0 )
        {
            CORE::warn( "Module::Generic::Dynamic::AUTOLOAD is not thread-safe and should not be called from a thread." ) if( warnings::enabled() );
            # return( $self->error( "Module::Generic::Dynamic::AUTOLOAD is not thread-safe and should not be called from a thread." ) );
        }
    }

    # Check if method already exists
    if( my $code = $self->can( $method ) )
    {
        return( $code->( @_ ) );
    }

    # Default handler
    # my $handler = '_set_get_scalar_as_object';
    my( $handler, $pl, $ref );
    my $has_args = scalar( @_ );
    my $first_arg = \'';
    if( $has_args )
    {
        $ref = lc( ref( $_[0] // '' ) );
        $first_arg = \$_[0] if( defined( $_[0] ) );
    }

    # We try to find the right handler based on the method name
    # Those checks should be very conservative. If nothing is found, and we received data, we will check the data type to find the proper handler.
    if( $method =~ /(^|\b)date|datetime|created|modified($|\b)/ )
    {
        $handler = '_set_get_datetime';
    }
    elsif( $method =~ /(^|\b)(uri|url)($|\b)/ )
    {
        $handler = '_set_get_uri';
    }
    elsif( $method =~ /(^id$|id$|_id$)/ )
    {
        $handler = '_set_get_uuid';
    }
    elsif( $method =~ /ip(_addr(ess)?)?$/i )
    {
        $handler = '_set_get_ip';
    }
    elsif( $method =~ /version$/i )
    {
        $handler = '_set_get_version';
    }
    elsif( $method =~ /^(is|has|enable|active|valid|disabled|inactive)/i )
    {
        $handler = '_set_get_boolean';
    }
    elsif( $method =~ /(file|path)$/i )
    {
        $handler = '_set_get_file';
    }
    elsif( $method =~ /(count|size|quantity)$/i )
    {
        $handler = '_set_get_number';
    }

    # Some data types take precedence and some don't, so we keep checking
    HANDLERS:
    {
        last HANDLERS unless( $has_args );
        # We make that determination here, because we do not want that check to conflict with regular SCALAR that comes below
        if( defined( $ref ) && 
            $ref eq 'scalar' && 
            ( $$ref == 1 || $$ref == 0 ) )
        {
            $handler = '_set_get_boolean';
        }
        # Using hash is very broad, so if we already have a handler
        elsif( defined( $ref ) && ( $ref eq 'hash' || $ref eq 'array' || $ref eq 'scalar' ) )
        {
            last HANDLERS if( defined( $handler ) );
            $handler = "_set_get_${ref}_as_object";
        }
        elsif( $ref eq 'CODE' )
        {
            $handler = '_set_get_code';
        }
        elsif( $self->_is_object( $$first_arg ) )
        {
            if( $self->_is_a( $$first_arg => [qw( JSON::PP::Boolean Module::Generic::Boolean )] ) )
            {
                $handler = '_set_get_boolean';
            }
            elsif( $self->_is_a( $$first_arg => 'Module::Generic::File' ) )
            {
                $handler = '_set_get_file';
            }
            elsif( $self->_is_a( $$first_arg => 'Module::Generic::Array' ) )
            {
                $handler = '_set_get_array_as_object';
            }
            elsif( $self->_is_a( $$first_arg => 'Module::Generic::Number' ) )
            {
                $handler = '_set_get_number';
            }
            elsif( $self->_is_a( $$first_arg => [qw( DateTime Module::Generic::DateTime )] ) )
            {
                $handler = '_set_get_datetime';
            }
            else
            {
                my $obj_class = ref( $$first_arg );
                $handler = '_set_get_object';
                $pl = "sub ${class}::${method} { return( shift->$handler( '$method', '$obj_class', \@_ ) ); }";
            }
        }
        elsif( $self->_is_glob( $$first_arg ) )
        {
            $handler = '_set_get_glob';
        }
        # We have arguments, but they are just not reference
        elsif( $has_args && !$ref )
        {
            if( (
                    $self->_load_class( 'Regexp::Common', 'URI' ) && 
                    $$first_arg =~ /^(?:$Regexp::Common::URI::RE{URI}{HTTP}|$Regexp::Common::URI::RE{URI}{HTTP}{-scheme => 'https'})$/
                ) ||
                (
                    $$first_arg =~ /^https?\:\/{2}[^\s\0-\x1F\x7F]+$/ &&
                    $$first_arg !~ /[<>\"|?*]/
                ) )
            {
                $handler = '_set_get_uri';
            }
            elsif( $self->_is_uuid( $$first_arg ) )
            {
                $handler = '_set_get_uuid';
            }
            elsif( $self->_is_ip( $$first_arg ) )
            {
                $handler = '_set_get_ip';
            }
            # We just do this here, so it does not get misconstrued for a version or an integer
            elsif( $handler eq '_set_get_boolean' && 
                ( $$first_arg == 1 || $$first_arg == 0 ) )
            {
                # ok, we're good
            }
            elsif( $self->_looks_like_path( $$first_arg ) )
            {
                $handler = '_set_get_file';
            }
            elsif( $self->_is_integer( $$first_arg ) )
            {
                $handler = '_set_get_number';
            }
            elsif( $self->_is_number( $$first_arg ) )
            {
                $handler = '_set_get_number';
            }
            # We do version at the end, because '0' is a proper version, and it would conflict with integer and number checks.
            elsif( $self->_is_version( $$first_arg ) )
            {
                $handler = '_set_get_version';
            }
        }

        # Fallback also applies for the special object class Regexp
        unless( defined( $handler ) )
        {
            $handler = ( $ref eq 'scalar' || !$ref ) ? '_set_get_scalar_as_object' : '_set_get_scalar';
        }
    };

    # Common code here for simple handlers
    if( defined( $handler ) && !defined( $pl ) )
    {
        $pl = "sub ${class}::${method} { return( shift->$handler( '$method', \@_ ) ); }";
    }
    local $@;
    eval( "sub ${class}::${method} { return( shift->$handler( '$method', \@_ ) ); }" );
    return( $self->error( "Failed to create method $method in $class: $@" ) ) if( $@ );
    # die( $@ ) if( $@ );
    return( $self->$method( @_ ) );
};

# Avoid being called by AUTOLOAD
sub DESTROY
{
    # <https://perldoc.perl.org/perlobj#Destructors>
    CORE::local( $., $@, $!, $^E, $? );
    CORE::return if( ${^GLOBAL_PHASE} eq 'DESTRUCT' );
    my $self = CORE::shift( @_ );
    CORE::return if( !CORE::defined( $self ) );
};

1;

__END__
