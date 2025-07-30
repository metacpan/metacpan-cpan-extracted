##----------------------------------------------------------------------------
## Module Generic - ~/lib/Module/Generic/SharedMemXS.pm
## Version v0.3.3
## Copyright(c) 2025 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 1970/01/01
## Modified 2025/07/30
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Module::Generic::SharedMemXS;
BEGIN
{
    use v5.26.1;
    use strict;
    use warnings;
    use warnings::register;
    use parent qw( Module::Generic );
    use vars qw(
        $SUPPORTED_RE $SYSV_SUPPORTED $SEMOP_ARGS $N $HAS_B64
    );
    use Config;
    use File::Spec ();
    use Scalar::Util ();
    # This is disruptive for everybody. Bad idea.
    # use JSON 4.03 qw( -convert_blessed_universally );
    use JSON 4.03;
    use Module::Generic::Global ':const';
    use Storable::Improved ();
    use constant {
        SHM_BUFSIZ     =>  65536,
        SEM_LOCKER     =>  0,
        SEM_MARKER     =>  0,
        SHM_LOCK_WAIT  =>  0,
        SHM_LOCK_EX    =>  1,
        SHM_LOCK_UN    => -1,
        SHM_EXISTS     =>  1,
        LOCK_SH        =>  1,
        LOCK_EX        =>  2,
        LOCK_NB        =>  4,
        LOCK_UN        =>  8,
    };
    $SUPPORTED_RE = qr/IPC\/SysV/;
    if( $Config{extensions} =~ /$SUPPORTED_RE/ && 
        $^O !~ /^(?:Android|dos|MSWin32|os2|VMS|riscos)/i &&
        # we need semaphore and messages
        $Config{d_sem} eq 'define' &&
        $Config{d_msg} eq 'define'
        )
    {
        require IPC::SysV;
        IPC::SysV->import( qw( IPC_RMID IPC_PRIVATE IPC_SET IPC_STAT IPC_CREAT IPC_EXCL IPC_NOWAIT
                               SEM_UNDO S_IRWXU S_IRWXG S_IRWXO S_IRUSR S_IWUSR
                               GETNCNT GETZCNT GETVAL SETVAL GETPID GETALL SETALL
                               shmat shmdt memread memwrite ftok ) );
        require IPC::SharedMem;
        require IPC::Semaphore;
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

    our @EXPORT_OK = qw(LOCK_EX LOCK_SH LOCK_NB LOCK_UN);
    our %EXPORT_TAGS = (
        all     => [qw( LOCK_EX LOCK_SH LOCK_NB LOCK_UN )],
        lock    => [qw( LOCK_EX LOCK_SH LOCK_NB LOCK_UN )],
        'flock' => [qw( LOCK_EX LOCK_SH LOCK_NB LOCK_UN )],
    );
    our $VERSION = 'v0.3.3';
};

use v5.26.1;
use strict;
use warnings;
# no warnings 'redefine';

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
    $self->{owner}      = $$;
    $self->{locked}     = 0;
    return( $self );
}

sub addr
{
    my $self = shift( @_ );
    my $shm = $self->_ipc_shared ||
        return( $self->error( "No IPC::SharedMem object set. Have you opened the shared memory?" ) );
    # try-catch
    local $@;
    my @rv = eval
    {
        return( $shm->addr );
    };
    if( $@ )
    {
        return( $self->error( "Error with \$shm->addr: $@" ) );
    }
    else
    {
        return( $rv[0] );
    }
}

# This class does not convert to an HASH
sub as_hash { return( $_[0] ); }

sub attach
{
    my $self = shift( @_ );
    my $flags = shift( @_ );
    $flags = $self->flags if( !defined( $flags ) );
    my $shm = $self->_ipc_shared ||
        return( $self->error( "No IPC::SharedMem object set. Have you opened the shared memory?" ) );
    # try-catch
    local $@;
    my @rv = eval
    {
        return( $shm->attach( $flags ) );
    };
    if( $@ )
    {
        return( $self->error( "Error with \$shm->attach: $@" ) );
    }
    else
    {
        return( $rv[0] );
    }
}

sub base64 { return( shift->_set_get_scalar( 'base64', @_ ) ); }

sub cbor { return( shift->_packing_method( 'cbor' ) ); }

sub close { return( shift->remove( @_ ) ); }

sub create { return( shift->_set_get_boolean( 'create', @_ ) ); }

sub delete { return( shift->remove( @_ ) ); }

sub destroy
{
    my $self = shift( @_ );
    if( @_ )
    {
        my $val = shift( @_ );
        $self->_set_get_boolean( 'destroy', $val );
    }
    return( $self->_set_get_boolean( 'destroy' ) );
}

sub destroy_semaphore { return( shift->_set_get_boolean( 'destroy_semaphore', @_ ) ); }

sub detach
{
    my $self = shift( @_ );
    my $shm = $self->_ipc_shared ||
        return( $self->error( "No IPC::SharedMem object set. Have you opened the shared memory?" ) );
    my $rv;
    # try-catch
    local $@;
    eval
    {
        $rv = $shm->detach;
    };
    if( $@ )
    {
        return( $self->error( "Error detaching shared memory block previously attached: $@" ) );
    }
    return( $self->error( "Unable to detach from shared memory: $!" ) ) if( !defined( $rv ) );
    return( $self );
}

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
    $opts->{key} //= $self->key;
    my $key;
    if( length( $opts->{key} ) )
    {
        my $key_val = $self->_verify_key( $opts->{key} ) ||
            return( $self->pass_error );
        $key = $self->_str2key( $key_val );
    }
    my $flags = $self->flags({ mode => 0644 });
    no strict 'subs';
    $flags = ( $flags ^ &IPC::SysV::IPC_CREAT );

    my $shm;
    # try-catch
    local $@;
    eval
    {
        if( defined( $key ) )
        {
            $shm = IPC::SharedMem->new( $key, $opts->{size}, $flags );
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
            return( $self->error( "Error trying to find out if this shared memory segment already exists: $@" ) );
        }
    }
    # $shm = IPC::SharedMem->new( &IPC::SysV::IPC_PRIVATE, $opts->{size}, $flags );
    # No key is specified, thus we would be using IPC_PRIVATE, which would mean 
    # creating a new shared memory
    return(0) if( !defined( $shm ) );
    return( $shm->id );
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

