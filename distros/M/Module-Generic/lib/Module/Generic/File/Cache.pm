##----------------------------------------------------------------------------
## Module Generic - ~/lib/Module/Generic/File/Cache.pm
## Version v0.1.0
## Copyright(c) 2022 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2022/03/16
## Modified 2022/03/16
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
    use vars qw( $CACHE_REPO $CACHE_TO_OBJECT $DEBUG );
    use Data::UUID;
    use Module::Generic::File qw( file sys_tmpdir );
    use Nice::Try;
    use JSON 4.03 qw( -convert_blessed_universally );
    use Scalar::Util ();
    use Storable 3.25 ();
    # Hash of cache file to objects to maintain the shared cache file objects created
    $CACHE_REPO = [];
    $CACHE_TO_OBJECT = {};
    $DEBUG = 0;
    our $VERSION = 'v0.1.0';
};

use strict;
use warnings;

sub init
{
    my $self = shift( @_ );
    $self->{binmode}    = 'utf-8';
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
    $self->{_init_strict_use_sub} = 1;
    # Storable keps breaking :(
    # I leave the feature of using it as a choice to the user, but defaults to JSON
    $self->{_packing_method} = 'json';
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    my $tmpdir = sys_tmpdir();
    $self->{_cache_dir} = $tmpdir->child( 'cache_file' );
    $self->{_cache_file} = '';
    $self->{id}         = undef();
    $self->{locked}     = 0;
    $self->{owner}      = $$;
    $self->{removed}    = 0;
    return( $self );
}

