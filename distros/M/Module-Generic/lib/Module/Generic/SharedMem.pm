##----------------------------------------------------------------------------
## Module Generic - ~/lib/Module/Generic/SharedMem.pm
## Version v0.4.1
## Copyright(c) 2023 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2021/01/18
## Modified 2024/09/05
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Module::Generic::SharedMem;
BEGIN
{
    use strict;
    use warnings;
    use warnings::register;
    use parent qw( Module::Generic );
    use vars qw( $SUPPORTED_RE $SYSV_SUPPORTED $SEMOP_ARGS $SHEM_REPO $ID2OBJ $N $HAS_B64 );
    use Config;
    use File::Spec ();
    # use Nice::Try;
    use Scalar::Util ();
    use JSON 4.03 qw( -convert_blessed_universally );
    use Storable::Improved ();
    use constant SHM_BUFSIZ     =>  65536;
    use constant SEM_LOCKER     =>  0;
    use constant SEM_MARKER     =>  0;
    use constant SHM_LOCK_WAIT  =>  0;
    use constant SHM_LOCK_EX    =>  1;
    use constant SHM_LOCK_UN    => -1;
    use constant SHM_EXISTS     =>  1;
    use constant LOCK_SH        =>  1;
    use constant LOCK_EX        =>  2;
    use constant LOCK_NB        =>  4;
    use constant LOCK_UN        =>  8;
    # if( $^O =~ /^(?:Android|cygwin|dos|MSWin32|os2|VMS|riscos)/ )
    # Even better
    $SUPPORTED_RE = qr/IPC\/SysV/;
    if( $Config{extensions} =~ /$SUPPORTED_RE/ && 
        $^O !~ /^(?:Android|dos|MSWin32|os2|VMS|riscos)/i &&
        # we need semaphore and messages
        $Config{d_msg} eq 'define' &&
        $Config{d_sem} eq 'define' &&
        $Config{d_semctl} eq 'define' &&
        $Config{d_semget} eq 'define' &&
        $Config{d_semop} eq 'define' &&
        $Config{d_shm} eq 'define' &&
        $Config{d_shmat} eq 'define' &&
        $Config{d_shmctl} eq 'define' &&
        $Config{d_shmdt} eq 'define' &&
        $Config{d_shmget} eq 'define'
        )
    {
        require IPC::SysV;
        IPC::SysV->import( qw( IPC_RMID IPC_PRIVATE IPC_SET IPC_STAT IPC_CREAT IPC_EXCL IPC_NOWAIT
                               SEM_UNDO S_IRWXU S_IRWXG S_IRWXO S_IRUSR S_IWUSR
                               GETNCNT GETZCNT GETVAL SETVAL GETPID GETALL SETALL
                               shmat shmdt memread memwrite ftok ) );
        $SYSV_SUPPORTED = 1;
        no strict 'subs';
        eval( <<'EOT' );
        our $SEMOP_ARGS = 
        {
            (LOCK_EX) =>
            [       
                1, 0, 0,                        # wait for readers to finish
                2, 0, 0,                        # wait for writers to finish
                2, 1, SEM_UNDO,                 # assert write lock
            ],
            (LOCK_EX | LOCK_NB) =>
            [
                1, 0, IPC_NOWAIT,               # wait for readers to finish
                2, 0, IPC_NOWAIT,               # wait for writers to finish
                2, 1, (SEM_UNDO | IPC_NOWAIT),  # assert write lock
            ],
            (LOCK_EX | LOCK_UN) =>
            [
                2, -1, (SEM_UNDO | IPC_NOWAIT),
            ],
            (LOCK_SH) =>
            [
                2, 0, 0,                        # wait for writers to finish
                1, 1, SEM_UNDO,                 # assert shared read lock
            ],
            (LOCK_SH | LOCK_NB) =>
            [
                2, 0, IPC_NOWAIT,               # wait for writers to finish
                1, 1, (SEM_UNDO | IPC_NOWAIT),  # assert shared read lock
            ],
            (LOCK_SH | LOCK_UN) =>
            [
                1, -1, (SEM_UNDO | IPC_NOWAIT), # remove shared read lock
            ],
        };
EOT
        if( $@ )
        {
            warn( "Error while trying to eval \$SEMOP_ARGS: $@\n" );
        }
    }
    else
    {
        $SYSV_SUPPORTED = 0;
    }
    # Credits IPC::SysV
    $N = do { my $foo = eval { pack "L!", 0 }; $@ ? '' : '!' };
    # Array to maintain the order in which shared memory object were created, so they can
    # be removed in that order
    $SHEM_REPO = [];
    $ID2OBJ    = {};
    
    our @EXPORT_OK = qw(LOCK_EX LOCK_SH LOCK_NB LOCK_UN);
    our %EXPORT_TAGS = (
            all     => [qw( LOCK_EX LOCK_SH LOCK_NB LOCK_UN )],
            lock    => [qw( LOCK_EX LOCK_SH LOCK_NB LOCK_UN )],
            'flock' => [qw( LOCK_EX LOCK_SH LOCK_NB LOCK_UN )],
    );
    our $VERSION = 'v0.4.1';
};

