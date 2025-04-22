##----------------------------------------------------------------------------
## Module Generic - ~/lib/Module/Generic/File/Cache.pm
## Version v0.2.10
## Copyright(c) 2025 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2022/03/16
## Modified 2025/04/22
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Module::Generic::File::Cache;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Module::Generic );
    use vars qw( $CACHE_REPO $CACHE_TO_OBJECT $DEBUG $HAS_B64 );
    use Config;
    use constant HAS_THREADS => ( $Config{useithreads} && $INC{'threads.pm'} );
    use constant IN_THREAD => ( HAS_THREADS && threads->can('tid') && threads->tid() != 0 );
    if( HAS_THREADS )
    {
        require threads;
        require threads::shared;
        threads->import();
        threads::shared->import();
        our $CACHE_REPO;
        our $CACHE_TO_OBJECT;
    }
    else
    {
        our $CACHE_REPO;
        our $CACHE_TO_OBJECT;
    }
    use Data::UUID;
    use Module::Generic::File qw( file sys_tmpdir );
    # use Nice::Try;
    # This is disruptive for everybody. Bad idea.
    # use JSON 4.03 qw( -convert_blessed_universally );
    use JSON 4.03;
    use Scalar::Util ();
    # use Storable 3.25 ();
    use Storable::Improved v0.1.3;
    # Hash of cache file to objects to maintain the shared cache file objects created
    $CACHE_REPO = [];
    $CACHE_TO_OBJECT = {};
    $DEBUG = 0;
    our $VERSION = 'v0.2.10';
};

use v5.26.1;
use strict;
use warnings;

sub init
{
    my $self = shift( @_ );
    $self->{binmode}    = 'utf-8';
    $self->{base64}     = undef;
    # Default action when accessing a shared file cache? If 1, it will create it if it does not exist already
    $self->{create}     = 0;
    # If true, this will destroy both the shared file cache and the semaphore upon end
    $self->{destroy}    = 0;
    $self->{exclusive}  = 0;
    no strict 'subs';
    $self->{key}        = Data::UUID->new->create_str;
    $self->{mode}       = 0666;
    $self->{serial}     = '';
    # SHM_BUFSIZ
    $self->{size}       = 0;
    $self->{tmpdir}     = sys_tmpdir();
    $self->{_init_strict_use_sub} = 1;
    # Storable keps breaking :(
    # I leave the feature of using it as a choice to the user, but defaults to JSON.
    # Other possibilities could be cbor, sereal and storable
    $self->{_packing_method} = 'json';
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    my $tmpdir = $self->{tmpdir} || sys_tmpdir();
    $self->{_cache_dir} = $tmpdir->child( 'cache_file' );
    $self->{_cache_file} = '';
    $self->{id}         = undef();
    $self->{locked}     = 0;
    $self->{owner}      = $$;
    $self->{removed}    = 0;
    return( $self );
}

# This class does not convert to an HASH
sub as_hash { return( $_[0] ); }

sub base64 { return( shift->_set_get_scalar( 'base64', @_ ) ); }

sub binmode { return( shift->_set_get_scalar( 'binmode', @_ ) ); }

sub cbor { return( shift->_packing_method( 'cbor' ) ); }

sub create { return( shift->_set_get_boolean( 'create', @_ ) ); }

sub delete { return( shift->remove( @_ ) ); }

sub destroy { return( shift->_set_get_boolean( 'destroy', @_ ) ); }

sub exclusive { return( shift->_set_get_boolean( 'exclusive', @_ ) ); }