sub id
{
    my $self = shift( @_ );
    my $shm = $self->_ipc_shared ||
        return( $self->error( "No IPC::SharedMem object set. Have you opened the shared memory?" ) );
    my $rv;
    # try-catch
    local $@;
    eval
    {
        $rv = $shm->id;
    };
    if( $@ )
    {
        return( $self->error( "Error with \$shm->id: $@" ) );
    }
    return( $rv );
}

sub json { return( shift->_packing_method( 'json' ) ); }

sub key
{
    my $self = shift( @_ );
    if( @_ )
    {
        my $key = $self->_verify_key( shift( @_ ) ) ||
            return( $self->pass_error );
        $self->{key} = $key;
        $self->{serial} = $self->_str2key( $key );
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
    my $sem = $self->_sem ||
        return( $self->error( "No IPC::Semaphore object set. Have you opened the shared memory?" ) );
    my $semid = $sem->id;
    return( $self->error( "No semaphore id set yet." ) ) if( !defined( $semid ) );
    my $rc;
    # try-catch
    local $@;
    eval
    {
        local $SIG{ALRM} = sub{ die( "timeout" ); };
        alarm( $timeout );
        $rc = $sem->op( @{$SEMOP_ARGS->{ $type }} );
        alarm(0);
    };
    if( $@ )
    {
        return( $self->error( "Unable to set a lock: $@" ) );
    }

    if( $rc )
    {
        $self->locked( $type );
    }
    # else
    # {
    #     # $self->message( 3, "Unable to set a lock on semaphore id \"$semid\": $!" );
    #     return( $self->error( "Failed to set a lock on semaphore id \"$semid\" for lock type $type: $!" ) );
    # }
    return( $self );
}

sub locked { return( shift->_set_get_scalar( 'locked', @_ ) ); }

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
    $opts->{key} //= $self->key // '';
    my $key;
    if( length( $opts->{key} ) )
    {
        my $key_val = $self->_verify_key( $opts->{key} ) ||
            return( $self->pass_error );
        $key = $self->_str2key( $key_val ) || 
            return( $self->error( "Cannot get serial from key '", ( $self->_is_array( $key_val ) ? join( "', '", @$key_val ) : $key_val ), "': ", $self->error ) );
    }
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

    my $shm;
    # try-catch
    local $@;
    eval
    {
        $key //= &IPC::SysV::IPC_PRIVATE;
        $shm = IPC::SharedMem->new( $key, $opts->{size}, $flags );
    };
    if( $@ )
    {
        return( $self->error( "Error instantiating a new IPC::SharedMem object: $@" ) );
    }

    if( !defined( $shm ) )
    {
        return( $self->error( "Unable to create shared memory block with key '", ( $self->_is_array( $opts->{key} ) ? join( "', '", @{$opts->{key}} ) : $opts->{key} ), "' (", ( $key // '' ), ") and flags \"$flags\": $!" ) );
    }

    my $sem;
    # try-catch
    local $@;
    eval
    {
        $sem = IPC::Semaphore->new( $key, 3, $flags );
    };
    if( $@ )
    {
        return( $self->error( "Error instantiating a new IPC::Semaphore object: $@" ) );
    }

    if( !defined( $sem ) )
    {
        return( $self->error( "Unable to create semaphore with key '", ( $self->_is_array( $opts->{key} ) ? join( "', '", @{$opts->{key}} ) : $opts->{key} ), "' (", ( $key // '' ), ") and flags \"$flags\": $!" ) );
    }

    my $new = $self->new(
        key     => $opts->{key},
        debug   => $self->debug,
        mode    => $self->mode,
        destroy => $self->destroy,
        _packing_method => $self->_packing_method,
    ) || return( $self->error( "Cannot create object with key '", ( $self->_is_array( $opts->{key} ) ? join( "', '", @{$opts->{key}} ) : $opts->{key} ), "': ", $self->error ) );
    $new->{base64} = $self->base64;
    $new->{size} = $opts->{size};
    $new->{flags} = $flags;
    $new->{create} = $create;
    $new->{_ipc_shared} = $shm;
    $new->{_sem} = $sem;
    my $id = $new->id;

    # Array to maintain the order in which shared memory object were created, so they can
    # be removed in that order
    my $shem_repo = Module::Generic::Global->new( 'shem_repo' => CORE::ref( $self ), key => CORE::ref( $self ) );
    my $id2obj_repo = Module::Generic::Global->new( 'id2obj' => CORE::ref( $self ), key => $id );
    $shem_repo->lock;
    my $all_shem = $shem_repo->get // [];
    CORE::push( @$all_shem, $id );
    $shem_repo->set( $all_shem );
    $shem_repo->unlock;

    $id2obj_repo->lock;
    $id2obj_repo->set( $new );
    $id2obj_repo->unlock;

    if( !defined( $sem->op( @{$SEMOP_ARGS->{(LOCK_SH)}} ) ) )
    {
        return( $self->error( "Unable to set lock on sempahore: $!" ) );
    }

    my $there = $new->stat( SEM_MARKER );
    if( defined( $there ) && $there == SHM_EXISTS )
    {
        # Binding to existing segment
    }
    else
    {
        # We initialise the semaphore with value of 1
        $new->stat( SEM_MARKER, SHM_EXISTS ) ||
            return( $new->error( "Unable to set semaphore during object creation: ", $new->error ) );
    }

    $sem->op( @{$SEMOP_ARGS->{(LOCK_SH | LOCK_UN)}} );
    return( $new );
}

sub op
{
    my $self = shift( @_ );
    return( $self->error( "No argument was provided!" ) ) if( !scalar( @_ ) );
    return( $self->error( "Invalid number of argument: '", join( ', ', @_ ), "'." ) ) if( @_ % 3 );
    my $sem = $self->_sem ||
        return( $self->error( "No IPC::Semaphore object set. Have you opened the shared memory?" ) );
    my $id = $sem->id;
    return( $self->error( "No semaphore set yet. You must open the shared memory first to set the semaphore." ) ) if( !length( $id ) );
    my $rv;
    # try-catch
    local $@;
    eval
    {
        $rv = $sem->op( @_ );
    };
    if( $@ )
    {
        return( $self->error( "Error passing operation list to semaphore id $id: $@" ) );
    }
    return( $rv );
}

sub owner { return( shift->_set_get_scalar( 'owner', @_ ) ); }

sub pid
{
    my $self = shift( @_ );
    my $sem  = shift( @_ );
    return( $self->error( "No semaphore provided." ) ) if( !defined( $sem ) || !length( $sem ) );
    my $obj = $self->_sem ||
        return( $self->error( "No IPC::Semaphore object set. Have you opened the shared memory?" ) );
    my $rv;
    # try-catch
    local $@;
    eval
    {
        $rv = $obj->getpid( $sem );
    };
    if( $@ )
    {
        return( $self->error( "Error getting the last process id of the semaphore: $@" ) );
    }
    return( ( defined( $rv ) && $rv ) ? 0 + $rv : undef() );
}

sub rand
{
    my $self = shift( @_ );
    my $size = $self->size || 1024;
    no strict 'subs';
    my $key  = shmget( &IPC::SysV::IPC_PRIVATE, $size, &IPC::SysV::S_IRWXU | &IPC::SysV::S_IRWXG | &IPC::SysV::S_IRWXO ) || return( $self->error( "Unable to generate a share memory key: $!" ) );
    return( $key );
}

# $self->read( $buffer, $size );
# $self->read( $buffer );
# my $data = $self->read;
sub read
{
    my( $self, $buf ) = @_;
    my $shm = $self->_ipc_shared ||
        return( $self->error( "No IPC::SharedMem object set. Have you opened the shared memory?" ) );
    my $size;
    $size = int( $_[2] ) if( scalar( @_ ) > 2 );
    # Optional length parameter for non-reference data only
    $size //= ( $self->size || SHM_BUFSIZ );
    $size = int( $size );
    my $id = $shm->id;
    return( $self->error( "No shared memory id! Have you opened it first?" ) ) if( !length( $id ) );
    my $buffer;
    # try-catch
    local $@;
    eval
    {
        $buffer = $shm->read( 0, $size );
    };
    if( $@ )
    {
        return( $self->error( "Error with \$shm->read: $@" ) );
    }

    if( !defined( $buffer ) )
    {
        if( $! =~ /Invalid argument/ )
        {
            return( $self->error( "Invalid argument used to read from shared memory. Size used was '$size' (", overload::StrVal( $size // 'undef' ), ")" ) );
        }
        else
        {
            return( $self->error( "Error reading from shared memory: $!" ) );
        }
    }

    my $packing = $self->_packing_method;
    # NOTE: Get rid of nulls end padded only for CBOR::XS, but not for Sereal and Storable who know how to handle them
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

        if( $packing eq 'json' )
        {
            # try-catch
            local $@;
            eval
            {
                $data = $self->_decode_json( $buffer );
            };
            if( $@ )
            {
                return( $self->error( "An error occured while decoding data using $packing with base64 set to '", ( $self->{base64} // '' ), "': $@" ) );
            }
        }
        elsif( $packing eq 'cbor' )
        {
            # try-catch
            local $@;
            eval
            {
                $data = $self->deserialise(
                    data => $buffer,
                    serialiser => 'CBOR::XS',
                    allow_sharing => 1,
                    ( defined( $self->{base64} ) ? ( base64 => $self->{base64} ) : () ),
                );
            };
            if( $@ )
            {
                return( $self->error( "An error occured while decoding data using $packing with base64 set to '", ( $self->{base64} // '' ), "': $@" ) );
            }
        }
        elsif( $packing eq 'sereal' )
        {
            # try-catch
            local $@;
            eval
            {
                $data = $self->deserialise(
                    data => $buffer,
                    serialiser => 'Sereal',
                    freeze_callbacks => 1,
                    ( defined( $self->{base64} ) ? ( base64 => $self->{base64} ) : () ),
                );
            };
            if( $@ )
            {
                return( $self->error( "An error occured while decoding data using $packing with base64 set to '", ( $self->{base64} // '' ), "': $@" ) );
            }
        }
        # By default Storable::Improved
        else
        {
            # try-catch
            local $@;
            eval
            {
                # $data = Storable::Improved::thaw( $buffer );
                $data = $self->deserialise(
                    data => $buffer,
                    serialiser => 'Storable::Improved',
                    ( defined( $self->{base64} ) ? ( base64 => $self->{base64} ) : () ),
                );
            };
            if( $@ )
            {
                return( $self->error( "An error occured while decoding data using $packing with base64 set to '", ( $self->{base64} // '' ), "': $@" ) );
            }
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
    my $shm = $self->{_ipc_shared};
    return(1) if( !defined( $shm ) || !length( $shm ) );
    my $sem = $self->{_sem};
    my( $id, $semid );
    $id = $shm->id;
    $semid = $sem->id if( $sem );
    $self->unlock();
    my $rv;
    # try-catch
    local $@;
    eval
    {
        $sem->remove if( $sem );
        $rv = $shm->remove;
    };
    if( $@ )
    {
        return( $self->error( "Error with \$shm->remove: $@" ) );
    }
    if( $rv )
    {
        my $id2obj_repo = Module::Generic::Global->new( 'id2obj' => CORE::ref( $self ), key => $id );
        $id2obj_repo->remove;
        my $shem_repo = Module::Generic::Global->new( 'shem_repo' => CORE::ref( $self ), key => CORE::ref( $self ) );
        $shem_repo->lock;
        my $all_shem = $shem_repo->get // [];
        my $modified = 0;
        for( my $i = 0; $i < scalar( @$all_shem ); $i++ )
        {
            my $this_id = $all_shem->[$i];
            if( $this_id eq $id )
            {
                CORE::splice( @$all_shem, $i, 1 );
                $modified++;
                last;
            }
        }
        if( $modified )
        {
            $shem_repo->set( $all_shem );
        }
        $self->{_ipc_shared} = undef;
        $self->{_sem} = undef;
    }
    return( ( defined( $rv ) && $rv ) ? 1 : 0 );
}

sub remove_semaphore
{
    my $self = shift( @_ );
    return(1) if( $self->removed_semaphore );
    my $sem = $self->_sem ||
        return( $self->error( "No IPC::Semaphore object set. Have you opened the shared memory?" ) );
    my $semid = $sem->id;
    $self->unlock();
    my $rv;

    # try-catch
    local $@;
    eval
    {
        $rv = $sem->remove;
    };
    if( $@ )
    {
        return( $self->error( "Error removing semaphore object: $@" ) );
    }

    if( !defined( $rv ) )
    {
        warn( "Warning only: could not remove the semaphore id \"$semid\" with IPC::SysV::IPC_RMID value '", &IPC::SysV::IPC_RMID, "': $!" ) if( $self->_warnings_is_enabled );
    }
    $self->{_sem} = undef;
    return( $rv ? 1 : 0 );
}

sub removed
{
    my $self = shift( @_ );
    my $shm = $self->{_ipc_shared};
    return(1) if( !defined( $shm ) || !length( $shm ) );
    return( $shm->is_removed );
}

sub removed_semaphore
{
    my $self = shift( @_ );
    my $sem = $self->{_sem};
    return( ( defined( $sem ) && $sem ) ? 0 : 1 );
}

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

sub semid
{
    my $self = shift( @_ );
    my $sem = $self->_sem ||
        return( $self->error( "No IPC::Semaphore object set. Have you opened the shared memory?" ) );
    my $rv;
    # try-catch
    local $@;
    eval
    {
        $rv = $sem->id;
    };
    if( $@ )
    {
        return( $self->error( "Error with retrieving semaphore id: $@" ) );
    }
    return( $rv );
}

sub sereal { return( shift->_packing_method( 'sereal' ) ); }

sub serialiser { return( shift->_set_get_scalar( '_packing_method', @_ ) ); }

{
    no warnings 'once';
    *serializer = \&serialiser;
}

sub shmstat
{
    my $self = shift( @_ );
    my $shm = $self->_ipc_shared ||
        return( $self->error( "No IPC::SharedMem object set. Have you opened the shared memory?" ) );
    my $rv; 
    # try-catch
    local $@;
    eval
    {
        $rv = $shm->stat;
    };
    if( $@ )
    {
        return( $self->error( "Error with \$shm->stat: $@" ) );
    }
    return( $rv );
}

sub size { return( shift->_set_get_scalar( 'size', @_ ) ); }

sub stat
{
    my $self = shift( @_ );
    my $obj = $self->_sem ||
        return( $self->error( "No IPC::Semaphore object set. Have you opened the shared memory?" ) );
    my $id = $obj->id;
    if( @_ )
    {
        if( @_ == 1 )
        {
            my $sem = shift( @_ );
            my $v;
            # try-catch
            local $@;
            eval
            {
                $v = $obj->getval( $sem );
            };
            if( $@ )
            {
                return( $self->error( "Error getting value for semaphore '$sem': $@" ) );
            }
            return( $self->error( "Error with \$sem->getval: $!" ) ) if( !defined( $v ) && $! );
            return if( !defined( $v ) );
            return( 0 + $v );
        }
        else
        {
            my( $sem, $val ) = @_;
            my $rv;
            # try-catch
            local $@;
            eval
            {
                $rv = $obj->setval( $sem => $val );
            };
            if( $@ )
            {
                return( $self->error( "Error setting value for semaphore '$sem': $@" ) );
            }
            return( $self->error( "Unable to semctl with semaphore id '$id', semaphore '$sem', SETVAL='", &IPC::SysV::SETVAL, "' and value='$val': $!" ) ) if( !defined( $rv ) );
            return( $rv );
        }
    }
    else
    {
        my $data = '';
        if( wantarray() )
        {
            my @sem;
            # try-catch
            local $@;
            eval
            {
                @sem = $obj->getall;
            };
            if( $@ )
            {
                return( $self->error( "Error getting all semaphore values as an array: $@" ) );
            }
            return( @sem );
        }
        else
        {
            my $stats;
            # try-catch
            local $@;
            eval
            {
                $stats = $obj->stat;
            };
            if( $@ )
            {
                return( $self->error( "Error getting a stat object for semaphore id $id: $@" ) );
            }
            return( $self->error( "Unable to stat semaphore with id '$id': $!" ) ) if( !$stats );
            return( $stats );
        }
    }
}

sub storable { return( shift->_packing_method( 'storable' ) ); }

sub supported { return( $SYSV_SUPPORTED ); }

sub unlock
{
    my $self = shift( @_ );
    return(1) if( !$self->locked );
    my $sem = $self->_sem ||
        return( $self->error( "No IPC::Semaphore object set. Have you opened the shared memory?" ) );
    my $type = ( $self->locked | LOCK_UN );
    $type ^= LOCK_NB if( $type & LOCK_NB );
    # if( defined( $self->op( @{$SEMOP_ARGS->{ $type }} ) ) )
    # {
    #     $self->locked(0);
    # }
    if( !defined( $self->op( @{$SEMOP_ARGS->{ $type }} ) ) )
    {
        # Failed to unlock semaphore
    }
    $self->locked(0);
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
    my $shm = $self->_ipc_shared ||
        return( $self->error( "No IPC::SharedMem object set. Have you opened the shared memory?" ) );
    my $id = $self->id || return( $self->error( "No shared memory id set yet. You must open the shared memory first to write." ) );
    my $size = int( $self->size() ) || SHM_BUFSIZ;
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
        return( $self->error( "Data to write are ${len} bytes long and exceed the maximum you have set of '$size'." ) );
    }

    # Ensure the shared memory segment is attached
    unless( defined( $self->addr ) )
    {
        my $addr = shmat( $id, undef, 0 );
        if( !defined( $addr ) || ( Scalar::Util::looks_like_number( $addr ) && $addr == -1 ) )
        {
            return( $self->error( "Unable to attach to shared memory id '$id': $!" ) );
        }
        $self->{addr} = $addr;
    }

    $self->lock( LOCK_EX ) || return( $self->pass_error );
    # my $rv = shmwrite( $id, $encoded, 0, $len ) ||
    #     return( $self->error( "Unable to write to shared memory id '$id' with ${len} bytes of data encoded and memory size of $size: $!" ) );
    my $rv;
    # try-catch
    local $@;
    eval
    {
        $rv = $shm->write( $encoded, 0, $len );
    };
    if( $@ )
    {
        return( $self->error( "Error with \$shm->write: $@" ) );
    }
    return( $self->error( "Unable to write to shared memory id '$id' with ${len} bytes of data encoded and memory size of $size: $!" ) ) if( !$rv );
    $self->unlock;
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

sub _ipc_shared { return( shift->_set_get_scalar( '_ipc_shared', @_ ) ); }

sub _packing_method { return( shift->_set_get_scalar( '_packing_method', @_ ) ); }

sub _sem { return( shift->_set_get_scalar( '_sem', @_ ) ); }

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
        $self->_load_class( 'Digest::SHA' ) || return( $self->pass_error );
        my $hash = Digest::SHA::sha1_base64( $key );
        my $id = ord( substr( $hash, 0, 1 ) );
        # We use the root as a reliable and stable path.
        # I initially thought about using __FILE__, but during testing this would be in ./blib/lib and beside one user might use a version of this module somewhere while the one used under Apache/mod_perl2 could be somewhere else and this would render the generation of the IPC key unreliable and unrepeatable
        # my $val = &IPC::SysV::ftok( File::Spec->rootdir(), $id );
        my $val = &IPC::SysV::ftok( $path, $id );
        return( $val );
    }
}

sub _verify_key
{
    my( $self, $key ) = @_;
    if( !defined( $key ) || !length( $key // '' ) )
    {
        # It's ok, _str2key will use IPC::SysV::IPC_PRIVATE then
    }
    elsif( !ref( $key ) || $self->_can_overload( $key => '""' ) )
    {
        $key = "$key";
        if( !CORE::length( $key // '' ) )
        {
            return( $self->error( "An empty key was provided." ) );
        }
    }
    elsif( $self->_is_array( $key ) )
    {
        # We use as-is
    }
    else
    {
        return( $self->error( "Key must be a string, but I got '", $self->_str_val( $key // 'undef' ), "'" ) );
    }
    return( $key );
}

sub DESTROY
{
    # <https://perldoc.perl.org/perlobj#Destructors>
    CORE::local( $., $@, $!, $^E, $? );
    CORE::return if( ${^GLOBAL_PHASE} eq 'DESTRUCT' );
    my $self = CORE::shift( @_ );
    CORE::return if( !CORE::defined( $self ) );
    CORE::return unless( $self->{_ipc_shared} );
    my $shm = $self->{_ipc_shared};
    CORE::return if( $shm->id );
    $self->unlock;
    $self->detach;
    my $rv = $self->remove_semaphore;
    if( $self->destroy )
    {
        my $stat = $self->shmstat();
        # number of processes attached to the associated shared memory segment.
        if( CORE::defined( $stat ) && ( $stat->nattch() == 0 ) )
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
    CORE::delete( @hash{ qw( owner ) } );
    $hash{_was_opened} = $self->{_ipc_shared} ? 1 : 0;
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
    my $was_opened = CORE::delete( $hash->{_was_opened} );
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
    if( $was_opened )
    {
        my $size = ( defined( $new->{size} ) && length( $new->{size} ) ) ? $new->{size} : SHM_BUFSIZ;
        my $flags = ( defined( $new->{flags} ) && length( $new->{flags} ) ) ? $new->{flags} : &IPC::SysV::S_IRWXU;
        $flags |= &IPC::SysV::IPC_CREAT if( defined( $new->{create} ) && $new->{create} );
        my $key = $new->{key};
        # try-catch
        local $@;
        eval
        {
            my $shm;
            if( defined( $key ) && length( $key ) )
            {
                $key = $self->_str2key( $key );
                $shm = IPC::SharedMem->new( $key, $size, $flags );
            }
            else
            {
                $shm = IPC::SharedMem->new( &IPC::SysV::IPC_PRIVATE, $size, $flags );
            }
            $new->{_ipc_shared} = $shm;
        };
        if( $@ )
        {
            return( $self->error( "Error creating a new IPC::SharedMem object: $@" ) );
        }

        my $sem;
        # try-catch
        local $@;
        eval
        {
            $sem = IPC::Semaphore->new( $key, 3, $flags );
        };
        if( $@ )
        {
            return( $self->error( "Error creating a new IPC::Semaphore object: $@" ) );
        }

        if( !defined( $sem ) )
        {
            return( $self->error( "Unable to create semaphore with key \"", ( $key // '' ), "\" and flags \"$flags\": $!" ) );
        }
        $new->{_sem} = $sem;
    }
    CORE::return( $new );
}

# NOTE: END
# END
# {
#     my $shem_repo = Module::Generic::Global->new( 'shem_repo' => __PACKAGE__, key => __PACKAGE__ );
#     $shem_repo->lock;
#     my $all_shem = $shem_repo->get // [];
#     foreach my $id ( @$all_shem )
#     {
#         my $id2obj_repo = Module::Generic::Global->new( 'id2obj' => __PACKAGE__, key => $id );
#         my $s = $id2obj_repo->get || next;
#         next if( $s->removed || !$s->id || !$s->destroy );
#         $s->detach;
#         $s->remove;
#     }
#     $shem_repo->unlock;
#     $shem_repo->remove;
# };

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

Module::Generic::SharedMemXS - Shared Memory Manipulation with XS API

=head1 SYNOPSIS

    # Check if IPC::SysV is supported on this system
    if( Module::Generic::SharedMemXS->supported )
    {
        my $shmem = Module::Generic::SharedMemXS->new( key => 'some_identifier' ) ||
            die( Module::Generic::SharedMemXS->error );
    }

    my $shmem = Module::Generic::SharedMemXS->new(
        # Create if necessary, or re-use if already exists
        create => 1,
        # Self-destroy upon end of object. Default to false
        destroy => 0,
        # make access exclusive
        exclusive => 1,
        key => 'some_identifier',
        mode => 0666,
        # 100K
        size => 102400,
        debug => 3,
    ) || die( Module::Generic::SharedMemXS->error );

    # Check if it already exists
    if( $shmem->exists )
    {
        # do something
    }

    $shmem->create(0);
    $shmem->destroy(0);
    $shmem->exclusive(0);
    # Then get the bitwise flags based on those options set above:
    my $flags = $shmem->flags;
    # or specify overriding values:
    my $flags = $shmem->flags({
        create => 0,
        destroy => 0,
        exclusive => 0,
        mode => 0644,
    });

    my $s = $shmem->open || die( $shmem->error );

    # Get the shared memory id
    my $id = $s->id;

    my $key = $s->key;

    # Get the actual key used in interacting with shared memory
    # You should not mess with this unless you know what you are doing
    my $shem_key = $s->serial;

    use Module::Generic::SharedMemXS qw( :all );
    $s->lock( LOCK_EX ) || die( $s->error );
    # Is it locked?
    my $is_locked = $s->locked;

    # example: 0666
    my $mode = $s->mode;
    my $s = $shmem->open || die( $shmem->error );

    # Actually the process pid
    my $owner = $s->owner;

    # The semaphore pid
    my $sempid = $s->pid;

    # Get a random key to use to create shared memory block
    my $random_key = $shmem->rand;

    my $data = $s->read;
    my $buffer;
    $s->read( $buffer );
    # You can control how much to read and allocate a buffer to put the read data onto
    # Data is automatically transcoded using Storable::Improved::thaw
    my $len = $s->read( $buffer, 1024 ) || die( $s->error );

    $s->remove;

    my $semaphore_id = $s->semid;

    # or $s->size;
    my $shared_mem_size = $shmem->size;

    # See Module::Generic::SemStat doc
    my $stat = $s->stat;

    # See Module::Generic::SharedStat doc
    my $stat = $s->shmstat;

    # Remove lock
    $s->unlock;

    # Data is automatically transcoded using Storable::Improved::freeze
    $s->write( $data ) || die( $s->error );

=head1 VERSION

    v0.3.3

=head1 DESCRIPTION

L<Module::Generic::SharedMemXS> provides an easy to use api to manipulate shared memory block. See L<perlipc> for more information. This module relies on the XS module L<IPC::SharedMem> part of the L<IPC::SysV> distribution.

This module is similar to L<Module::Generic::SharedMem>, except this one relies on L<IPC::SharedMem> whereas L<Module::Generic::SharedMem> uses perl core functions to access and manipulate shared memory.

As stipulated in L<perlport>, this is not supported on the following platforms: android, dos, MSWin32, OS2, VMS and Risc OS.

You can check if the system is supported with L</supported>

    if( Module::Generic::SharedMemXS->supported )
    {
        # do something
    }

This module only works with reference data, such as array, hash or reference to scalar. Anything that L<CBOR::XS>, L<Sereal>. or L<Storable::Improved> knows how to L<Storable::Improved/freeze> and L<Storable::Improved/thaw>

=head1 DEBUGGING

To list all used shared memory, at least on Unix type systems such as Linux or FreeBSD (including MacOSX), use:

    ipcs -m

=head1 METHODS

=head2 new

This instantiates a shared memory object. It takes the following parameters:

=over 4

=item * C<cbor>

Provided with a value (true or false does not matter), and this will set L<CBOR::XS> as the data serialisation mechanism when storing data to memory or reading data from memory.

=item * C<debug>

A debug value will enable debugging output (equal or above 3 actually)

=item * C<create>

A boolean value to indicate whether the shared memory block should be created if it does not exist. Default to false.

=item * C<destroy>

A boolean value to indicate if the shared memory block should be removed when the object is destroyed upon end of the script process.
See L<perlmod> for more about object destruction.

=item * C<destroy_semaphore>

A boolean value to indicate if the semaphore should be removed when the object is destroyed upon end of the script process.
See L<perlmod> for more about object destruction.

C<destroy_semaphore> is automatically enabled if I<destroy> is set to true.

Thus, one can deactive auto removal of the shared memory block, but enable auto removal of the semaphore. This is useful when there are two processes accessing the same shared memory block and one wants to give the first process the authority to create and remove the shared memory block, while the second only access and write to the shared memory block, but does not remove it. Still to avoid having semaphores surviving the process, by enabling this option and disabling I<destroy>, it will remove the semaphore and leave the shared memory.

=item * C<exclusive>

A boolean value to set the shared memory as exclusive. This will affect the flags set by L</flags> which are used by L</open>.

=item * C<json>

Provided with a value (true or false does not matter), and this will set L<JSON> as the data serialisation mechanism when storing data to memory or reading data from memory.

=item * C<key>

The shared memory key identifier to use. It defaults to C<IPC::SysV::IPC_PRIVATE>

If you provide an empty value, it will revert to C<IPC::SysV::IPC_PRIVATE>.

If you provide a number, it will be used to call L<IPC::SysV/ftok>.

Otherwise, if you provide a key as string, the characters in the string will be converted to their numeric value and added up. The resulting id, called C<project id> by L<IPC::SysV>, will be used to call L<IPC::SysV/ftok> and will produce an hopefully unique and repeatable value.

Either way, the resulting value is used to create a shared memory segment and a semaphore by L</open>.

=item * C<mode>

The octal mode value to use when opening the shared memory block.

Shared memory are owned by system users and access to shared memory segment is ruled by the initial permissions set to it.

If you do not want to share it with any other user than yourself, setting mode to C<0600> is fine.

=item * C<sereal>

Provided with a value (true or false does not matter), and this will set L<Sereal> as the data serialisation mechanism when storing data to memory or reading data from memory.

=item * C<serialiser>

You can provide the serialiser with this option. Possible values are: C<cbor>, C<json>, C<sereal>, C<storable>

=item * C<size>

The size in byte of the shared memory.

This is set once it is created. You can create again the shared memory segment with a smaller size, but not a bigger one. If you want to increase the size, you would need to remove it first.

=item * C<storable>

Provided with a value (true or false does not matter), and this will set L<Storable::Improved> as the data serialisation mechanism when storing data to memory or reading data from memory.

=back

An object will be returned if it successfully initiated, or undef() upon error, which can then be retrieved with C< Module::Generic::SharedMemXS->error >. You should always check the return value of the methods used here for their definedness.

    my $shmem = Module::Generic::SharedMemXS->new(
        create => 1,
        destroy => 0,
        key => 'my_memory',
        # 64K
        size => 65536,
    ) || die( Module::Generic::SharedMemXS->error );

=head2 addr

Returns the address of the shared memory segment once it has been attached to this address space.

=head2 attach

Attach the shared memory segment to this address space and returns its address.

Upon error, it returns C<undef> and sets an error that can be retrieved with the error method:

    my $addr = $shem->attach || die( $shem->error );

A shared memory segment object must be first created with the L</open> method, because L</attach> calls L<IPC::SysV/shmat> with the shared memory id and this id is returned upon using the L</open> method.

=head2 cbor

When called, this will set L<CBOR::XS> as the data serialisation mechanism when storing data to memory or reading data from memory.

=head2 close

This is an alias for L</remove>

=head2 create

Set or get the boolean value to true to indicate you want to create the shared memory block if it does not exist already. Default to false.

=head2 delete

This is an alias for L</remove>

=head2 destroy

Set or get the boolean value to indicate that the shared memory should be automatically destroyed when the module object is destroyed. See L<perlmod> for more information about module object destruction.

=head2 detach

Quoting the IPC documentation, this detaches the shared memory segment located at the address specified by L</attach> from this address space.

It returns C<undef> if it is not attached anymore, but without setting an error.

=head2 exclusive

Set or get the boolean value to affect the open flags in exclusive mode.

=head2 exists

Checks if the shared memory identified with I<key> exists.

It takes the same arguments as L</open> and returns 1 if the shared memory exists or 0 otherwise.

It does this by performing a L<perlfunc/shmget> such as:

    shmget( $shared_mem_key, $size, 0444 );

This will typically return the shared memory id if it exists or C<undef()> with an error set in C<$!> by perl otherwise.

=head2 flags

Provided with an optional hash or hash reference and this return a bitwise value of flags used by L</open>.

    my $flags = $shmem->flags({
        create => 1,
        exclusive => 0,
        mode => 0600,
    }) || die( $shmem->error );

=head2 id

Returns the id of the shared memory once it has been opened with L</open>

    my $s = $shmem->open || die( $shmem->error );
    my $id = $s->id;

=head2 json

When called, this will set L<JSON> as the data serialisation mechanism when storing data to memory or reading data from memory.

=head2 key

Sets or gets the shared memory key identifier.

    $shem->key( 'some_identifier' );

=head2 lock

It takes an optional bitwise lock value, and defaults to C<LOCK_SH> if none is provided and issues a lock on the shared memory.

    use Module::Generic::SharedMemXS qw( :all );
    my $s = $shem->open || die( $shmem->error );
    $s->lock( LOCK_EX );
    # Do something
    $s->unlock;

=head2 locked

Returns a positive value when a lock is active or 0 when there is no active lock.

The value is the bitwise value of the lock used.

=head2 mode

Sets or gets the mode for the shared memory as used by L</open>

    $shmem->mode( 0666 );
    my $s = $shmem->open || die( $shmem->error );

=head2 op

Issue an opeation on the L<semaphore|https://en.wikipedia.org/wiki/Semaphore_(programming)>.

Provided value sould be a set of 3.

    ＄s->op( @{$Module::Generic::SharedMemXS::SEMOP_ARGS->{(LOCK_SH)}} ) ||
        die( $s->error );

=head2 open

Creates or accesses a shared memory segment and returns a new L<Module::Generic::SharedMemXS> object. Takes an optional hash or hash reference with parameters such as C<key>, C<mode>, and C<size>:

    my $shmem = Module::Generic::SharedMemXS->new(
        create => 1,
        destroy => 0,
        # If not provided, will use the one provided during object instantiation
        key => 'my_memory',
        # 64K
        size => 65536,
    ) || die( Module::Generic::SharedMemXS->error );
    # Overriding some default value set during previous object instantiation
    my $shmem = $shmem->open({
        mode => 0600,
        size => 1024,
    }) || die( $shmem->error );
    # or
    my $s = $shmem->open({ mode => 'r', size => 1024 }) || die( $shmem->error );

If called on an already opened object, it reuses the existing shared memory segment and semaphore, creating a new object that shares the same resources. This is critical for threaded applications to ensure all threads access the same segment safely. The module leverages L<IPC::Semaphore> to reliably reuse semaphores based on the shared memory key, ensuring thread-safe operations without additional configuration.

In threaded applications, open the shared memory in the main thread before starting threads to ensure thread-safety:

    require threads;
    require threads::shared;
    threads->import();
    threads::shared->import();
    my $shmem = Module::Generic::SharedMemXS->new(
        debug => 3,
        key => 'my_memory',
        size => 65536,
        mode => 0666,
        create => 1,
    ) || die( Module::Generic::SharedMemXS->error );
    my $obj = $shmem->open({ mode => 'w' }) || die( $shmem->error );
    my @threads;
    for(1..3)
    {
        push @threads, threads->create(sub
        {
            my $tid = threads->tid();
            my $sh = $obj->open();
            if( !defined( $sh ) )
            {
                warn( "Error with thread $tid: unable to open shared memory segment: ", $obj->error );
                return(0);
            }
            my $data = $sh->read();
            my $old_counter = $data->{counter};
            $data->{counter}++;
            $sh->write( $data ) || return(0);
            return(1);
        });
    }
    my $success = 1;
    for my $thr ( @threads )
    {
        my $result = $thr->join();
        $success &&= $result;
    }
    my $data = $obj->read();
    # $data->{counter} is 3, and $success is true

Parameters:

=over 4

=item * C<key>

The shared memory key identifier. Defaults to the key set during object instantiation or C<IPC::SysV::IPC_PRIVATE>.

=item * C<mode>

The octal mode for the shared memory (e.g., C<0600> for owner-only access). Defaults to the mode set during object instantiation.

=item * C<size>

The size of the shared memory segment in bytes. Defaults to the size set during object instantiation.

=back

If the L</create> option is true and the shared memory exists, C<open> accesses it without the C<IPC::SysV::IPC_CREAT> flag. Returns a new object on success, or C<undef> on error, with the error accessible via L<Module::Generic/error>.

=head2 owner

Sets or gets the shared memory owner, which is by default actually the process id (C<$$>)

=head2 pid

Get the L<semaphore|https://en.wikipedia.org/wiki/Semaphore_(programming)> pid once the shared memory has been opened.

    my $pid = $s->pid || die( $s->error );

=head2 rand

Get a random key to be used as identifier to create a shared memory.

=head2 read

Read the content of the shared memory and decode the data read using L<JSON>, L<CBOR|CBOR::XS>, L<Sereal> or L<Storable::Improved/thaw> depending on your choice upon either object instantiation or upon using the methods L</json>, L</cbor>, L</sereal> or L</storable>. For example:

    my $s = Module::Generic::SharedMemXS->new( cbor => 1 ) ||
        die( Module::Generic::SharedMemXS->error );
    # or
    $s->cbor(1);
    # or
    my $s = Module::Generic::SharedMemXS->new( serialiser => 'cbor' ) ||
        die( Module::Generic::SharedMemXS->error );

By default, if no serialiser is specified, it will default to C<storable>.

You can optionally provide a buffer, and a maximum length and it will read that much length and put the shared memory content decoded in that buffer, if it were provided.

It then return the length read, or C<0E0> if no data was retrieved. C<0E0> still is treated as 0, but as a positive value, so you can do:

    my $len = $s->read( $buffer ) || die( $s->error );

But you really should more thoroughly do instead:

    my( $len, $buffer );
    if( !defined( $len = $s->read( $buffer ) ) )
    {
        die( $s->error );
    }

If you do not provide any buffer, you can call L</read> like this and it will return you the shared memory decoded content:

    my $buffer;
    if( !defined( $buffer = $s->read ) )
    {
        die( $s->error );
    }

=head2 remove

Remove entire the shared memory identified with L</key>

=head2 remove_semaphore

Remove the semaphore associated with the shared memory.

=head2 removed

Returns true if the shared memory was removed, false otherwise.

=head2 removed_semaphore

Returns true if the semaphore has been removed, false otherwise.

=head2 reset

Reset the shared memory value. If a value is provided, it will be used as the new reset value, othewise an empty string will be used.

=head2 semid

Return the L<semaphore|https://en.wikipedia.org/wiki/Semaphore_(programming)> id once the shared memory has been opened. See L<perlipc> for more information about semaphore and L<perlfunc>.

=head2 sereal

When called, this will set L<Sereal> as the data serialisation mechanism when storing data to memory or reading data from memory.

=head2 serial

Returns the serial number used to create or access the shared memory segment.

This serial is created based on the I<key> parameter provided either upon object instantiation or upon using the L</open> method.

The serial is created by calling L<IPC::SysV/ftok> to provide a reliable and repeatable numeric identifier.

=head2 serialiser

Sets or gets the serialiser. Possible values are: C<cbor>, C<json>, C<sereal>, C<storable>

=head2 shmstat

Returns an C<Module::Generic::SharedStat> object representing the current shared memory properties.

=head2 size

Sets or gets the shared memory block size.

This should be an integer representing bytes, so typically a multiple of 1024.

=head2 stat

Sets or retrieve value with L<semaphore|https://en.wikipedia.org/wiki/Semaphore_(programming)>.

If one parameter only is provided, it returns its corresponding value set.

It performs:

    # Get the semaphore id
    my $id = $s->semid;
    my $value = semctl( $id, $sem, IPC::SysV::GETVAL, 0 );

When 2 parameters are provided, this is treated as a key-value pair and sets the value for the corresponding key.

It performs:

    my $id = $s->semid;
    semctl( $id, $sem, IPC::SysV::SETVAL, $val )

If no parameter is provided it returns a L<Module::Generic::SemStat> object in scalar context or an array of value in list context.

=head2 storable

When called, this will set L<Storable::Improved> as the data serialisation mechanism when storing data to memory or reading data from memory.

=head2 supported

Returns true if IPC shared memory segments are supported by the system, and false otherwise.

=head2 unlock

Remove the lock, if any. The shared memory must first be opened.

    $s->unlock || die( $s->error );

=head2 write

Write the data provided to the shared memory, after having encoded it using L<JSON>, L<CBOR|CBOR::XS>, L<Sereal> or L<Storable::Improved/freeze> depending on your choice of serialiser. See L</json>, L</cbor>, L</sereal> and L</storable>

By default, if no serialiser is specified, it will default to C<storable>.

You can only store in shared memory reference, such as scalar reference, array or hash reference. You could also store module objects, but note that if you choose L<JSON> as a serialiser for your shared data, L<JSON> only supports encoding objects that are based on array or hash. As the L<JSON> documentation states "other blessed references will be converted into null". Thus if you use other reference types, you might want to use L<CBOR|CBOR::XS>, L<Sereal> or L<Storable> instead.

It returns the current object for chaining, or C<undef> if there was an error, which can then be retrieved with L<Module::Generic/error>

=head1 SERIALISATION

=for Pod::Coverage FREEZE

=for Pod::Coverage STORABLE_freeze

=for Pod::Coverage STORABLE_thaw

=for Pod::Coverage THAW

=for Pod::Coverage TO_JSON

Serialisation by L<CBOR|CBOR::XS>, L<Sereal> and L<Storable::Improved> (or the legacy L<Storable>) is supported by this package. To that effect, the following subroutines are implemented: C<FREEZE>, C<THAW>, C<STORABLE_freeze> and C<STORABLE_thaw>

=head1 PROCESS CLEANUP SAFETY

This module attempts to automatically clean up shared memory and semaphore resources using an C<END> block. However, note that:

=over 4

=item *

In multi-threaded programs, C<END> blocks may not execute for all threads.

=item *

If multiple processes share a memory segment, only the original owner should call C<remove()> or rely on auto-cleanup.

=item *

For best results, call C<remove()> manually if your lifecycle logic requires guaranteed cleanup.

=back

=head1 THREAD & PROCESS SAFETY

L<Module::Generic::SharedMemXS> is designed for safe multi-process and multi-threaded access to shared memory using System V IPC, leveraging L<IPC::SharedMem> and L<IPC::Semaphore>. Semaphores guard concurrent access, ensuring data integrity across processes and threads. In threaded applications, the module uses L<IPC::Semaphore>’s key-based semaphore reuse and thread-safe locking for shared memory objects, ensuring robust thread-safety.

Key considerations for thread and process safety:

=over 4

=item * B<Main Thread Initialization>

In threaded applications, the shared memory segment must be opened in the main thread before starting worker threads. This ensures the shared memory and semaphore are initialized, allowing worker threads to reuse them safely via L</open>:

    my $shmem = Module::Generic::SharedMemXS->new( key => 'my_memory', create => 1 );
    my $obj = $shmem->open({ mode => 'w' });
    my @threads = map
    {
        threads->create(sub
        {
            my $sh = $obj->open();
            # Work with $sh
        });
    } 1..10;

=item * B<Semaphore Reuse>

Calling L</open> on an already opened object (e.g., C<$obj->open()>) reuses the existing shared memory segment and semaphore. L<IPC::Semaphore> ensures the same semaphore is used across threads and processes for a given key, providing thread-safe access without additional synchronization.

=item * B<Process Safety>

For multi-process applications, semaphores prevent concurrent access issues. Each process can open the shared memory segment using the same key, with L<IPC::Semaphore> ensuring safe access.

=item * B<Cleanup>

Shared memory and semaphores are system-wide resources and persist until removed or the system is rebooted. Use L</remove> to clean up shared memory and L</remove_semaphore> for semaphores, especially in daemonized or mod_perl environments. The L</destroy> and L</destroy_semaphore> options can automate cleanup, but manual removal is recommended for explicit control:

    $obj->remove() if $obj->exists();

=item * B<Thread Limitations>

While thread-safe, this module is primarily designed for inter-process communication. In threaded environments, ensure proper initialization in the main thread and avoid creating new shared memory segments in worker threads to prevent conflicts.

=back

For debugging shared memory and semaphore usage on Unix-like systems (e.g., Linux, FreeBSD, macOS), use:

    ipcs -m  # List shared memory segments
    ipcs -s  # List semaphores
    ipcrm -m <shmid>  # Remove shared memory
    ipcrm -s <semid>  # Remove semaphore

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Module::Generic>, L<Module::Generic::SemStat>, L<Module::Generic::SharedStat>

L<perlipc>, L<perlmod>, L<IPC::Semaphore>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2022-2025 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