# use strict;
no warnings 'redefine';

sub init
{
    my $self = shift( @_ );
    $self->{base64}     = undef;
    # Default action when accessing a shared memory? If 1, it will create it if it does not exist already
    $self->{create}     = 0;
    # If true, this will destroy both the shared memory and the semaphore upon end
    $self->{destroy}    = 0;
    # If true, this will destroy only the semaphore upon end
    $self->{destroy_semaphore} = 0;
    $self->{exclusive}  = 0;
    no strict 'subs';
    $self->{key}        = &IPC::SysV::IPC_PRIVATE if( $SYSV_SUPPORTED );
    $self->{mode}       = 0666;
    $self->{serial}     = '';
    # SHM_BUFSIZ
    $self->{size}       = SHM_BUFSIZ;
    $self->{_init_strict_use_sub} = 1;
    # $self->{_packing_method} = 'storable';
    # Storable keps breaking :(
    # I leave the feature of using it as a choice to the user, but defaults to JSON
    $self->{_packing_method} = 'json';
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    $self->{addr}       = undef();
    $self->{id}         = undef();
    $self->{locked}     = 0;
    $self->{owner}      = $$;
    $self->{removed}    = 0;
    $self->{removed_semaphore} = 0;
    $self->{semid}      = undef();
    return( $self );
}

sub addr { return( shift->_set_get_scalar( 'addr', @_ ) ); }

# This class does not convert to an HASH
sub as_hash { return( $_[0] ); }

sub attach
{
    my $self = shift( @_ );
    my $flags = shift( @_ );
    $flags = $self->flags if( !defined( $flags ) );
    my $addr = $self->addr;
    return( $addr ) if( defined( $addr ) );
    my $id = $self->id;
    return( $self->error( "No shared memory id! Have you opened it first?" ) ) if( !length( $id ) );
    $addr = shmat( $id, undef(), $flags );
    return( $self->error( "Unable to attach to shared memory: $!" ) ) if( !defined( $addr ) );
    $self->addr( $addr );
    return( $addr );
}

sub base64 { return( shift->_set_get_scalar( 'base64', @_ ) ); }

sub cbor { return( shift->_packing_method( 'cbor' ) ); }

sub create { return( shift->_set_get_boolean( 'create', @_ ) ); }

sub delete { return( shift->remove( @_ ) ); }

sub destroy
{
    my $self = shift( @_ );
    if( @_ )
    {
        my $val = shift( @_ );
        $self->_set_get_boolean( 'destroy', $val );
        $self->_set_get_boolean( 'destroy_semaphore', $val );
    }
    return( $self->_set_get_boolean( 'destroy' ) );
}

sub destroy_semaphore { return( shift->_set_get_boolean( 'destroy_semaphore', @_ ) ); }

sub detach
{
    my $self = shift( @_ );
    my $addr = $self->addr;
    return if( !defined( $addr ) );
    my $rv = shmdt( $addr );
    return( $self->error( "Unable to detach from shared memory: $!" ) ) if( !defined( $rv ) );
    $self->addr( undef() );
    return( $self );
}

sub exclusive { return( shift->_set_get_boolean( 'exclusive', @_ ) ); }

sub exists
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
    my $serial;
    if( length( $opts->{key} ) )
    {
        $serial = $self->_str2key( $opts->{key} );
        # $serial = $opts->{key};
    }
    else
    {
        $serial = $self->serial;
        # $serial = $self->key;
    }
    my $flags = $self->flags({ mode => 0644 });
    # Remove the create bit
    no strict 'subs';
    $flags = ( $flags ^ &IPC::SysV::IPC_CREAT );
    my $semid;
    # try-catch
    local $@;
    my @rv = eval
    {
        $semid = semget( $serial, 0, $flags );
        if( defined( $semid ) )
        {
            my $arg = 0;
            my $found = semctl( $semid, SEM_MARKER, &IPC::SysV::GETVAL, $arg );
            $arg = 0;
            semctl( $semid, 0, &IPC::SysV::IPC_RMID, $arg );
            return( $found == SHM_EXISTS ? 1 : 0 );
        }
        else
        {
            return(0) if( $! =~ /\bNo[[:blank:]]+such[[:blank:]]+file\b/ );
            return;
        }
    };
    if( $@ )
    {
        # warn( "Trying to access shared memory triggered error: $e" ) if( $self->_warnings_is_enabled );
        my $arg = 0;
        if( $semid )
        {
            # try-catch
            local $@;
            if( !eval
            {
                semctl( $semid, 0, &IPC::SysV::IPC_RMID, $arg );
            })
            {
                warn( "Error trying to remove semaphore id ${semid} after checking if shared memory existed: $@" ) if( $self->_warnings_is_enabled );
            }
        }
        return(0);
    }
    else
    {
        return( $rv[0] );
    }
}