sub exists
{
    my $self   = shift( @_ );
    my $file = $self->{_cache_file} || return(0);
    return( $self->error( "Cache file found in our object is not a Module::Generic::File object." ) ) if( !$self->_is_a( $file => 'Module::Generic::File' ) );
    return( $file->exists );
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

sub id { return( shift->_set_get_scalar( 'id', @_ ) ); }

sub json { return( shift->_packing_method( 'json' ) ); }

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

sub lock
{
    my $self = shift( @_ );
    my $file = $self->{_cache_file} ||
        return( $self->error( "No cache file is set yet. Have you first opened the cache file with open()?" ) );
    return( $self->error( "Cache file found in our object is not a Module::Generic::File object." ) ) if( !$self->_is_a( $file => 'Module::Generic::File' ) );
    $self->locked( $file->lock ? 1 : 0 );
    return( $self );
}

sub locked { return( shift->_set_get_boolean( 'locked', @_ ) ); }

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
    $opts->{key} //= '';
    $opts->{binmode} //= $self->binmode // 'utf-8';
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
        if( !$cache_dir->is_dir )
        {
            return( $self->error( "Cache directory exists, but is not a directory!" ) );
        }
        elsif( !$cache_dir->can_write )
        {
            return( $self->error( "Cache directory exists, but the current user id $> is not allowed to write to it!" ) );
        }
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
            $io = $fo->open( '+<', { binmode => $opts->{binmode}, autoflush => 1 } ) ||
                return( $self->pass_error( $fo->error ) );
            # Ok, we could write to the cache file, remove data we just wrote
            $fo->seek(0,0) || return( $self->pass_error( $fo->error ) );
            # $fo->truncate( $fo->tell ) || return( $self->pass_error( $fo->error ) );
        }
        else
        {
            return( $self->error( "Requested mode ($flags) require reading, but missing access privilege to the cache file \"$cache_file\"." ) ) if( !$fo->can_read );
            $io = $fo->open( '<', { binmode => $opts->{binmode}, autoflush => 1 } ) ||
                return( $self->pass_error( $fo->error ) );
        }
    }
    else
    {
        if( ( $flags & 0600 ) || 
            ( $flags & 0060 ) ||
            ( $flags & 0006 ) )
        {
            $io = $fo->open( '+>', { binmode => $opts->{binmode}, autoflush => 1 } ) ||
                return( $self->pass_error( $fo->error ) );
            # Some size, was provided, we fill the file with it, thus ensuring the filesystem lets us use that much
            # Subsequent calls to write(9 will clobber the file and truncate it to the actual size
            # but no more than the size if it was provided.
            if( $opts->{size} )
            {
                $self->_fill( $opts->{size} => $fo ) || return( $self->pass_error );
            }
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
        _packing_method => $self->_packing_method,
    ) || return( $self->error( "Cannot create object with key '", ( $opts->{key} || $self->key ), "': ", $self->error ) );
    $new->{base64} = $self->base64;
    $new->key( $self->key );
    $new->serial( $serial );
    $new->id( Scalar::Util::refaddr( $new ) );
    $new->size( $opts->{size} );
    $new->{_cache_file} = $fo;
    if( IN_THREAD )
    {
        lock( $CACHE_REPO );
        lock( $CACHE_TO_OBJECT );
        push( @$CACHE_REPO, $new );
        $CACHE_TO_OBJECT->{ $cache_file } = [] if( !CORE::exists( $CACHE_TO_OBJECT->{ $cache_file } ) );
        CORE::push( @{$CACHE_TO_OBJECT->{ $cache_file }}, $new );
    }
    else
    {
        push( @$CACHE_REPO, $new );
        $CACHE_TO_OBJECT->{ $cache_file } = [] if( !CORE::exists( $CACHE_TO_OBJECT->{ $cache_file } ) );
        CORE::push( @{$CACHE_TO_OBJECT->{ $cache_file }}, $new );
    }
    return( $new );
}

sub owner { return( shift->_set_get_scalar( 'owner', @_ ) ); }

sub rand
{
    my $self = shift( @_ );
    return( Data::UUID->new->create_str );
}

