##----------------------------------------------------------------------------
## Module Generic - ~/lib/Module/Generic/File/Mmap.pm
## Version v0.1.4
## Copyright(c) 2024 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2022/07/26
## Modified 2025/03/12
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Module::Generic::File::Mmap;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Module::Generic );
    use vars qw( $VERSION $HAS_CACHE_MMAP $HAS_B64 );
    use Data::UUID;
    # This is disruptive for everybody. Bad idea.
    # use JSON 4.03 qw( -convert_blessed_universally );
    use JSON 4.03;
    use Module::Generic::File qw( file sys_tmpdir );
    # use Nice::Try;
    our $HAS_CACHE_MMAP = 0;
    our $VERSION = 'v0.1.4';
};

use strict;
use warnings;

sub init
{
    my $self = shift( @_ );
    $self->{base64}          = undef;
    $self->{cache_file}      = '';
    # Default action when accessing a shared file cache? If 1, it will create it if it does not exist already
    $self->{create}          = 0;
    $self->{destroy}         = 0;
    $self->{key}             = Data::UUID->new->create_str;
    $self->{mode}            = 0666;
    $self->{serial}          = '';
    $self->{size}            = 0;
    $self->{_packing_method} = 'json';
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    unless( $HAS_CACHE_MMAP )
    {
        $self->_load_class( 'Cache::FastMmap' ) || return( $self->pass_error );
        $HAS_CACHE_MMAP = 1;
    }
    return( $self->error( "No key was set." ) ) if( !defined( $self->{key} ) || !length( $self->{key} ) );
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    my $tmpdir = sys_tmpdir();
    $self->{_cache_dir} = $tmpdir->child( 'mmap_data' );
    # A cache file will be provided either by the user, either by us with the open() method.
    if( my $f = $self->cache_file )
    {
        # try-catch
        local $@;
        eval
        {
            # No serialiser because we manage ths ourself
            my $cache = Cache::FastMmap->new(
                ( ( defined( $self->{destroy} ) && length( $self->{destroy} ) ) ? ( unlink_on_exit => $self->{destroy} ) : () ),
                share_file => "$f",
                ( $self->{size} ? ( cache_size => $self->{size} ) : () ),
                ( $self->{mode} ? ( permissions => $self->{mode} ) : () ),
                serializer => '',
            );
            $self->{_cache} = $cache;
        };
        if( $@ )
        {
            return( $self->error( "Error trying to instantiate a Cache::FastMmap object: $@" ) );
        }
    }
    $self->{owner} = $$;
    $self->{removed} = 0;
    return( $self );
}

# This class does not convert to an HASH
sub as_hash { return( $_[0] ); }

sub base64 { return( shift->_set_get_scalar( 'base64', @_ ) ); }

sub cache_file { return( shift->_set_get_file( 'cache_file', @_ ) ); }

sub cbor { return( shift->_packing_method( 'cbor' ) ); }

sub create { return( shift->_set_get_boolean( 'create', @_ ) ); }

sub destroy { return( shift->_set_get_boolean( 'destroy', @_ ) ); }

sub exists
{
    my $self   = shift( @_ );
    my $cache = $self->_cache || return( $self->error( "No Cache::FastMmap object. It seems it is gone!" ) );
    my $file = $cache->{share_file} || return(0);
    return( -e( "$file" ) ? 1 : 0 );
}

sub flags
{
    my $self   = shift( @_ );
    my $opts   = $self->_get_args_as_hash( @_ );
    no warnings 'uninitialized';
    no strict 'subs';
    $opts->{create} = $self->create unless( length( $opts->{create} ) );
    $opts->{mode} = $self->mode unless( length( $opts->{mode} ) );
    my $flags  = 0;
    $flags    |= 0600 if( $opts->{create} );
    $flags    |= ( $opts->{mode} || 0666 );
    return( $flags );
}

sub ftok
{
    my $self = shift( @_ );
    my $id = shift( @_ );
    my $f = sys_tmpdir();
    return( int(
                ( int( $f->inode ) & 0xffff ) |
                int( ( $f->device ) << 16 ) |
                ( ( $id & 0xff ) << 21 )
               ) );
}

sub has_xs { return( shift->_is_class_loadable( 'Cache::FastMmap' ) ); }

sub id { return( shift->_set_get_scalar( 'id', @_ ) ); }

sub json { return( shift->_packing_method( 'json' ) ); }