sub flags
{
    my $self   = shift( @_ );
    my $opts   = $self->_get_args_as_hash( @_ );
    no warnings 'uninitialized';
    no strict 'subs';
    $opts->{create} = $self->create unless( length( $opts->{create} ) );
    $opts->{exclusive} = $self->exclusive unless( length( $opts->{exclusive} ) );
    $opts->{mode} = $self->mode unless( length( $opts->{mode} ) );
    my $flags  = 0;
    $flags    |= &IPC::SysV::IPC_CREAT if( $opts->{create} );
    $flags    |= &IPC::SysV::IPC_EXCL  if( $opts->{exclusive} );
    $flags    |= ( $opts->{mode} || 0666 );
    return( $flags );
}

# sub id { return( shift->_set_get_scalar( 'id', @_ ) ); }
sub id
{
    my $self = shift( @_ );
    my @callinfo = caller;
    no warnings 'uninitialized';
    if( @_ )
    {
        $self->{id} = shift( @_ );
    }
    return( $self->{id} );
}

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
    my $type = shift( @_ );
    my $timeout = shift( @_ );
    # $type = LOCK_EX if( !defined( $type ) );
    $type = LOCK_SH if( !defined( $type ) );
    return( $self->unlock ) if( ( $type & LOCK_UN ) );
    return(1) if( $self->locked & $type );
    $timeout = 0 if( !defined( $timeout ) || $timeout !~ /^\d+$/ );
    # If the lock is different, release it first
    $self->unlock if( $self->locked );
    my $semid = $self->semid;
    return( $self->error( "No semaphore id set yet." ) ) if( !defined( $semid ) );
    # try-catch
    local $@;
    my $rc;
    eval
    {
        local $SIG{ALRM} = sub{ die( "timeout" ); };
        alarm( $timeout );
        $rc = $self->op( @{$SEMOP_ARGS->{ $type }} );
        alarm(0);
    };
    if( $@ )
    {
        return( $self->error( "Unable to set a lock: $@" ) );
    }
    else
    {
        if( $rc )
        {
            $self->locked( $type );
        }
        else
        {
            return( $self->error( "Failed to set a lock on semaphore id \"$semid\" for lock type $type: $!" ) );
        }
    }
    return( $self );
}

sub locked { return( shift->_set_get_scalar( 'locked', @_ ) ); }

sub mode { return( shift->_set_get_scalar( 'mode', @_ ) ); }