sub read
{
    my( $self, $buf ) = @_;
    my $file = $self->{_cache_file} ||
        return( $self->error( "No cache file is set yet. Have you first opened the cache file with open()?" ) );
    return( $self->error( "Cache file found in our object is not a Module::Generic::File object." ) ) if( !$self->_is_a( $file => 'Module::Generic::File' ) );
    $file->lock;
    # Make sure we are at the top of the file
    $file->seek(0,0) || return( $self->pass_error( $file->error ) );
    my $buffer = '';
    my $bytes = $file->read( $buffer, $file->length );
    $file->unlock;
    return( $self->pass_error( $file->error ) ) if( !defined( $bytes ) );
    my $packing = $self->_packing_method;
    $packing = lc( $packing ) if( defined( $packing ) );
    my $data;
    if( CORE::length( $buffer ) )
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
        };
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
    return(1) if( $self->removed );
    my $file = $self->{_cache_file} ||
        return( $self->error( "No cache file is set yet. Have you first opened the cache file with open()?" ) );
    return( $self->error( "Cache file found in our object is not a Module::Generic::File object." ) ) if( !$self->_is_a( $file => 'Module::Generic::File' ) );
    if( !$file->exists )
    {
        $self->removed(1);
        return( $self );
    }
    $file->unlock;
    my $rv = $file->delete;
    return( $self->pass_error( $file->error ) ) if( !defined( $rv ) );
    $self->removed( $rv ? 1 : 0 );
    if( $rv )
    {
        if( IN_THREAD )
        {
            lock( $CACHE_REPO );
            OBJECT: for( my $i = 0; $i < scalar( @$CACHE_REPO ); $i++ )
            {
                my $obj = $CACHE_REPO->[$i];
                # Somehow found an object, but without cache file associated. This would be weird
                my $file = $obj->{_cache_file} || next;
                # Should not happen, but let's not assume anything.
                unless( $self->_is_a( $file => 'Module::Generic::File' ) )
                {
                    next;
                }
                my $fname = "$file";
                next if( !CORE::exists( $CACHE_TO_OBJECT->{ $fname } ) );
                my $ref = $CACHE_TO_OBJECT->{ $fname };
                next unless( ref( $ref ) eq 'ARRAY' );
                for( my $j = 0; $j <= $#$ref; $j++ )
                {
                    CORE::splice( @$CACHE_REPO, $i, 1 );
                    CORE::splice( @$ref, $j, 1 );
                    last OBJECT;
                }
            }
        }
        else
        {
            OBJECT: for( my $i = 0; $i < scalar( @$CACHE_REPO ); $i++ )
            {
                my $obj = $CACHE_REPO->[$i];
                # Somehow found an object, but without cache file associated. This would be weird
                my $file = $obj->{_cache_file} || next;
                # Should not happen, but let's not assume anything.
                unless( $self->_is_a( $file => 'Module::Generic::File' ) )
                {
                    next;
                }
                my $fname = "$file";
                next if( !CORE::exists( $CACHE_TO_OBJECT->{ $fname } ) );
                my $ref = $CACHE_TO_OBJECT->{ $fname };
                next unless( ref( $ref ) eq 'ARRAY' );
                for( my $j = 0; $j <= $#$ref; $j++ )
                {
                    CORE::splice( @$CACHE_REPO, $i, 1 );
                    CORE::splice( @$ref, $j, 1 );
                    last OBJECT;
                }
            }
        }
        $self->{_cache_file} = '';
        $self->id( undef() );
    }
    
    if( $self->{_cache_dir} && 
        $self->{_cache_dir}->exists && 
        $self->{_cache_dir}->is_empty )
    {
        $self->{_cache_dir}->remove;
    }
    return( $rv ? 1 : 0 );
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
    my $file = $self->{_cache_file} ||
        return( $self->error( "No cache file is set yet. Have you first opened the cache file with open()?" ) );
    return( $self->error( "Cache file found in our object is not a Module::Generic::File object." ) ) if( !$self->_is_a( $file => 'Module::Generic::File' ) );
    $file->lock( exclusive => 1 );
    $self->write( $default );
    $file->unlock;
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
    my $file = $self->{_cache_file} || return(0);
    return( $self->error( "Cache file found in our object is not a Module::Generic::File object." ) ) if( !$self->_is_a( $file => 'Module::Generic::File' ) );
    return( $file->stat );
}

sub storable { return( shift->_packing_method( 'storable' ) ); }

sub supported { return(1); }

sub tmpdir { return( shift->_set_get_file( 'tmpdir', @_ ) ); }

sub unlock
{
    my $self = shift( @_ );
    my $file = $self->{_cache_file} ||
        return( $self->error( "No cache file is set yet. Have you first opened the cache file with open()?" ) );
    return( $self->error( "Cache file found in our object is not a Module::Generic::File object." ) ) if( !$self->_is_a( $file => 'Module::Generic::File' ) );
    return( $file->stat );
}

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
    my $file = $self->{_cache_file} ||
        return( $self->error( "No cache file is set yet. Have you first opened the cache file with open()?" ) );
    return( $self->error( "Cache file found in our object is not a Module::Generic::File object." ) ) if( !$self->_is_a( $file => 'Module::Generic::File' ) );
    my $size = 0;
    $size = $self->size // 0;
    $size = int( "${size}" ) if( defined( $size ) );
    my $packing = $self->_packing_method;
    my $encoded;
    if( $packing eq 'json' )
    {
        $encoded = $self->_encode_json( $data );
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
        # local $Storable::forgive_me = 1;
        # $encoded = Storable::Improved::freeze( $data );
        # try-catch
        local $@;
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

    # For some reason, I get warning that $size is uninitialised despite having initialised it and ensured it is defined
    no warnings 'uninitialized';
    $size //= 0;
    if( defined( $size ) && 
        ( $size > 0 ) && 
        length( $encoded ) > $size )
    {
        return( $self->error( "Data to write are ", length( $encoded ), " bytes long and exceed the maximum you have set of '$size'." ) );
    }

    # We use simple encapsulation to later remove irrelevant null-bytes and ensuring our data integrity
    # FYI: MG = Module::Generic
    # substr( $encoded, 0, 0, 'MG[' . length( $encoded ) . ']' );

    $file->lock;
    $file->seek(0,0);
    $file->print( $encoded );
    
    # Ensure data is safely flushed to disk
    $file->flush if( $file->can( 'flush' ) );
    $file->sync  if( $file->can( 'sync' ) );
    
    $file->truncate( $file->tell );
    $file->unlock;
    return( $self );
}

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
    
    # try-catch
    local $@;
    my $decoded = eval
    {
        $j->decode( $data );
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
    # try-catch
    local $@;
    my $encoded = eval
    {
        $j->encode( $ref );
    };
    if( $@ )
    {
        return( $self->error( "An error occurred while trying to JSON encode data: $@" ) );
    };
    return( $encoded );
}

sub _fill
{
    my $self = shift( @_ );
    my $size = shift( @_ );
    my $file = shift( @_ ) || return( $self->error( "No file was provided." ) );
    return( $self->error( "Size value provided ($size) is not an integer." ) ) if( $size !~ /^\d+$/ );
    return(1) if( $size <= 0 );
    return( $self->error( "File provided is not a Module::Generic::File file object." ) ) if( !$self->_is_a( $file => 'Module::Generic::File' ) );
    $file->seek(0,0);
    my $minimum = 32;
    my $range = 96;
    for( my $bytes = 0; $bytes < $size; $bytes += 4 )
    {
        my $rand = int( CORE::rand( $range ** 4 ) );
        my $string = '';
        for( 1..4 )
        {
            $string .= chr( $rand % $range + $minimum );
            $rand = int( $rand / $range );
        }
        $file->print( $string ) || return( $self->pass_error( $file->error ) );
    }
    $file->truncate( $file->tell );
    return(1);
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
            return( $self->error( "Unable to get a key using IPC::SysV::ftok: $!" ) );
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

sub DESTROY
{
    my $self = shift( @_ );
    return unless( CORE::exists( $self->{_cache_file} ) && defined( $self->{_cache_file} ) && CORE::length( $self->{_cache_file} ) );
    my $cache_file = '';
    $cache_file = $self->{_cache_file} if( CORE::length( $self->{_cache_file} ) );
    $self->unlock;
    if( $self->destroy )
    {
        return if( !$self->_is_a( $cache_file => 'Module::Generic::File' ) );
        my $ref = $CACHE_TO_OBJECT->{ "$cache_file" };
        if( ref( $ref ) )
        {
            my $addr = Scalar::Util::refaddr( $self );
            for( my $i = 0; $i <= $#$ref; $i++ )
            {
                if( Scalar::Util::refaddr( $ref->[$i] ) eq $addr )
                {
                    splice( @$ref, $i, 1 );
                    $i--;
                }
            }
            $self->remove if( !scalar( @$ref ) );
        }
    }
};

sub FREEZE
{
    my $self = CORE::shift( @_ );
    my $serialiser = CORE::shift( @_ ) // '';
    my $class = CORE::ref( $self );
    my %hash  = %$self;
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

# NOTE: END
END
{
    return unless( defined( $CACHE_REPO ) && ref( $CACHE_REPO ) eq 'ARRAY' );
    
    my $prefix = __PACKAGE__ . '::END';
    printf( STDERR "${prefix}: %d objects in repo to check.\n", scalar( @$CACHE_REPO ) ) if( $DEBUG >= 4 );

    # Only allow the parent process to clean up
    state $main_pid = $$;
    return if( $$ != $main_pid );

    foreach my $cache ( @$CACHE_REPO )
    {
        if( !Scalar::Util::blessed( $cache // '' ) || 
            ref( $cache // '' ) ne 'Module::Generic::File::Cache' )
        {
            warn( "${prefix}: Object found in object repo is not a Module::Generic::File::Cache object.\n" );
            next;
        }
        elsif( !defined( $cache ) || !ref( $cache ) || ( Scalar::Util::blessed( $cache ) && !$cache->can( 'remove' ) ) )
        {
            next;
        }
        elsif( !Scalar::Util::blessed( $cache->{_cache_file} ) ||
               ( Scalar::Util::blessed( $cache->{_cache_file} ) && !$cache->{_cache_file}->isa( 'Module::Generic::File' ) ) )
        {
            warn( "${prefix}: File object found in _cache_file (", overload::StrVal( $cache->{_cache_file} ), ") is actually not a Module::Generic::File, which is weird.\n" );
            next;
        }
        
        my $fname = "$cache->{_cache_file}";
        print( STDERR "\t${prefix}: Cache file is: \"", ( $fname // 'undef' ), "\"\n" ) if( $DEBUG >= 4 );
        next if( !length( $fname // '' ) );

        # Check for other references to the same file
        if( defined( $CACHE_TO_OBJECT ) && ref( $CACHE_TO_OBJECT ) eq 'HASH' )
        {
            if( IN_THREAD )
            {
                lock( $CACHE_TO_OBJECT );
                if( exists $CACHE_TO_OBJECT->{ $fname } )
                {
                    my $ref = $CACHE_TO_OBJECT->{ $fname } || next;
                    next if( ref( $ref ) ne 'ARRAY' );
                    printf( STDERR "\t${prefix}: %d objects associated with cache file \"${fname}\".\n", scalar( @$ref ) ) if( $DEBUG >= 4 );
                    my $addr = Scalar::Util::refaddr( $cache );
                    @$ref = grep{ ref( $_ // '' ) && Scalar::Util::refaddr( $_ ) != $addr } @$ref;
                    # Only remove file if no one else is using it
                    unless( @$ref )
                    {
                        if( $cache->destroy && $cache->id && !$cache->removed )
                        {
                            print( STDERR "\t${prefix}: Removing cache file \"${fname}\"\n" ) if( $DEBUG >= 4 );
                            $cache->remove;
                        }
                        delete( $CACHE_TO_OBJECT->{ $fname } );
                    }
                }
            }
            else
            {
                if( exists $CACHE_TO_OBJECT->{ $fname } )
                {
                    my $ref = $CACHE_TO_OBJECT->{ $fname } || next;
                    next if( ref( $ref ) ne 'ARRAY' );
                    printf( STDERR "\t${prefix}: %d objects associated with cache file \"${fname}\".\n", scalar( @$ref ) ) if( $DEBUG >= 4 );
                    my $addr = Scalar::Util::refaddr( $cache );
                    @$ref = grep{ ref( $_ // '' ) && Scalar::Util::refaddr( $_ ) != $addr } @$ref;
                    # Only remove file if no one else is using it
                    unless( @$ref )
                    {
                        if( $cache->destroy && $cache->id && !$cache->removed )
                        {
                            print( STDERR "\t${prefix}: Removing cache file \"${fname}\"\n" ) if( $DEBUG >= 4 );
                            $cache->remove;
                        }
                        delete( $CACHE_TO_OBJECT->{ $fname } );
                    }
                }
            }
        }
        else
        {
            $cache->remove;
        }
    }
};

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

Module::Generic::File::Cache - File-based Cache

=head1 SYNOPSIS

    use Module::Generic::File::Cache;
    my $cache = Module::Generic::File::Cache->new(
        key => 'something',
        create => 1,
        mode => 0666,
        base64 => 1,
        # Could also be CBOR, Storable::Improved
        serialiser => 'Sereal',
    ) || die( Module::Generic::File::Cache->error, "\n" );

=head1 VERSION

    v0.2.10

=head1 DESCRIPTION

This module provides a file-based shared space that can be shared across proceses. It behaves like L<Module::Generic::SharedMem>, but instead of using shared memory block that requires L<IPC::SysV>, it uses a file.

This is particularly useful for system that lack support for shared cache. See L<perlport> for that.

=head1 METHODS

=head2 new

This instantiates a shared cache object. It takes the following parameters:

=over 4

=item I<base64>

When set, this will instruct the serialiser used (see option I<serialiser>) to base64 encode and decode the data before writing and after reading.

The value can be either a simple true value, such as C<1>, or a base64 encoder/decoder. Currently the only supported ones are: L<Crypt::Misc> and L<MIME::Base64>, or it can also be an array reference of 2 code references, one for encoding and one for decoding.

=item I<cbor>

Provided with a value (true or false does not matter), and this will set L<CBOR::XS> as the data serialisation mechanism when storing data to cache file.

=item I<debug>

A debug value will enable debugging output (equal or above 3 actually)

=item I<create>

A boolean value to indicate whether the shared cache file should be created if it does not exist. Default to false.

=item I<destroy>

A boolean value to indicate if the shared cache file should be removed when the object is destroyed upon end of the script process.

See L<perlmod> for more about object destruction.

=item I<json>

Provided with a value (true or false does not matter), and this will set L<JSON> as the data serialisation mechanism when storing data to cache file.

Please note that if you want to store objects, you need to use I<cbor>, I<sereal> or I<storable> instead, because L<JSON> is not suitable to serialise objects.

=item I<key>

The shared cache key identifier to use. It defaults to a random one created with L</rand>

If you provide an empty value, it will revert to one created with L</rand>.

If you provide a number, it will be used to call L</ftok>.

Otherwise, if you provide a key as string, the characters in the string will be converted to their numeric value and added up. The resulting id will be used to call L</ftok> and will produce a unique and repeatable value.

Either way, the resulting value is used to create a shared cache file by L</open>.

=item I<mode>

The octal mode value to use when opening the shared cache file.

Shared cache files are owned by system users and access to shared cache files is ruled by the initial permissions set to it.

If you do not want to share it with any other user than yourself, setting mode to C<0600> is fine.

=item I<sereal>

Provided with a value (true or false does not matter), and this will set L<Sereal> as the data serialisation mechanism when storing data to cache file.

=item I<serialiser>

The class name of the serialiser to use. Currently supported ones are: L<CBOR|CBOR::XS>, L<Sereal>, L<Storable::Improved> (or the legacy L<Storable>)

=item I<size>

The size in byte of the shared cache.

This is set once it is created. You can create again the shared cache file with a smaller size. No need to remove it first.

=item I<storable>

Provided with a value (true or false does not matter), and this will set L<Storable::Improved> as the data serialisation mechanism when storing data to cache file.

=item I<tmpdir>

The temporary directory to use to store the cache files. By default this is the system standard temporary directory.

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

=head2 base64

When set, this will instruct the serialiser used (see option I<serialiser>) to base64 encode and decode the data before writing and after reading.

The value can be either a simple true value, such as C<1>, or a base64 encoder/decoder. Currently the only supported ones are: L<Crypt::Misc> and L<MIME::Base64>, or it can also be an array reference of 2 code references, one for encoding and one for decoding.

=head2 binmode

=head2 cbor

When called, this will set L<CBOR::XS> as the data serialisation mechanism when storing data to cache file or reading data from cache file.

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

=head2 id

Returns the id or serial of the cache file set after having opened it with L</open>

=head2 json

Sets the data serialising method to L<JSON>

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

Create an access to the cache file and return a new L<Module::Generic::File::Cache> object.

    my $cache = Module::Generic::File::Cache->new(
        create => 1,
        destroy => 0,
        # If not provided, will use the one provided during object instantiation
        key => 'my_cache',
        # 64K
        size => 65536,
    ) || die( Module::Generic::File::Cache->error );
    # Overriding some default value set during previous object instantiation
    my $c = $cache->open({
        mode => 0600,
        size => 1024,
    }) || die( $cache->error );

If the L</create> option is set to true, but the cache file already exists, L</open> will detect it and attempt to open access to the cache file without the L</create> bit on.

=head2 owner

Sets or gets the cache file owner, which is by default actually the process id (C<$$>)

=head2 rand

Get a random key to be used as identifier to create a shared cache.

=head2 read

Read the content of the shared cached and decode the data read using L<JSON>, L<CBOR|CBOR::XS>, L<Sereal> or L<Storable/thaw> depending on your choice of serialiser upon either object instantiation or upon using the methods L</json>, L</cbor>, L</sereal> or L</storable> or even more simply L</serialiser>

By default, if no serialiser is specified, it will default to C<storable>.

You can optionally provide a buffer, and a maximum length and it will read that much length and put the shared cache content decoded in that buffer, if it were provided.

It then return the length read, or C<0E0> if no data was retrieved. C<0E0> still is treated as 0, but as a positive value, so you can do:

    my $len = $cache->read( $buffer ) || die( $cache->error );

But you really should more thoroughly do instead:

    my( $len, $buffer );
    if( !defined( $len = $cache->read( $buffer ) ) )
    {
        die( $cache->error );
    }

If you do not provide any buffer, you can call L</read> like this and it will return you the shared cache decoded content:

    my $buffer;
    if( !defined( $buffer = $cache->read ) )
    {
        die( $cache->error );
    }

The content is stored in shared cache after being encoded with the serialiser of choice.

=head2 remove

Remove entire the shared cache identified with L</key>

=head2 removed

Returns true if the shared cache was removed, false otherwise.

=head2 reset

Reset the shared cache value. If a value is provided, it will be used as the new reset value, othewise an empty string will be used.

=head2 serial

Returns the serial number used to create or access the shared cache.

This serial is created based on the I<key> parameter provided either upon object instantiation or upon using the L</open> method.

The serial is created by calling L</ftok> to provide a reliable and repeatable numeric identifier. L</ftok> is a simili polyfill of L<IPC::SysV/ftok>

=head2 serialiser

Sets or gets the serialiser. Possible values are: C<cbor>, C<json>, C<sereal>, C<storable>

=head2 size

Sets or gets the shared cache size.

This should be an integer representing bytes, so typically a multiple of 1024.

This has not much effect, except ensuring there is enough space on the filesystem for the cache and that whatever data is provided does not exceed that threshold.

=head2 stat

Sets or retrieve value with L<Module::Generic::File/stat> for the underlying cache file.

It returns a L<Module::Generic::SemStat> object.

=head2 storable

When called, this will set L<Storable> as the data packing mechanism when storing data to memory.

=head2 supported

Returns always true as cache file relies solely on file.

=head2 tmpdir

The temporary directory to use to save cache file. By default, this will be the system standard temporary directory.

=head2 unlock

Remove the lock, if any. The shared cache must first be opened.

    $cache->unlock || die( $cache->error );

=head2 write

Write the data provided to the shared cache, after having encoded it using L<JSON>, L<CBOR|CBOR::XS>, L<Sereal> or L<Storable/freeze> depending on your serialiser of choice. See L</json>, L</cbor>, L</sereal> and L</storable> and more simply L</serialiser>

By default, if no serialiser is specified, it will default to C<storable>.

You can store in shared cache any kind of data excepted glob, such as scalar reference, array or hash reference. You could also store module objects, but L<JSON> only supports encoding objects that are based on array or hash. As the L<JSON> documentation states "other blessed references will be converted into null"

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