sub binmode { return( shift->_set_get_scalar( 'binmode', @_ ) ); }

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
    $self->message( 3, "Adding create bit." ) if( $opts->{create} );
    $flags    |= 0600 if( $opts->{create} );
    $self->message( 3, "Adding exclusive bit" ) if( $opts->{exclusive} );
    $flags    |= ( $opts->{mode} || 0666 );
    $self->message( 3, "Returning flags value '$flags'." );
    return( $flags );
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
        $self->message( 3, "Setting key to '$self->{key}' ($self->{serial})" );
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
        $self->message( 4, "Getting serial based on key '$opts->{key}'." );
        $serial = $self->_str2key( $opts->{key} ) || 
            return( $self->error( "Cannot get serial from key '$opts->{key}': ", $self->error ) );
    }
    else
    {
        $self->message( 3, "Getting serial ($self->{serial})" );
        $serial = $self->serial;
        $self->message( 4, "Got saved serial '$serial' ($self->{serial})." );
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
    $self->message( 4, "Using flags $flags and cache directory \"${cache_dir}\" and serial '${serial}' with create boolean set to '${create}'." );
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
    $self->message( 4, "Cache file to use is '${cache_file}'" );
    my $io;
    if( $fo->exists )
    {
        $self->message( 4, "Cache file ${cache_file} already exists." );
        # Need to find a way to make that more efficient
        if( ( $flags & 0600 ) || 
            ( $flags & 0060 ) ||
            ( $flags & 0006 ) )
        {
            $self->message( 4, "Flags ($flags) require write privilege to the cache file." );
            return( $self->error( "Requested mode ($flags) requires writing, but uid $> is missing write privilege to the cache file \"$cache_file\"." ) ) if( !$fo->can_write );
            $self->message( 4, "Opening cache file ${cache_file} in read append mode." );
            $io = $fo->open( '+<', { binmode => $opts->{binmode}, autoflush => 1 } ) ||
                return( $self->pass_error( $fo->error ) );
            # Ok, we could write to the cache file, remove data we just wrote
            $fo->seek(0,0) || return( $self->pass_error( $fo->error ) );
            # $fo->truncate( $fo->tell ) || return( $self->pass_error( $fo->error ) );
        }
        else
        {
            $self->message( 4, "Flags ($flags) require only read priviles." );
            return( $self->error( "Requested mode ($flags) require reading, but missing access privilege to the cache file \"$cache_file\"." ) ) if( !$fo->can_read );
            $self->message( 4, "Opening cache file ${cache_file} in read-only mode." );
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
            $self->message( 4, "Cache file ${cache_file} does not already exist, creating it now." );
            $io = $fo->open( '+>', { binmode => $opts->{binmode}, autoflush => 1 } ) ||
                return( $self->pass_error( $fo->error ) );
            # Some size, was provided, we fill the file with it, thus ensuring the filesystem lets us use that much
            # Subsequent calls to write(9 will clobber the file and truncate it to the actual size
            # but no more than the size if it was provided.
            if( $opts->{size} )
            {
                $self->message( 4, "The 'size' parameter was provided with value '$opts->{size}', trying to fill the file with that much bytes." );
                $self->_fill( $opts->{size} => $fo ) || return( $self->pass_error );
            }
        }
        else
        {
            $self->message( 4, "Cache file ${cache_file} does not already exist, and flags ($flags) are only in read-only mode." );
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
    $new->key( $self->key );
    $new->serial( $serial );
    $new->id( Scalar::Util::refaddr( $new ) );
    $new->size( $opts->{size} );
    $new->{_cache_file} = $fo;
    $self->message( 4, "Adding new object to global object repo and returning it." );
    push( @$CACHE_REPO, $new );
    $CACHE_TO_OBJECT->{ $cache_file } = [] if( !CORE::exists( $CACHE_TO_OBJECT->{ $cache_file } ) );
    CORE::push( @{$CACHE_TO_OBJECT->{ $cache_file }}, $new );
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
    $self->messagef( 4, "Reading from cache file \"${file}\" that is %d bytes big.", $file->size );
    $file->lock;
    # Make sure we are at the top of the file
    $file->seek(0,0) || return( $self->pass_error( $file->error ) );
    my $buffer = '';
    my $bytes = $file->read( $buffer, $file->length );
    $file->unlock;
    $self->messagef( 4, "${bytes} bytes read with a buffer now of size %d, unpacking data now.", CORE::length( $buffer ) );
    return( $self->pass_error( $file->error ) ) if( !defined( $bytes ) );
    my $packing = $self->_packing_method;
    my $data;
    if( CORE::length( $buffer ) )
    {
        try
        {
            if( $packing eq 'json' )
            {
                $data = $self->_decode_json( $buffer );
            }
            else
            {
                $data = Storable::thaw( $buffer );
            }
            $self->message( 4, "Decoded data '$buffer' -> '$data': ", sub{ $self->dump( $data ) });
        }
        catch( $e )
        {
            return( $self->error( "An error occured while decoding data using $packing: $e", ( length( $buffer ) <= 1024 ? "\nData is: '$buffer'" : '' ) ) );
        }
    }
    else
    {
        $data = $buffer;
    }
    
    $self->messagef( 4, "Unpacked data is now %d bytes.", CORE::length( $data ) );
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
    $self->message( 4, "Checking to remove cache file \"${file}\"." );
    if( !$file->exists )
    {
        $self->message( 4, "Cache file \"${file}\" already does not exist." );
        $self->removed(1);
        return( $self );
    }
    $file->unlock;
    my $rv = $file->delete;
    return( $self->pass_error( $file->error ) ) if( !defined( $rv ) );
    $self->removed( $rv ? 1 : 0 );
    if( $rv )
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
        $self->{_cache_file} = '';
        $self->id( undef() );
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
    $self->message( 4, "Resetting file cache \"${file}\" with content '$default'" );
    $file->lock( exclusive => 1 );
    $self->write( $default );
    $file->unlock;
    return( $self );
}

sub serial { return( shift->_set_get_scalar( 'serial', @_ ) ); }

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
    my $size = int( $self->size );
    $self->message( 4, "Writing ${data} to cache file \"${file}\"." );
    my $packing = $self->_packing_method;
    my $encoded;
    try
    {
        if( $packing eq 'json' )
        {
            $encoded = $self->_encode_json( $data );
        }
        else
        {
            $encoded = Storable::freeze( $data );
        }
    }
    catch( $e )
    {
        return( $self->error( "An error occured encoding data provided using $packing: $e. Data was: '$data'" ) );
    }
    
    if( $size > 0 && length( $encoded ) > $size )
    {
        return( $self->error( "Data to write are ", length( $encoded ), " bytes long and exceed the maximum you have set of '$size'." ) );
    }
    
    $self->messagef( 4, "Writing %d bytes of encoded data to cache file \"${file}\".", CORE::length( $encoded ) );
    $file->lock;
    $file->seek(0,0);
    $file->print( $encoded );
    $file->flush;
    $self->messagef( 4, "Position in cache file \"${file}\" is %d", $file->tell );
    $file->truncate( $file->tell );
    $file->unlock;
    $self->messagef( 4, "Cache file \"${file}\" is %d bytes big.", $file->length );
    # $self->message( 3, "Successfully wrote ", length( $encoded ), " bytes of data to memory." );
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
    
    try
    {
        my $decoded = $j->decode( $data );
        my $result = $crawl->( $decoded );
        return( $result );
    }
    catch( $e )
    {
        return( $self->error( "An error occurred while trying to decode JSON data: $e" ) );
    }
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
    try
    {
        my $encoded = $j->encode( $ref );
        return( $encoded );
    }
    catch( $e )
    {
        return( $self->error( "An error occurred while trying to JSON encode data: $e" ) );
    }
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
    elsif( $key =~ /^\d+$/ )
    {
        my $rand = $key;
        my $id = $self->ftok( $key ) ||
            return( $self->error( "Unable to get a key using IPC::SysV::ftok: $!" ) );
        return( $id );
    }
    else
    {
        my $id = 0;
        $id += $_ for( unpack( "C*", $key ) );
        # We use the root as a reliable and stable path.
        # I initially though about using __FILE__, but during testing this would be in ./blib/lib and beside one user might use a version of this module somewhere while the one used under Apache/mod_perl2 could be somewhere else and this would render the generation of the IPC key unreliable and unrepeatable
        my $val = $self->ftok( $id );
        $self->message( 4, "Calling ftok() for key '$key' with numeric id '$id' returning '$val'." );
        return( $val );
    }
}

sub DESTROY
{
    my $self = shift( @_ );
    return unless( CORE::exists( $self->{_cache_file} ) && defined( $self->{_cache_file} ) && CORE::length( $self->{_cache_file} ) );
    my $cache_file = '';
    $cache_file = $self->{_cache_file} if( CORE::length( $self->{_cache_file} ) );
    # $self->message( 4, "Called for cache file \"${cache_file}\" (", overload::StrVal( $cache_file ), ") with destroy flag set to '$self->{destroy}'" );
    $self->unlock;
    if( $self->destroy )
    {
        # $self->message( 4, "Cache file \"${cache_file}\" (", overload::StrVal( $cache_file ), " is to be destroyed." );
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
            $self->message( 4, "Any other object left? ", scalar( @$ref ) ? 'yes' : 'no' );
            $self->remove if( !scalar( @$ref ) );
        }
    }
};