sub op
{
    my $self = shift( @_ );
    return( $self->error( "No argument was provided!" ) ) if( !scalar( @_ ) );
    return( $self->error( "Invalid number of argument: '", join( ', ', @_ ), "'." ) ) if( @_ % 3 );
    my $id = $self->semid;
    return( $self->error( "No semaphore set yet. You must open the shared memory first to set the semaphore." ) ) if( !length( $id ) );
    my $data = pack( "s$N*", @_ );
    my $rv;
    no strict 'subs';
    $rv = semop( $id, $data ) || do
    {
        my $serial = $self->serial;
        my $semid = semget( $serial, 3, IPC_CREAT | 0666 );
        $rv = semop( $semid, $data );
    };
    return( $rv );
}

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
    no strict 'subs';
    my $serial;
    if( length( $opts->{key} ) )
    {
        $serial = $self->_str2key( $opts->{key} ) || 
            return( $self->error( "Cannot get serial from key '$opts->{key}': ", $self->error ) );
        # $serial = $opts->{key};
    }
    else
    {
        $serial = $self->serial;
        # $serial = $self->key;
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
    
    my $id;
    # try-catch
    local $@;
    eval
    {
        $id = shmget( $serial, $opts->{size}, $flags );
        if( defined( $id ) )
        {
            # All is ok.
        }
        else
        {
            my $newflags = ( $flags & &IPC::SysV::IPC_CREAT ) ? $flags : ( $flags | &IPC::SysV::IPC_CREAT );
            my $limit = ( $serial + 10 );
            # &IPC::SysV::ftok has likely made the serial unique, but as stated in the manual page, there is no guarantee
            while( $serial <= $limit )
            {
                $id = shmget( $serial, $opts->{size}, $newflags | &IPC::SysV::IPC_CREAT );
                $serial++;
                last if( defined( $id ) );
            }
        }
    };
    if( $@ )
    {
        if( $@ =~ /shmget[[:blank:]\h]+not[[:blank:]\h]+implemented/i )
        {
            return( $self->error( "IPC SysV is supported, but somehow shmget is not implemented: $@" ) );
        }
        else
        {
            return( $self->error( "Error while trying to get the shared memory id: $@" ) );
        }
    }
    
    if( !defined( $id ) )
    {
        return( $self->error( "Unable to create shared memory id with key \"$serial\" and flags \"$flags\": $!" ) );
    }
    $self->serial( $serial );
    
    # The value 3 can be anything above 0 and below the limit set by SEMMSL. On Linux system, this is usually 32,000. Seem semget(2) man page:
    # "The argument nsems can be 0 (a don't care) when a semaphore set is  not being  created.   Otherwise, nsems must be greater than 0 and less than or equal  to  the  maximum  number  of  semaphores  per  semaphore  set (SEMMSL)."
    my $semid;
    # try-catch
    local $@;
    eval
    {
        $semid = semget( $serial, ( $create ? 3 : 0 ), $flags );
        if( !defined( $semid ) )
        {
            my $newflags = ( $flags | &IPC::SysV::IPC_CREAT );
            $semid = semget( $serial, 3, $newflags );
        }
    };
    if( $@ )
    {
        if( $@ =~ /semget[[:blank:]\h]+not[[:blank:]\h]+implemented/i )
        {
            return( $self->error( "IPC SysV is supported, but somehow semget is not implemented: $@" ) );
        }
        else
        {
            return( $self->error( "Error while trying to get the semaphore for shared memory id: $@" ) );
        }
    }
    return( $self->error( "Unable to get a semaphore for shared memory key \"", ( $opts->{key} || $self->key ), "\" wth id \"$id\": $!" ) ) if( !defined( $semid ) );
    
    my $new = $self->new(
        key     => ( $opts->{key} || $self->key ),
        debug   => $self->debug,
        mode    => $self->mode,
        destroy => $self->destroy,
        destroy_semaphore => $self->destroy_semaphore,
        _packing_method => $self->_packing_method,
    ) || return( $self->error( "Cannot create object with key '", ( $opts->{key} || $self->key ), "': ", $self->error ) );
    $new->key( $self->key );
    $new->serial( $self->serial );
    $new->id( $id );
    $new->semid( $semid );
    CORE::push( @$SHEM_REPO, $id );
    $ID2OBJ->{ $id } = $new;
    if( !defined( $new->op( @{$SEMOP_ARGS->{(LOCK_SH)}} ) ) )
    {
        return( $self->error( "Unable to set lock on sempahore: $!" ) );
    }
    
    my $there = $new->stat( SEM_MARKER );
    $new->size( $opts->{size} );
    # $new->flags( $flags );
    if( $there == SHM_EXISTS )
    {
    }
    else
    {
        # We initialise the semaphore with value of 1
        $new->stat( SEM_MARKER, SHM_EXISTS ) ||
            return( $new->error( "Unable to set semaphore during object creation: ", $new->error ) );
    }
    
    $new->op( @{$SEMOP_ARGS->{(LOCK_SH | LOCK_UN)}} );
    return( $new );
}

sub owner { return( shift->_set_get_scalar( 'owner', @_ ) ); }

sub pid
{
    my $self = shift( @_ );
    my $sem  = shift( @_ );
    my $semid = $self->semid ||
        return( $self->error( "No semaphore set yet. You must open the shared memory first to remove semaphore." ) );
    no strict 'subs';
    my $arg = 0;
    # try-catch
    local $@;
    my @rv = eval
    {
        my $v = semctl( $semid, $sem, &IPC::SysV::GETPID, $arg );
        return( $v ? 0 + $v : undef() );
    };
    if( $@ )
    {
        return( $self->error( "Error trying to get semaphore pid using semaphore id ${semid}: $@" ) );
    }
    return( $rv[0] );
}

sub rand
{
    my $self = shift( @_ );
    my $size = $self->size || 1024;
    no strict 'subs';
    # try-catch
    local $@;
    my $key;
    eval
    {
        $key  = shmget( &IPC::SysV::IPC_PRIVATE, $size, &IPC::SysV::S_IRWXU | &IPC::SysV::S_IRWXG | &IPC::SysV::S_IRWXO );
    };
    if( $@ )
    {
        return( $self->error( "Error trying to get a random private key using shmget and IPC_PRIVATE: $@" ) );
    }
    if( !defined( $key ) )
    {
        return( $self->error( "Unable to generate a share memory key: $!" ) )
    }
    else
    {
        return( $key );
    }
}