# sub key { return( shift->_set_get_scalar( 'key', @_ ) ); }
sub key
{
    my $self = shift( @_ );
    if( @_ )
    {
        $self->{key} = shift( @_ );
        $self->{serial} = $self->_str2key( $self->{key} );
    }
    return( $self->{key} );
}

# NOTE: lock is a noop
sub lock { return(1); }

# NOTE: locked is a noop
sub locked { return(1); }

sub mode { return( shift->_set_get_scalar( 'mode', @_ ) ); }

sub open
{
    my $self = shift( @_ );
    my $opts = {};
    if( ref( $_[0] ) eq 'HASH' )
    {
        $opts = shift( @_ );
    }
    else
    {
        @$opts{ qw( key mode size ) } = @_;
    }
    $opts->{size} = $self->size unless( length( $opts->{size} ) );
    $opts->{size} = int( $opts->{size} );
    $opts->{mode} //= '';
    $opts->{key} = $opts->{key}->[0] if( ref( $opts->{key} // '' ) eq 'ARRAY' );
    $opts->{key} //= '';
    no strict 'subs';
    my $serial;
    if( length( $opts->{key} ) )
    {
        $serial = $self->_str2key( $opts->{key} ) || 
            return( $self->error( "Cannot get serial from key '$opts->{key}': ", $self->error ) );
    }
    else
    {
        $serial = $self->serial;
    }
    die( "There is no serial!!\n" ) if( !CORE::length( $serial ) );
    my $create = 0;
    if( $opts->{mode} eq 'w' || $opts->{key} =~ s/^>// )
    {
        $create++;
    }
    elsif( $opts->{mode} eq 'r' || $opts->{key} =~ s/^<// )
    {
        $create = 0;
    }
    else
    {
        $create = $self->create;
    }
    my $flags = $self->flags( create => $create, ( $opts->{mode} =~ /^\d+$/ ? $opts->{mode} : () ) );
    
    my $cache_dir = $self->{_cache_dir} || return( $self->error( "Cache directory object is gone!" ) );
    return( $self->error( "Cache directory is not a Module::Generic::File object!" ) ) if( !$self->_is_a( $cache_dir => 'Module::Generic::File' ) );
    if( $cache_dir->exists )
    {
        return( $self->error( "Cache directory exists, but is not a directory!" ) ) if( !$cache_dir->is_dir );
    }
    else
    {
        $cache_dir->makepath || return( $self->pass_error( $cache_dir->error ) );
    }
    my $fo = $cache_dir->child( $serial );
    my $cache_file = "$fo";
    my $io;
    if( $fo->exists )
    {
        # Need to find a way to make that more efficient
        if( ( $flags & 0600 ) || 
            ( $flags & 0060 ) ||
            ( $flags & 0006 ) )
        {
            return( $self->error( "Requested mode ($flags) requires writing, but uid $> is missing write privilege to the cache file \"$cache_file\"." ) ) if( !$fo->can_write );
            $io = $fo->open( '<', { binmode => 'raw', autoflush => 1 } ) ||
                return( $self->pass_error( $fo->error ) );
        }
        else
        {
            return( $self->error( "Requested mode ($flags) require reading, but missing access privilege to the cache file \"$cache_file\"." ) ) if( !$fo->can_read );
            $io = $fo->open( '<', { binmode => $opts->{binmode}, autoflush => 1 } ) ||
                return( $self->pass_error( $fo->error ) );
        }
        $io->close;
    }
    else
    {
        if( ( $flags & 0600 ) || 
            ( $flags & 0060 ) ||
            ( $flags & 0006 ) )
        {
            $io = $fo->open( '+>', { binmode => 'raw', autoflush => 1 } ) ||
                return( $self->pass_error( $fo->error ) );
            $fo->close;
        }
        else
        {
            return( $self->error( "Requested mode ($flags) require reading, but the cache file \"$cache_file\" does not exist yet." ) );
        }
    }
    
    $self->serial( $serial );
    my $new = $self->new(
        key     => ( $opts->{key} || $self->key ),
        debug   => $self->debug,
        mode    => $flags,
        destroy => $self->destroy,
        cache_file => $fo,
        _packing_method => $self->_packing_method,
    ) || return( $self->error( "Cannot create object with key '", ( $opts->{key} || $self->key ), "': ", $self->error ) );
    $new->{base64} = $self->base64;
    $new->key( $self->key );
    $new->serial( $serial );
    $new->id( Scalar::Util::refaddr( $new ) );
    $new->size( $opts->{size} );
    return( $new );
}

sub owner { return( shift->_set_get_scalar( 'owner', @_ ) ); }

sub rand
{
    my $self = shift( @_ );
    return( Data::UUID->new->create_str );
}

# $self->read( $buffer, $size );
# $self->read( $buffer );
# my $data = $self->read;
sub read
{
    my( $self, $buf ) = @_;
    my $key = $self->key || return( $self->error( "No key set." ) );
    my $cache = $self->_cache || return( $self->error( "No Cache::FastMmap object. It seems it is gone!" ) );
    my $buffer;
    # try-catch
    local $@;
    eval
    {
        $buffer = $cache->get( $key );
    };
    if( $@ )
    {
        return( $self->error( "Error retrieving data in MMap file for key '$key': $@" ) );
    }
    my $bytes = CORE::length( $buffer // '' );
    my $packing = $self->_packing_method;
    $packing = lc( $packing ) if( defined( $packing ) );
    my $data;
    if( CORE::defined( $buffer ) && CORE::length( $buffer ) )
    {
        # There may be encapsulation of data before writing data to memory.
        # e.g.: MG[14]something here
        if( index( $buffer, 'MG[' ) == 0 )
        {
            my $def = substr( $buffer, 0, index( $buffer, ']' ) + 1, '' );
            # Get the string length stored
            my $len = int( substr( $def, 3, -1 ) );
            # Remove any possible remaining unwanted data
            substr( $buffer, $len, length( $buffer ), '' );
        }

        # try-catch
        local $@;
        eval
        {
            if( $packing eq 'json' )
            {
                $data = $self->_decode_json( $buffer );
            }
            elsif( $packing eq 'cbor' )
            {
                $data = $self->deserialise(
                    data => $buffer,
                    serialiser => 'CBOR::XS',
                    allow_sharing => 1,
                    ( defined( $self->{base64} ) ? ( base64 => $self->{base64} ) : () ),
                );
            }
            elsif( $packing eq 'sereal' )
            {
                $data = $self->deserialise(
                    data => $buffer,
                    serialiser => 'Sereal',
                    freeze_callbacks => 1,
                    ( defined( $self->{base64} ) ? ( base64 => $self->{base64} ) : () ),
                );
            }
            # By default Storable::Improved
            else
            {
                # $data = Storable::Improved::thaw( $buffer );
                $data = $self->deserialise(
                    data => $buffer,
                    serialiser => 'Storable::Improved',
                    ( defined( $self->{base64} ) ? ( base64 => $self->{base64} ) : () ),
                );
            }
        };
        if( $@ )
        {
            return( $self->error( "An error occured while decoding data using $packing with base64 set to '", ( $self->{base64} // '' ), "': $@" ) );
        }
    }
    else
    {
        $data = $buffer;
    }
    
    # data decoded is not a reference and size was provided and is greater than 0
    if( !ref( $data ) && scalar( @_ ) > 2 && int( $_[2] ) > 0 )
    {
        $data = substr( $data, 0, $_[2] );
    }
    
    if( scalar( @_ ) > 1 )
    {
        $_[1] = $data;
        return( CORE::length( $_[1] ) || "0E0" );
    }
    else
    {
		return( $data );
    }
}

sub remove
{
    my $self = shift( @_ );
    my $cache = $self->_cache || return( $self->error( "No Cache::FastMmap object. It seems it is gone!" ) );
    $cache->cleanup( @_ );
    undef( $cache );
    $self->_cache( undef );
    if( my $f = $self->cache_file )
    {
        $f->unlink if( $f->exists );
    }
    $self->removed(1);
}

sub removed { return( shift->_set_get_boolean( 'removed', @_ ) ); }

sub reset
{
    my $self = shift( @_ );
    my $default;
    if( @_ )
    {
        $default = shift( @_ );
    }
    else
    {
        $default = '';
    }
    if( my $cache = $self->_cache )
    {
        # my $key = $self->key || return( $self->error( "Could not find the mmap key!" ) );
        # $cache->set( $key => $default );
        $self->write( $default );
    }
    return( $self );
}

sub sereal { return( shift->_packing_method( 'sereal' ) ); }

sub serial { return( shift->_set_get_scalar( 'serial', @_ ) ); }

sub serialiser { return( shift->_set_get_scalar( '_packing_method', @_ ) ); }

{
    no warnings 'once';
    *serializer = \&serialiser;
}

sub size { return( shift->_set_get_scalar( 'size', @_ ) ); }

sub stat
{
    my $self   = shift( @_ );
    my $file = $self->cache_file || return(0);
    return( $self->error( "Mmap cache file found in our object is not a Module::Generic::File object." ) ) if( !$self->_is_a( $file => 'Module::Generic::File' ) );
    return( $file->stat );
}

sub storable { return( shift->_packing_method( 'storable' ) ); }

# NOTE: unlock is a noop
sub unlock { return(1); }

sub write
{
    my $self = shift( @_ );
    my $data;
    if( scalar( @_ ) == 1 && ref( $_[0] ) )
    {
        $data = shift( @_ );
    }
    else
    {
        $data = \join( '', @_ );
    }
    my $key = $self->key || return( $self->error( "No key set." ) );
    my $cache = $self->_cache || return( $self->error( "No Cache::FastMmap object. It seems it is gone!" ) );
    my $packing = $self->_packing_method;
    my $encoded;
    if( $packing eq 'json' )
    {
        # try-catch
        local $@;
        eval
        {
            $encoded = $self->_encode_json( $data );
        };
        if( $@ )
        {
            return( $self->error( "An error occured encoding data provided using $packing: $@. Data was: '$data'" ) );
        }
    }
    elsif( $packing eq 'cbor' )
    {
        # try-catch
        local $@;
        eval
        {
            $encoded = $self->serialise( $data,
                serialiser => 'CBOR::XS',
                allow_sharing => 1,
                ( defined( $self->{base64} ) ? ( base64 => $self->{base64} ) : () ),
            );
        };
        if( $@ )
        {
            return( $self->error( "An error occured encoding data provided using $packing: $@. Data was: '$data'" ) );
        }
        return( $self->pass_error ) if( !defined( $encoded ) );
    }
    elsif( $packing eq 'sereal' )
    {
        $self->_load_class( 'Sereal::Encoder' ) || return( $self->pass_error );
        my $const;
        $const = \&{"Sereal\::Encoder::SRL_ZLIB"} if( defined( &{"Sereal\::Encoder::SRL_ZLIB"} ) );
        # try-catch
        local $@;
        eval
        {
            $encoded = $self->serialise( $data,
                serialiser => 'Sereal',
                freeze_callbacks => 1,
                ( defined( $const ) ? ( compress => $const->() ) : () ),
                ( defined( $self->{base64} ) ? ( base64 => $self->{base64} ) : () ),
            );
        };
        if( $@ )
        {
            return( $self->error( "An error occured encoding data provided using $packing: $@. Data was: '$data'" ) );
        }
        return( $self->pass_error ) if( !defined( $encoded ) );
    }
    # Default to Storable::Improved
    else
    {
        # try-catch
        local $@;
        # local $Storable::forgive_me = 1;
        # $encoded = Storable::Improved::freeze( $data );
        eval
        {
            $encoded = $self->serialise( $data,
                serialiser => 'Storable::Improved',
                ( defined( $self->{base64} ) ? ( base64 => $self->{base64} ) : () ),
            );
        };
        if( $@ )
        {
            return( $self->error( "An error occured encoding data provided using $packing: $@. Data was: '$data'" ) );
        }
        return( $self->pass_error ) if( !defined( $encoded ) );
    }

    # Simple encapsulation
    # FYI: MG = Module::Generic
    substr( $encoded, 0, 0, 'MG[' . length( $encoded ) . ']' );
    
    # try-catch
    local $@;
    eval
    {
        $cache->set( $key => $encoded );
    };
    if( $@ )
    {
        return( $self->error( "Error writing data to MMap file for key '$key': $@" ) );
    }
    return( $self );
}

sub _cache { return( shift->_set_get_object_without_init( '_cache', 'Cache::FastMmap', @_ ) ); }

sub _decode_json
{
    my $self = shift( @_ );
    my $data = shift( @_ );
    # Nothing to do
    return( $data ) if( !defined( $data ) || !CORE::length( $data ) );
    no warnings 'uninitialized';
    my $j = JSON->new->utf8->relaxed->allow_nonref;
    my $seen = {};
    my $crawl;
    $crawl = sub
    {
        my $this = shift( @_ );
        my $type = Scalar::Util::reftype( $this );
        return( $this ) if( ( $type eq 'HASH' || $type eq 'ARRAY' ) && ++$seen->{ Scalar::Util::refaddr( $this ) } > 1 );
        if( $type eq 'HASH' )
        {
            # Found a former scalar reference, restore it
            if( CORE::exists( $this->{__scalar_gen_shm} ) )
            {
                return( \$this->{__scalar_gen_shm} );
            }
            
            foreach my $k ( keys( %$this ) )
            {
                next if( !ref( $this->{ $k } ) );
                $this->{ $k } = $crawl->( $this->{ $k } );
            }
        }
        elsif( $type eq 'ARRAY' )
        {
            for( my $i = 0; $i < scalar( @$this ); $i++ )
            {
                next if( !ref( $this->[$i] ) );
                $this->[$i] = $crawl->( $this->[$i] );
            }
        }
        return( $this );
    };
    
    my $decoded;
    # try-catch
    local $@;
    eval
    {
        $decoded = $j->decode( $data );
    };
    if( $@ )
    {
        return( $self->error( "An error occurred while trying to decode JSON data: $@" ) );
    }
    my $result = $crawl->( $decoded );
    return( $result );
}

# Purpose of this method is to recursively check the given data and change scalar reference if they are anything else than 1 or 0, otherwise JSON would complain
sub _encode_json
{
    my $self = shift( @_ );
    my $data = shift( @_ );
    my $seen = {};
    my $crawl;
    no warnings 'uninitialized';
    $crawl = sub
    {
        my $this = shift( @_ );
        my $type = Scalar::Util::reftype( $this );
        # Skip this reference if it is either hash or array and we have already seen it in order to avoid looping.
        return( $this ) if( ( $type eq 'HASH' || $type eq 'ARRAY' ) && ++$seen->{ Scalar::Util::refaddr( $this ) } > 1 );
        if( $type eq 'HASH' )
        {
            foreach my $k ( keys( %$this ) )
            {
                next if( !ref( $this->{ $k } ) );
                $this->{ $k } = $crawl->( $this->{ $k } );
            }
        }
        elsif( $type eq 'ARRAY' )
        {
            for( my $i = 0; $i < scalar( @$this ); $i++ )
            {
                next if( !ref( $this->[$i] ) );
                $this->[$i] = $crawl->( $this->[$i] );
            }
        }
        elsif( $type eq 'SCALAR' )
        {
            # The only supported value by JSON for a scalar reference
            return( $this ) if( $$this eq "1" or $$this eq "0" );
            my $pkg;
            if( ( $pkg = Scalar::Util::blessed( $this ) ) )
            {
                if( overload::Method( $this => '""' ) )
                {
                    $this = { __scalar_gen_shm => "$this", __package => $pkg };
                }
                else
                {
                    $this = { __scalar_gen_shm => $$this, __package => $pkg };
                }
            }
            else
            {
                $this = { __scalar_gen_shm => $$this };
            }
        }
        return( $this );
    };
    my $ref = $crawl->( $data );
    my $j = JSON->new->utf8->relaxed->allow_nonref->convert_blessed;
    
    my $encoded;
    # try-catch
    local $@;
    eval
    {
        $encoded = $j->encode( $ref );
    };
    if( $@ )
    {
        return( $self->error( "An error occurred while trying to JSON encode data: $@" ) );
    }
    return( $encoded );
}

sub _packing_method { return( shift->_set_get_scalar( '_packing_method', @_ ) ); }

sub _str2key
{
    my $self = shift( @_ );
    my $key  = shift( @_ );
    no strict 'subs';
    if( !defined( $key ) || $key eq '' )
    {
        return( Data::UUID->new->create_str );
    }
    # We do not actually use any path, but this is for standardisation with Module::Generic::SharedMem
    my $path;
    ( $key, $path ) = ref( $key ) eq 'ARRAY' ? @$key : ( $key, [getpwuid($>)]->[7] );
    $path = [getpwuid($path)]->[7] if( $path =~ /^\d+$/ );
    if( $key =~ /^\d+$/ )
    {
        my $id = $self->ftok( $key ) ||
            return( $self->error( "Unable to get a key using ftok: $!" ) );
        return( $id );
    }
    else
    {
        my $id = 0;
        $id += $_ for( unpack( "C*", $key ) );
        my $val = $self->ftok( $id );
        return( $val );
    }
}

sub FREEZE
{
    my $self = CORE::shift( @_ );
    my $serialiser = CORE::shift( @_ ) // '';
    my $class = CORE::ref( $self );
    my %hash  = %$self;
    CORE::delete( $hash{cache_file} );
    if( my $cache = $self->{_cache} )
    {
        my $file = $self->cache_file;
        my $cache_data = $cache->get( $self->key );
        $hash{__cache_file} = "$file";
        $hash{__cache_data} = $cache_data;
    }
    CORE::delete( $hash{_cache} );
    # Return an array reference rather than a list so this works with Sereal and CBOR
    # On or before Sereal version 4.023, Sereal did not support multiple values returned
    CORE::return( [$class, \%hash] ) if( $serialiser eq 'Sereal' && Sereal::Encoder->VERSION <= version->parse( '4.023' ) );
    # But Storable want a list with the first element being the serialised element
    CORE::return( $class, \%hash );
}

sub STORABLE_freeze { return( shift->FREEZE( @_ ) ); }

sub STORABLE_thaw { return( shift->THAW( @_ ) ); }

# NOTE: CBOR will call the THAW method with the stored classname as first argument, the constant string CBOR as second argument, and all values returned by FREEZE as remaining arguments.
# NOTE: Storable calls it with a blessed object it created followed with $cloning and any other arguments initially provided by STORABLE_freeze
sub THAW
{
    my( $self, undef, @args ) = @_;
    my $ref = ( CORE::scalar( @args ) == 1 && CORE::ref( $args[0] ) eq 'ARRAY' ) ? CORE::shift( @args ) : \@args;
    my $class = ( CORE::defined( $ref ) && CORE::ref( $ref ) eq 'ARRAY' && CORE::scalar( @$ref ) > 1 ) ? CORE::shift( @$ref ) : ( CORE::ref( $self ) || $self );
    my $hash = CORE::ref( $ref ) eq 'ARRAY' ? CORE::shift( @$ref ) : {};
    my $new;
    my( $cache_data, $cache_file );
    if( CORE::exists( $hash->{__cache_data} ) &&
        CORE::exists( $hash->{__cache_file} ) )
    {
        ( $cache_data, $cache_file ) = CORE::delete( @$hash{qw( __cache_data __cache_file )} );
    }
    
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
    if( CORE::defined( $cache_data ) &&
        CORE::defined( $cache_file ) )
    {
        my $f = Module::Generic::File->new( $cache_file ) || do
        {
            warn( "Unable to get a file object for \"$cache_file\": ", Module::Generic::File->error, "\n" ) if( $self->_warnings_is_enabled() );
            return( $new );
        };
        $new->{cache_file} = $f;
        $new->{_cache} = Cache::FastMmap->new(
            ( ( defined( $new->{destroy} ) && length( $new->{destroy} ) ) ? ( unlink_on_exit => $new->{destroy} ) : () ),
            share_file => "$f",
            ( $new->{size} ? ( cache_size => $new->{size} ) : () ),
            ( $new->{mode} ? ( permissions => $new->{mode} ) : () ),
            serializer => '',
        ) || do
        {
            warn( "Unable to instantiate a Cache::FastMmap object.\n" ) if( $self->_warnings_is_enabled() );
            return( $new );
        };
        $new->{_cache}->set( $new->key => $cache_data );
    }
    $new->{owner} = $$;
    CORE::return( $new );
}

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

Module::Generic::File::Mmap - MMap File Class

=head1 SYNOPSIS

    use Module::Generic::File::Mmap;
    my $cache = Module::Generic::File::Mmap->new(
        create => 1,
        destroy => 1,
        key => 'my key',
        mode => 0666,
        # Other possibilities are: cbor, sereal, storable and json
        serialiser => 'sereal',
        # 256k
        size => 262144,
        base64 => 1,
    ) || die( Module::Generic::File::Mmap->error, "\n" );

=head1 VERSION

    v0.1.4

L<Module::Generic::File::Mmap> implements a Mmap cache mechanism using L<Cache::FastMmap>, which is an XS module. The api is very similar to its counterpart with L<Module::Generic::File::Cache> and L<Module::Generic::SharedMem>, but has the advantage of sharing data over a file like L<Module::Generic::File::Cache>, but using Mmap and being very fast.

You must have installed separately L<Cache::FastMmap> for this module to work. If it is not installed, you could still instantiate an object, but you would not be able to get a new object after with L</open>.

This is particularly useful for system that lack support for shared memory cache. See L<perlport> for that.

=head1 METHODS

=head2 new

This instantiates a shared mmap cache object. It takes the following parameters:

=over 4

=item I<debug>

A debug value will enable debugging output (equal or above 3 actually)

=item I<cbor>

Provided with a value (true or false does not matter), and this will set L<CBOR::XS> as the data serialisation mechanism when storing data to mmap file.

=item I<create>

A boolean value to indicate whether the shared mmap cache file should be created if it does not exist. Default to false.

=item I<destroy>

A boolean value to indicate if the shared mmap cache file should be removed when the object is destroyed upon end of the script process.

See L<perlmod> for more about object destruction.

=item I<json>

Provided with a value (true or false does not matter), and this will set L<JSON> as the data serialisation mechanism when storing data to mmap file

Please note that if you want to store objects, you need to use I<storable> instead, because L<JSON> is not suitable to serialise objects.

=item I<key>

The shared mmap cache key identifier to use. It defaults to a random one created with L</rand>

If you provide an empty value, it will revert to one created with L</rand>.

If you provide a number, it will be used to call L</ftok>.

Otherwise, if you provide a key as string, the characters in the string will be converted to their numeric value and added up. The resulting id will be used to call L</ftok> and will produce a unique and repeatable value.

Either way, the resulting value is used to create a shared mmap cache file by L</open>.

=item I<mode>

The octal mode value to use when opening the shared mmap cache file.

Shared cache files are owned by system users and access to shared mmap cache files is ruled by the initial permissions set to it.

If you do not want to share it with any other user than yourself, setting mode to C<0600> is fine.

=item I<sereal>

Provided with a value (true or false does not matter), and this will set L<Sereal> as the data serialisation mechanism when storing data to mmap file

=item I<size>

The size in byte of the shared mmap cache.

This is set once it is created. You can create again the shared mmap cache file with a smaller size. No need to remove it first.

=item I<storable>

Provided with a value (true or false does not matter), and this will set L<Storable::Improved> as the data serialisation mechanism when storing data to mmap file

=back

An object will be returned if it successfully initiated, or C<undef()> upon error, which can then be retrieved with L<Module::Generic/error> inherited by L<Module::Generic::SharedMem>. You should always check the return value of the methods used here for their definedness.

    my $shmem = Module::Generic::SharedMem->new(
        create => 1,
        destroy => 0,
        key => 'my_memory',
        # 64K
        size => 65536,
        storable => 1,
    ) || die( Module::Generic::SharedMem->error );

=head2 cache_file

Sets or gets the underlying cache file to use.

=head2 cbor

When called, this will set L<CBOR::XS> as the data serialisation mechanism when storing data to mmap cache or reading data from mmap cache.

=head2 create

Boolean value. If set, this will have L</open> create the cache file if it does not already exists.

=head2 delete

Removes the cache file ad returns true upon success, or sets an L<error|Module::Generic/error> and return C<undef> upon error.

=head2 destroy

Boolean value. If true, the cache file will be removed when this objects is destroyed by perl upon clean-up.

=head2 exclusive

Boolean value. Sets whether there should be an exclusive access to the cache file. This is currently not used.

=head2 exists

Returns true if the cache file exists, or false otherwise.

=head2 flags

Provided with an optional hash or hash reference and this return a bitwise value of flags used by L</open>.

    my $flags = $cache->flags({
        create => 1,
        exclusive => 0,
        mode => 0600,
    }) || die( $cache->error );

=head2 ftok

This attempts to be a polyfil for L<POSIX/ftok> and provided with some digits, this returns a steady and reproducible serial that serves as a base file name for the cache file.

=head2 has_xs

Read-only. Returns true if the XS module L<Cache::FastMmap> is installed on your system and false otherwise.

=head2 id

Returns the id or serial of the cache file set after having opened it with L</open>

=head2 json

When called, this will set L<JSON> as the data serialisation mechanism when storing data to cache mmap.

=head2 key

The key to use to identify the cache file.

This must be unique enough to be different from other cache file and to be shared among other processes.

It returns the value currently set, if any.

=head2 lock

This locks the cache file, if any and returns the result from the lock.

If the cache has not been opened first, then this will set an L<error|Module::Generic/error> and return C<undef>.

=head2 locked

Returns the boolean value representing the lock state of the cache file.

=head2 mode

Set or get the cache file mode to be used by L</open>

=head2 open

Create an access to the cache mmap file and return a new L<Module::Generic::File::Mmap> object.

    my $cache = Module::Generic::File::Mmap->new(
        create => 1,
        destroy => 0,
        # If not provided, will use the one provided during object instantiation
        key => 'my_cache',
        # 64K
        size => 65536,
    ) || die( Module::Generic::File::Mmap->error );
    # Overriding some default value set during previous object instantiation
    my $c = $cache->open({
        mode => 0600,
        size => 1024,
    }) || die( $cache->error );

If the L</create> option is set to true, but the cache file already exists, L</open> will detect it and attempt to open access to the cache file without the L</create> bit on.

=head2 owner

Sets or gets the cache file owner, which is by default actually the process id (C<$$>)

=head2 rand

Get a random key to be used as identifier to create a shared mmap cache.

=head2 read

Read the content of the shared mmap cached and decode the data read using L<JSON>, L<CBOR|CBOR::XS>, L<Sereal> or L<Storable/thaw> depending on your serialiser of choice upon either object instantiation or upon using the methods L</json> or L</storable>

By default, if no serialiser is specified, it will default to C<storable>.

You can optionally provide a buffer, and a maximum length and it will read that much length and put the shared mmap cache content decoded in that buffer, if it were provided.

It then return the length read, or C<0E0> if no data was retrieved. C<0E0> still is treated as 0, but as a positive value, so you can do:

    my $len = $cache->read( $buffer ) || die( $cache->error );

But you really should more thoroughly do instead:

    my( $len, $buffer );
    if( !defined( $len = $cache->read( $buffer ) ) )
    {
        die( $cache->error );
    }

If you do not provide any buffer, you can call L</read> like this and it will return you the shared mmap cache decoded content:

    my $buffer;
    if( !defined( $buffer = $cache->read ) )
    {
        die( $cache->error );
    }

The content is stored in shared mmap cache after being encoded with L<Storable/freeze>.

=head2 remove

Remove entire the shared mmap cache identified with L</key>

=head2 removed

Returns true if the shared mmap cache was removed, false otherwise.

=head2 reset

Reset the shared mmap cache value. If a value is provided, it will be used as the new reset value, othewise an empty string will be used.

=head2 sereal

When called, this will set L<Sereal> as the data serialisation mechanism when storing data to cache mmap.

=head2 serial

Returns the serial number used to create or access the shared mmap cache.

This serial is created based on the I<key> parameter provided either upon object instantiation or upon using the L</open> method.

The serial is created by calling L</ftok> to provide a reliable and repeatable numeric identifier. L</ftok> is a simili polyfill of L<IPC::SysV/ftok>

=head2 serialiser

Sets or gets the serialiser. Possible values are: C<cbor>, C<json>, C<sereal>, C<storable>

=head2 size

Sets or gets the shared mmap cache size.

This should be an integer representing bytes, so typically a multiple of 1024.

This has not much effect, except ensuring there is enough space on the filesystem for the cache and that whatever data is provided does not exceed that threshold.

=head2 stat

Sets or retrieve value with L<Module::Generic::File/stat> for the underlying cache file.

It returns a L<Module::Generic::SemStat> object.

=head2 storable

When called, this will set L<Storable::Improved> as the data serialisation mechanism when storing data to cache mmap.

=head2 supported

Returns always true as cache file relies solely on file.

=head2 unlock

Remove the lock, if any. The shared mmap cache must first be opened.

    $cache->unlock || die( $cache->error );

=head2 write

Write the data provided to the shared mmap cache, after having encoded it using L<JSON>, L<CBOR|CBOR::XS>, L<Sereal> or L<Storable/freeze> depending on your serialiser of choice. See L</json>, L</cbor>, L</sereal> and L</storable> and more simply L</serialiser>

By default, if no serialiser is specified, it will default to C<storable>.

You can store in shared mmap cache any kind of data excepted glob, such as scalar reference, array or hash reference. You could also store module objects, but L<JSON> only supports encoding objects that are based on array or hash. As the L<JSON> documentation states "other blessed references will be converted into null"

It returns the current object for chaining, or C<undef> if there was an error, which can then be retrieved with L<Module::Generic/error>

=head1 SERIALISATION

=for Pod::Coverage FREEZE

=for Pod::Coverage STORABLE_freeze

=for Pod::Coverage STORABLE_thaw

=for Pod::Coverage THAW

=for Pod::Coverage TO_JSON

Serialisation by L<CBOR|CBOR::XS>, L<Sereal> and L<Storable::Improved> (or the legacy L<Storable>) is supported by this package. To that effect, the following subroutines are implemented: C<FREEZE>, C<THAW>, C<STORABLE_freeze> and C<STORABLE_thaw>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Module::Generic::SharedMem>, L<Cache::File>, L<File::Cache>, L<Cache::FileCache>

L<JSON>, L<Storable>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2022-2024 DEGUEST Pte. Ltd.

All rights reserved
This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