# NOTE: END
END
{
    my $prefix = __PACKAGE__ . '::END';
    printf( STDERR "${prefix}: %d objects in repo to check.\n", scalar( @$CACHE_REPO ) ) if( $DEBUG >= 4 );
    no warnings;
    foreach my $obj ( @$CACHE_REPO )
    {
        if( !Scalar::Util::blessed( $obj ) || ref( $obj ) ne 'Module::Generic::File::Cache' )
        {
            warn( "${prefix}: Object found in object repo is not a Module::Generic::File::Cache object.\n" );
            next;
        }
        elsif( !exists( $obj->{_cache_file} ) || !CORE::length( $obj->{_cache_file} ) )
        {
            next;
        }
        elsif( !Scalar::Util::blessed( $obj->{_cache_file} ) ||
               ( Scalar::Util::blessed( $obj->{_cache_file} ) && !$obj->{_cache_file}->isa( 'Module::Generic::File' ) ) )
        {
            warn( "${prefix}: File object found in _cache_file (", overload::StrVal( $obj->{_cache_file} ), ") is actually not a Module::Generic::File, which is weird.\n" );
            next;
        }
        my $fname = "$obj->{_cache_file}";
        print( STDERR "\t${prefix}: Cache file is: \"${fname}\"\n" ) if( $DEBUG >= 4 );
        next if( !defined( $fname ) || !length( $fname ) );
        my $ref = $CACHE_TO_OBJECT->{ $fname } || next;
        next if( ref( $ref ) ne 'ARRAY' );
        printf( STDERR "\t${prefix}: %d objects associated with cache file \"${fname}\".\n", scalar( @$ref ) ) if( $DEBUG >= 4 );
        my $addr = Scalar::Util::refaddr( $obj );
        for( my $i = 0; $i <= $#$ref; $i++ )
        {
            if( Scalar::Util::refaddr( $ref->[$i] ) eq $addr )
            {
                splice( @$ref, $i, 1 );
                $i--;
            }
        }
        next if( $obj->removed || !$obj->id || !$obj->destroy );
        print( STDERR "\t${prefix}: Removing cache file \"${fname}\"\n" ) if( $DEBUG >= 4 );
        $obj->remove;
    }
};


1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

Module::Generic::File::Cache - Module Generic

=head1 SYNOPSIS

    use Module::Generic::File::Cache;
    my $cache = Module::Generic::File::Cache->new(
        key => 'something',
        create => 1,
        mode => 0666,
    ) || die( Module::Generic::File::Cache->error, "\n" );

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

This module provides a file-based shared space that can be shared across proceses. It behaves like L<Module::Generic::SharedMem>, but instead of using shared memory block that requires L<IPC::SysV>, it uses a file.

This is particularly useful for system that lack support for shared cache. See L<perlport> for that.

=head1 METHODS

=head2 new

This instantiates a shared cache object. It takes the following parameters:

=over 4

=item I<debug>

A debug value will enable debugging output (equal or above 3 actually)

=item I<create>

A boolean value to indicate whether the shared cache file should be created if it does not exist. Default to false.

=item I<destroy>

A boolean value to indicate if the shared cache file should be removed when the object is destroyed upon end of the script process.

See L<perlmod> for more about object destruction.

=item I<json>

Provided with a value (true or false does not matter), and this will set L<JSON> as the data packing mechanism when storing data to memory.

Please note that if you want to store objects, you need to use I<storable> instead, because L<JSON> is not suitable to serialise objects.

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

=item I<size>

The size in byte of the shared cache.

This is set once it is created. You can create again the shared cache file with a smaller size. No need to remove it first.

=item I<storable>

Provided with a value (true or false does not matter), and this will set L<Storable> as the data packing mechanism when storing data to cache file.

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

=head2 binmode

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

Read the content of the shared cached and decode the data read using L<JSON> or L<Storable/thaw> depending on your choice upon either object instantiation or upon using the methods L</json> or L</storable>

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

The content is stored in shared cache after being encoded with L<Storable/freeze>.

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

=head2 unlock

Remove the lock, if any. The shared cache must first be opened.

    $cache->unlock || die( $cache->error );

=head2 write

Write the data provided to the shared cache, after having encoded it using L<JSON> or L<Storable/freeze> depending on your choice. See L</json> and L</storable>

You can store in shared cache any kind of data excepted glob, such as scalar reference, array or hash reference. You could also store module objects, but L<JSON> only supports encoding objects that are based on array or hash. As the L<JSON> documentation states "other blessed references will be converted into null"

It returns the current object for chaining, or C<undef> if there was an error, which can then be retrieved with L<Module::Generic/error>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Module::Generic::SharedMem>, L<Cache::File>, L<File::Cache>, L<Cache::FileCache>

L<JSON>, L<Storable>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2022 DEGUEST Pte. Ltd.

All rights reserved
This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