# $self->read( $buffer, $size );
# $self->read( $buffer );
# my $data = $self->read;
sub read
{
    my( $self, $buf ) = @_;
    my $size;
    $size = int( $_[2] ) if( scalar( @_ ) > 2 );
    # Optional length parameter for non-reference data only
    $size //= int( $self->size || SHM_BUFSIZ );
    my $id = $self->id;
    return( $self->error( "No shared memory id! Have you opened it first?" ) ) if( !length( $id ) );
    my $buffer = '';
    my $addr = $self->addr;
    if( $addr )
    {
        memread( $addr, $buffer, 0, $size ) ||
            return( $self->error( "Unable to read data from shared memory address \"$addr\" using memread: $!" ) );
    }
    else
    {
        shmread( $id, $buffer, 0, $size ) ||
            return( $self->error( "Unable to read data from shared memory id \"$id\": $!" ) );
    }
    # Get rid of nulls end padded
    # 2022-08-03: Ok, null bytes are added to Storable and CBOR::XS serialised data, 
    # so we cannot just remove them. Instead we encapsulate the serialised data
    # $buffer = unpack( "A*", $buffer );
    my $packing = $self->_packing_method;
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
        }
    }
    else
    {
        $data = $buffer;
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
    my $id   = $self->id();
    return( $self->error( "No shared memory id! Have you opened it first?" ) ) if( !length( $id ) );
    my $semid = $self->semid;
    return( $self->error( "No semaphore set yet. You must open the shared memory first to remove semaphore." ) ) if( !length( $semid ) );
    $self->unlock();
    no strict 'subs';
    # Remove share memory segment
    if( !defined( shmctl( $id, &IPC::SysV::IPC_RMID, 0 ) ) )
    {
        return( $self->error( "Unable to remove share memory segement id '$id' (IPC_RMID is '", &IPC::SysV::IPC_RMID, "'): $!" ) );
    }
    # Remove semaphore
    my $rv;
    my $arg = 0;
    if( !defined( $rv = semctl( $semid, 0, &IPC::SysV::IPC_RMID, $arg ) ) )
    {
        warn( "Warning only: could not remove the semaphore id \"$semid\": $!" ) if( $self->_warnings_is_enabled );
    }
    $self->removed( $rv ? 1 : 0 );
    if( $rv )
    {
        for( my $i = 0; $i < scalar( @$SHEM_REPO ); $i++ )
        {
            my $this_id = $SHEM_REPO->[$i];
            my $obj = $ID2OBJ->{ $this_id };
            if( Scalar::Util::blessed( $obj ) && $this_id eq $id )
            {
                CORE::splice( @$SHEM_REPO, $i, 1 );
                CORE::delete( $ID2OBJ->{ $this_id } );
                last;
            }
        }
        $self->id( undef() );
        $self->semid( undef() );
    }
    return( $rv ? 1 : 0 );
}

sub remove_semaphore
{
    my $self = shift( @_ );
    return(1) if( $self->removed_semaphore );
    my $semid = $self->semid;
    return( $self->error( "No semaphore set yet. You must open the shared memory first to remove semaphore." ) ) if( !length( $semid ) );
    $self->unlock();
    my $rv;
    no strict 'subs';
    my $arg = 0;
    if( !defined( $rv = semctl( $semid, 0, &IPC::SysV::IPC_RMID, $arg ) ) )
    {
        warn( "Warning only: could not remove the semaphore id \"$semid\" with IPC::SysV::IPC_RMID value '", &IPC::SysV::IPC_RMID, "': $!" ) if( $self->_warnings_is_enabled );
    }
    $self->removed_semaphore( $rv ? 1 : 0 );
    $self->semid( undef() );
    return( $rv ? 1 : 0 );
}

sub removed { return( shift->_set_get_boolean( 'removed', @_ ) ); }

sub removed_semaphore { return( shift->_set_get_boolean( 'removed_semaphore', @_ ) ); }

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
    $self->lock( LOCK_EX );
    $self->write( $default );
    $self->unlock;
    return( $self );
}

sub semid { return( shift->_set_get_scalar( 'semid', @_ ) ); }

sub sereal { return( shift->_packing_method( 'sereal' ) ); }

sub serial { return( shift->_set_get_scalar( 'serial', @_ ) ); }

sub serialiser { return( shift->_set_get_scalar( '_packing_method', @_ ) ); }

{
    no warnings 'once';
    *serializer = \&serialiser;
}

sub shmstat
{
    my $self = shift( @_ );
    my $data = '';
    my $id = $self->id || return( $self->error( "No shared memory id set!" ) );
    no strict 'subs';
    shmctl( $id, &IPC::SysV::IPC_STAT, $data ) or
        return( $self->error( "Unable to stat shared memory with id '$id': $!" ) );
    return( Module::Generic::SharedStat->new->unpack( $data ) );
}

sub size { return( shift->_set_get_scalar( 'size', @_ ) ); }

sub stat
{
    my $self = shift( @_ );
    my $id   = $self->semid;
    return( $self->error( "No semaphore set yet. You must open the shared memory first to set the semaphore." ) ) if( !length( $id ) );
    no strict 'subs';
    if( @_ )
    {
        if( @_ == 1 )
        {
            my $sem = shift( @_ );
            my $arg = 0;
            my $v = semctl( $id, $sem, &IPC::SysV::GETVAL, $arg );
            return( $v ? 0 + $v : undef() );
        }
        else
        {
            my( $sem, $val ) = @_;
            semctl( $id, $sem, &IPC::SysV::SETVAL, $val ) ||
                return( $self->error( "Unable to semctl with semaphore id '$id', semaphore '$sem', SETVAL='", &IPC::SysV::SETVAL, "' and value='$val': $!" ) );
        }
    }
    else
    {
        my $data = '';
        if( wantarray() )
        {
            semctl( $id, 0, &IPC::SysV::GETALL, $data ) || return( () );
            return( ( unpack( "s$N*", $data ) ) );
        }
        else
        {
            semctl( $id, 0, &IPC::SysV::IPC_STAT, $data ) ||
                return( $self->error( "Unable to stat semaphore with id '$id': $!" ) );
            return( Module::Generic::SemStat->new->unpack( $data ) );
        }
    }
}

sub storable { return( shift->_packing_method( 'storable' ) ); }

sub supported { return( $SYSV_SUPPORTED ); }

sub unlock
{
    my $self = shift( @_ );
    return(1) if( !$self->locked );
    my $semid = $self->semid;
    return( $self->error( "No semaphore set yet. You must open the shared memory first to unlock semaphore." ) ) if( !length( $semid ) );
    my $type = ( $self->locked | LOCK_UN );
    $type ^= LOCK_NB if( $type & LOCK_NB );
    if( defined( $self->op( @{$SEMOP_ARGS->{ $type }} ) ) )
    {
        $self->locked(0);
    }
    return( $self );
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
    my $id   = $self->id();
    my $size = int( $self->size() ) || SHM_BUFSIZ;
    # my @callinfo = caller;
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
            return( $self->error( "An error occured encoding data provided using $packing with base64 set to '", ( $self->{base64} // '' ), ": $@. Data was: '$data'" ) );
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
            return( $self->error( "An error occured encoding data provided using $packing with base64 set to '", ( $self->{base64} // '' ), ": $@. Data was: '$data'" ) );
        }
        return( $self->error( "Unable to serialise ", CORE::length( $data ), " bytes of data using CBOR::XS with base64 set to '", ( $self->{base64} // '' ), ": ", $self->error ) ) if( !defined( $encoded ) );
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
            return( $self->error( "An error occured encoding data provided using $packing with base64 set to '", ( $self->{base64} // '' ), ": $@. Data was: '$data'" ) );
        }
        return( $self->error( "Unable to serialise ", CORE::length( $data ), " bytes of data using Sereal with base64 set to '", ( $self->{base64} // '' ), ": ", $self->error ) ) if( !defined( $encoded ) );
    }
    # Default to Storable::Improved
    else
    {
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
            return( $self->error( "An error occured encoding data provided using $packing with base64 set to '", ( $self->{base64} // '' ), ": $@. Data was: '$data'" ) );
        }
        return( $self->error( "Unable to serialise ", CORE::length( $data ), " bytes of data using Storable with base64 set to '", ( $self->{base64} // '' ), ": ", $self->error ) ) if( !defined( $encoded ) );
    }
    
    # Simple encapsulation
    # FYI: MG = Module::Generic
    substr( $encoded, 0, 0, 'MG[' . length( $encoded ) . ']' );
    
    my $len = length( $encoded );
    if( $len > $size )
    {
        return( $self->error( "Data to write are ", length( $encoded ), " bytes long and exceed the maximum you have set of '$size'." ) );
    }
    my $addr = $self->addr;
    if( $addr )
    {
        memwrite( $addr, $encoded, 0, $len ) ||
            return( $self->error( "Unable to write to shared memory address '$addr' using memwrite: $!" ) );
    }
    else
    {
        # id, data, position, size
        shmwrite( $id, $encoded, 0, $len ) ||
            return( $self->error( "Unable to write to shared memory id '$id' with ${len} bytes of data encoded and memory size of $size: $!" ) );
    }
    return( $self );
}

sub _decode_json
{
    my $self = shift( @_ );
    my $data = shift( @_ );
    # Nothing to do
    return( $data ) if( !defined( $data ) || !CORE::length( $data ) );
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
    
    my $result;
    # try-catch
    local $@;
    eval
    {
        my $decoded = $j->decode( $data );
        $result = $crawl->( $decoded );
    };
    if( $@ )
    {
        return( $self->error( "An error occurred while trying to decode JSON data: $@" ) );
    }
    return( $result );
}

# Purpose of this method is to recursively check the given data and change scalar reference if they are anything else than 1 or 0, otherwise JSON would complain
sub _encode_json
{
    my $self = shift( @_ );
    my $data = shift( @_ );
    my $seen = {};
    my $crawl;
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
        return( &IPC::SysV::IPC_PRIVATE );
    }
    my $path;
    ( $key, $path ) = ref( $key ) eq 'ARRAY' ? @$key : ( $key, [getpwuid($>)]->[7] );
    $path = [getpwuid($path)]->[7] if( $path =~ /^\d+$/ );
    $path ||= File::Spec->rootdir();
    if( $key =~ /^\d+$/ )
    {
        my $id = &IPC::SysV::ftok( $path, $key ) ||
            return( $self->error( "Unable to get a key using IPC::SysV::ftok: $!" ) );
        return( $id );
    }
    else
    {
        # my $id = 0;
        # $id += $_ for( unpack( "C*", $key ) );
        require Digest::SHA;
        my $hash = Digest::SHA::sha1_base64( $key );
        my $id = ord( substr( $hash, 0, 1 ) );
        # We use the root as a reliable and stable path.
        # I initially though about using __FILE__, but during testing this would be in ./blib/lib and beside one user might use a version of this module somewhere while the one used under Apache/mod_perl2 could be somewhere else and this would render the generation of the IPC key unreliable and unrepeatable
        # my $val = &IPC::SysV::ftok( File::Spec->rootdir(), $id );
        my $val = &IPC::SysV::ftok( $path, $id );
        return( $val );
    }
}

sub DESTROY
{
    my $self = shift( @_ );
    return unless( $self->{id} );
    $self->unlock;
    $self->detach;
    my $rv = $self->remove_semaphore;
    if( $self->destroy )
    {
        my $stat = $self->shmstat();
        # number of processes attached to the associated shared memory segment.
        if( defined( $stat ) && ( $stat->nattch() == 0 ) )
        {
            $self->remove;
        }
    }
};

sub FREEZE
{
    my $self = CORE::shift( @_ );
    my $serialiser = CORE::shift( @_ ) // '';
    my $class = CORE::ref( $self );
    my %hash  = %$self;
    CORE::delete( @hash{ qw( addr id locked owner removed removed_semaphore semid ) } );
    # Return an array reference rather than a list so this works with Sereal and CBOR
    # On or before Sereal version 4.023, Sereal did not support multiple values returned
    CORE::return( [$class, \%hash] ) if( $serialiser eq 'Sereal' && Sereal::Encoder->VERSION <= version->parse( '4.023' ) );
    # But Storable want a list with the first element being the serialised element
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

END
{
    foreach my $id ( @$SHEM_REPO )
    {
        my $s = $ID2OBJ->{ $id } || next;
        next if( $s->removed || !$s->id || !$s->destroy );
        $s->detach;
        $s->remove;
    }
};

# NOTE: Module::Generic::SharedStat class
{
    package
        Module::Generic::SharedStat;
    use IPC::SysV;
    require IPC::SharedMem;
    our $VERSION = 'v0.1.0';
    
    use constant UID    => 0;
    use constant GID    => 1;
    use constant CUID   => 2;
    use constant CGID   => 3;
    use constant MODE   => 4;
    use constant SEGSZ  => 5;
    use constant LPID   => 6;
    use constant CPID   => 7;
    use constant NATTCH => 8;
    use constant ATIME  => 9;
    use constant DTIME  => 10;
    use constant CTIME  => 11;

    sub new
    {
        my $this = shift( @_ );
        my @vals = @_;
        return( bless( [ @vals ] => ref( $this ) || $this ) );
    }
    
    sub unpack
    {
        my $self = shift( @_ );
        my $data = shift( @_ );
        # XS method
        my $d = IPC::SharedMem::stat->new->unpack( $data );
        # my @unpacked = unpack( "i*", $data );
        return( $self->new( @$d ) );
    }
    
    # time when the last attach was completed to the associated shared memory segment.
    sub atime { return( shift->[ATIME] ); }

    sub cgid { return( shift->[CGID] ); }
    
    # process ID of the creator of the shared memory entry.
    sub cpid { return( shift->[CPID] ); }

    # time when the associated entry was created or changed.
    sub ctime { return( shift->[CTIME] ); }
    
    sub cuid { return( shift->[CUID] ); }

    # time the last detach was completed on the associated shared memory segment.
    sub dtime { return( shift->[DTIME] ); }

    sub gid { return( shift->[GID] ); }
    
    # process ID of the last process to attach or detach the shared memory segment.
    sub lpid { return( shift->[LPID] ); }

    sub mode { return( shift->[MODE] ); }

    # number of processes attached to the associated shared memory segment.
    sub nattch { return( shift->[NATTCH] ); }

    # size of the associated shared memory segment in bytes.
    sub segsz { return( shift->[SEGSZ] ); }

    sub uid { return( shift->[UID] ); }

    sub FREEZE
    {
        my $self = CORE::shift( @_ );
        my $serialiser = CORE::shift( @_ ) // '';
        my $class = CORE::ref( $self );
        my @array = @$self;
        # Return an array reference rather than a list so this works with Sereal
        # On or before Sereal version 4.023, Sereal did not support multiple values returned
        CORE::return( [$class, \@array] ) if( $serialiser eq 'Sereal' && Sereal::Encoder->VERSION <= version->parse( '4.023' ) );
        # But CBOR and Storable want a list with the first element being the serialised element
        CORE::return( $class, \@array );
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
        my $array = CORE::ref( $ref ) eq 'ARRAY' ? $ref : [];
        # Storable pattern requires to modify the object it created rather than returning a new one
        if( CORE::ref( $self ) )
        {
            @$self = @$array;
            CORE::return( $self );
        }
        else
        {
            my $new = bless( $array => $class );
            CORE::return( $new );
        }
    }

    sub TO_JSON { CORE::return( [ @{$_[0]} ] ); }
}

# NOTE: Module::Generic::SemStat class
{
    package
        Module::Generic::SemStat;
    use IPC::SysV;
    require IPC::Semaphore;
    our $VERSION = 'v0.1.0';
    
    use constant UID => 0;
    use constant GID => 1;
    use constant CUID => 2;
    use constant CGID => 3;
    use constant MODE => 4;
    use constant CTIME => 5;
    use constant OTIME => 6;
    use constant NSEMS => 7;
    
    sub new
    {
        my $this = shift( @_ );
        my @vals = @_;
        return( bless( [ @vals ] => ref( $this ) || $this ) );
    }
    
    sub unpack
    {
        my $self = shift( @_ );
        my $data = shift( @_ );
        # my @unpacked = unpack( "i*", $data );
        # XS method
        my $d = IPC::Semaphore::stat->new->unpack( $data );
        return( $self->new( @$d ) );
    }
    
    sub cgid { return( shift->[CGID] ); }
    
    sub ctime { return( shift->[CTIME] ); }
    
    sub cuid { return( shift->[CUID] ); }

    sub gid { return( shift->[GID] ); }
    
    sub mode { return( shift->[MODE] ); }
    
    # number of semaphores in the set associated with the semaphore entry.
    sub nsems { return( shift->[NSEMS] ); }
    
    # time the last semaphore operation was completed on the set associated with the semaphore entry.
    sub otime { return( shift->[OTIME] ); }

    sub uid { return( shift->[UID] ); }

    sub FREEZE
    {
        my $self = CORE::shift( @_ );
        my $serialiser = CORE::shift( @_ ) // '';
        my $class = CORE::ref( $self );
        my @array = @$self;
        # Return an array reference rather than a list so this works with Sereal
        # On or before Sereal version 4.023, Sereal did not support multiple values returned
        CORE::return( [$class, \@array] ) if( $serialiser eq 'Sereal' && Sereal::Encoder->VERSION <= version->parse( '4.023' ) );
        # But CBOR and Storable want a list with the first element being the serialised element
        CORE::return( $class, \@array );
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
        my $array = CORE::ref( $ref ) eq 'ARRAY' ? $ref : [];
        # Storable pattern requires to modify the object it created rather than returning a new one
        if( CORE::ref( $self ) )
        {
            @$self = @$array;
            CORE::return( $self );
        }
        else
        {
            my $new = bless( $array => $class );
            CORE::return( $new );
        }
    }

    sub TO_JSON { CORE::return( [ @{$_[0]} ] ); }
}

1;

__END__
