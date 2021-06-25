##----------------------------------------------------------------------------
## Module Generic - ~/lib/Module/Generic/SharedMem.pm
## Version v0.1.0
## Copyright(c) 2021 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2021/01/18
## Modified 2021/01/23
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
    use Config;
    use File::Spec ();
    use Nice::Try;
    use Scalar::Util ();
    use Storable ();
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
    our $SUPPORTED_RE = qr/\bIPC\/SysV\b/m;
    if( $Config{extensions} =~ m/$SUPPORTED_RE/ && 
        $^O !~ /^(?:Android|dos|MSWin32|os2|VMS|riscos)/i )
    {
        require IPC::SysV;
        IPC::SysV->import( qw( IPC_RMID IPC_PRIVATE IPC_SET IPC_STAT IPC_CREAT IPC_EXCL IPC_NOWAIT
                               SEM_UNDO S_IRWXU S_IRWXG S_IRWXO S_IRUSR S_IWUSR
                               GETNCNT GETZCNT GETVAL SETVAL GETPID GETALL SETALL
                               shmat shmdt memread memwrite ftok ) );
        our $SYSV_SUPPORTED = 1;
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
            warn( "Error while trying to evel \$SEMOP_ARGS: $@\n" );
        }
    }
    else
    {
        our $SYSV_SUPPORTED = 0;
    }
    our @EXPORT_OK = qw(LOCK_EX LOCK_SH LOCK_NB LOCK_UN);
    our %EXPORT_TAGS = (
            all     => [qw( LOCK_EX LOCK_SH LOCK_NB LOCK_UN )],
            lock    => [qw( LOCK_EX LOCK_SH LOCK_NB LOCK_UN )],
            'flock' => [qw( LOCK_EX LOCK_SH LOCK_NB LOCK_UN )],
    );
    # Credits IPC::SysV
    our $N = do { my $foo = eval { pack "L!", 0 }; $@ ? '' : '!' };
    # Array to maintain the order in which shared memory object were created, so they can
    # be removed in that order
    our $SHEM_REPO = [];
    our $ID2OBJ    = {};
    our $VERSION = 'v0.1.0';
};

sub init
{
    my $self = shift( @_ );
    # Default action when accessing a shared memory? If 1, it will create it if it does not exist already
    $self->{create}     = 0;
    # If true, this will destroy both the shared memory and the semaphore upon end
    $self->{destroy}    = 0;
    # If true, this will destroy only the semaphore upon end
    $self->{destroy_semaphore} = 0;
    $self->{exclusive}  = 0;
    $self->{key}        = IPC::SysV::IPC_PRIVATE;
    $self->{mode}       = 0666;
    $self->{serial}     = '';
    # SHM_BUFSIZ
    $self->{size}       = SHM_BUFSIZ;
    $self->{_init_strict_use_sub} = 1;
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
    $flags = ( $flags ^ IPC::SysV::IPC_CREAT );
    # $self->message( 3, "Checking if shared memory key \"", ( $opts->{key} || $self->key ), "\" exists with flags '$flags'." );
    my $semid;
    try
    {
        $semid = semget( $serial, 3, $flags );
        # $self->message( 3, "Found the shared memory? ", defined( $semid ) ? 'yes' : 'no' );
        if( defined( $semid ) )
        {
            my $found = semctl( $semid, SEM_MARKER, IPC::SysV::GETVAL, 0 );
            semctl( $semid, 0, IPC::SysV::IPC_RMID, 0 );
            return( $found == SHM_EXISTS ? 1 : 0 );
        }
        else
        {
            # $self->message( 3, "Error getting a semaphore: $!" );
            return( 0 ) if( $! =~ /\bNo[[:blank:]]+such[[:blank:]]+file\b/ );
            return;
        }
    }
    catch( $e )
    {
        # $self->message( 3, "Trying to access shared memory triggered error: $e" );
        semctl( $semid, 0, IPC::SysV::IPC_RMID, 0 ) if( $semid );
        return( 0 );
    }
}

sub flags
{
    my $self   = shift( @_ );
    my $opts   = $self->_get_args_as_hash( @_ );
    no warnings 'uninitialized';
    # $self->message( 3, "Option mode value is '$opts->{mode}'." );
    $opts->{create} = $self->create unless( length( $opts->{create} ) );
    $opts->{exclusive} = $self->exclusive unless( length( $opts->{exclusive} ) );
    $opts->{mode} = $self->mode unless( length( $opts->{mode} ) );
    my $flags  = 0;
    # $self->message( 3, "Adding create bit" ) if( $opts->{create} );
    $flags    |= IPC::SysV::IPC_CREAT if( $opts->{create} );
    # $self->message( 3, "Adding exclusive bit" ) if( $opts->{exclusive} );
    $flags    |= IPC::SysV::IPC_EXCL  if( $opts->{exclusive} );
    # $self->message( 3, "Adding mode '", ( $opts->{mode} || 0666 ), "'" );
    $flags    |= ( $opts->{mode} || 0666 );
    # $self->message( 3, "Returning flags value '$flags'." );
    return( $flags );
}

# sub id { return( shift->_set_get_scalar( 'id', @_ ) ); }
sub id
{
    my $self = shift( @_ );
    my @callinfo = caller;
    no warnings 'uninitialized';
    # $self->message( 3, "Called from package $callinfo[0] in file $callinfo[1] at line $callinfo[2] with ", scalar( @_ ) ? ( "args: '" . join( "', '", @_ ) . "'." ) : 'no argument.' );
    if( @_ )
    {
        # $self->message( 3, "Setting id to value '", defined( $_[0] ) ? $_[0] : 'undef()', "'." );
        $self->{id} = shift( @_ );
    }
    # $self->message( 3, "Returning id '$self->{id}'" );
    return( $self->{id} );
}

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
    my $type = shift( @_ );
    my $timeout = shift( @_ );
    # $type = LOCK_EX if( !defined( $type ) );
    $type = LOCK_SH if( !defined( $type ) );
    return( $self->unlock ) if( ( $type & LOCK_UN ) );
    return( 1 ) if( $self->locked & $type );
    $timeout = 0 if( !defined( $timeout ) || $timeout !~ /^\d+$/ );
    # If the lock is different, release it first
    $self->unlock if( $self->locked );
    my $semid = $self->semid ||
        return( $self->error( "No semaphore id set yet." ) );
    # $self->message( 3, "Setting a lock on semaphore id \"$semid\" with type \"$type\" and arguments: ", sub{ $self->dump( $SEMOP_ARGS->{ $type } ) } );
    try
    {
        local $SIG{ALRM} = sub{ die( "timeout" ); };
        alarm( $timeout );
        my $rc = $self->op( @{$SEMOP_ARGS->{ $type }} );
        # XXX Remove this
#         my $v = $self->debug;
#         $self->debug(3);
#         $self->message( 3, "Semaphore arguments are: ", sub{ $self->dump( $SEMOP_ARGS ) } );
#         $self->debug($v);
        alarm( 0 );
        if( $rc )
        {
            $self->locked( $type );
        }
        else
        {
            # $self->message( 3, "Unable to set a lock on semaphore id \"$semid\": $!" );
            return( $self->error( "Failed to set a lock on semaphore id \"$semid\" for lock type $type: $!" ) );
        }
    }
    catch( $e )
    {
        return( $self->error( "Unable to set a lock: $e" ) );
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
    $rv = semop( $semid, $data ) || do
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
    my $serial;
    if( length( $opts->{key} ) )
    {
        $self->message( 4, "Getting serial based on key '$opts->{key}'." );
        $serial = $self->_str2key( $opts->{key} ) || 
            return( $self->error( "Cannot get serial from key '$opts->{key}': ", $self->error ) );
        # $serial = $opts->{key};
    }
    else
    {
        $self->message( 3, "Getting serial ($self->{serial})" );
        $serial = $self->serial;
        # $serial = $self->key;
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
    my $flags = $self->flags( create => $create );
    $self->message( 3, "Trying to get the shared memory segment with key '", ( $opts->{key} || $self->key ), "' with serial '$serial', size '$opts->{size}' and mode '$opts->{mode}'." );
    my $id = shmget( $serial, $opts->{size}, $flags );
    if( defined( $id ) )
    {
        # $self->message( 3, "Got the shared memory first time around with id \"$id\"." );
    }
    else
    {
        $self->message( 4, "Shared memory does not exists yet ($!), trying to create it now start from $serial" );
        my $newflags = ( $flags & IPC::SysV::IPC_CREAT ) ? $flags : ( $flags | IPC::SysV::IPC_CREAT );
        my $limit = ( $serial + 10 );
        # IPC::SysV::ftok has likely made the serial unique, but as stated in the manual page, there is no guarantee
        while( $serial <= $limit )
        {
            $id = shmget( $serial, $opts->{size}, $newflags | IPC::SysV::IPC_CREAT );
            $self->message( 4, "Shared memory key '$serial' worked ? ", defined( $serial ) ? 'yes' : 'no' );
            $serial++;
            last if( defined( $id ) );
        }
    }
    
    if( !defined( $id ) )
    {
        # $self->message( 3, "Could not open shared memory with flags '$flags': $!" );
        return( $self->error( "Unable to create shared memory id with key \"$serial\" and flags \"$flags\": $!" ) );
    }
    $self->serial( $serial );
    
    # $self->message( 3, "Shared memory created with id \"$id\"." );
    # The value 3 can be anything above 0 and below the limit set by SEMMSL. On Linux system, this is usually 32,000. Seem semget(2) man page
    my $semid = semget( $serial, 3, $flags );
    if( !defined( $semid ) )
    {
        # $self->message( 3, "Could not get a semaphore, trying again with creating it." );
        my $newflags = ( $flags | IPC::SysV::IPC_CREAT );
        $semid = semget( $serial, 3, $newflags );
        return( $self->error( "Unable to get a semaphore for shared memory key \"", ( $opts->{key} || $self->key ), "\" wth id \"$id\": $!" ) ) if( !defined( $semid ) );
        # $self->message( 3, "Retrieved existing semaphore with semaphore id \"$semid\"." );
    }
    # $self->message( 3, "Semaphore id is '$semid'" );
    $self->message( 3, "Creating new ", __PACKAGE__, " object with auto destroy set to '", $self->destroy, "'." );
    my $new = $self->new(
        key     => ( $opts->{key} || $self->key ),
        debug   => $self->debug,
        mode    => $self->mode,
        destroy => $self->destroy,
        destroy_semaphore => $self->destroy_semaphore,
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
    $new->flags( $flags );
    if( $there == SHM_EXISTS )
    {
        # $self->message( 3, "Binding to existing segment on ", $new->id );
    }
    else
    {
        # $self->message( 3, "New segment on ", $new->id );
        # We initialise the semaphore with value of 1
        $new->stat( SEM_MARKER, SHM_EXISTS ) ||
            return( $new->error( "Unable to set semaphore during object creation: ", $new->error ) );
        # $self->message( 3, "Semaphore created." );
    }
    
    $new->op( @{$SEMOP_ARGS->{(LOCK_SH | LOCK_UN)}} );
    # $self->message( 3, "Returning new object persuant to open" );
    return( $new );
}

sub owner { return( shift->_set_get_scalar( 'owner', @_ ) ); }

sub pid
{
    my $self = shift( @_ );
    my $sem  = shift( @_ );
    my $semid = $self->semid ||
        return( $self->error( "No semaphore set yet. You must open the shared memory first to remove semaphore." ) ) if( !length( $id ) );
    my $v = semctl( $semid, $sem, IPC::SysV::GETPID, 0 );
    return( $v ? 0 + $v : undef() );
}

sub rand
{
    my $self = shift( @_ );
    my $size = $self->size || 1024;
    my $key  = shmget( IPC::SysV::IPC_PRIVATE, $size, IPC::SysV::S_IRWXU | IPC::SysV::S_IRWXG | IPC::SysV::S_IRWXO ) ||
        return( $self->error( "Unable to generate a share memory key: $!" ) );
    return( $key );
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
    # $self->message( 3, "Reading $size bytes of data from memory for id '$id'." );
    return( $self->error( "No shared memory id! Have you opened it first?" ) ) if( !length( $id ) );
    my $buffer = '';
    my $addr = $self->addr;
    if( $addr )
    {
        $self->message( 3, "memread( $addr, ", ( defined( $buffer ) ? "'$buffer'" : "''" ), ", 0, $size )", { prefix => '<<<' });
        memread( $addr, $buffer, 0, $size ) ||
            return( $self->error( "Unable to read data from shared memory address \"$addr\" using memread: $!" ) );
    }
    else
    {
        $self->message( 3, "shmread( $id, ", ( defined( $buffer ) ? "'$buffer'" : "''" ), ", 0, $size )", { prefix => '<<<' });
        shmread( $id, $buffer, 0, $size ) ||
            return( $self->error( "Unable to read data from shared memory id \"$id\": $!" ) );
    }
    # Get rid of nulls end padded
    # $buffer = unpack( "A*", $buffer );
    my $data;
    try
    {
        $data = Storable::thaw( $buffer );
        $self->message( 4, "Decoded data '$buffer' -> '$data': ", sub{ $self->dump( $data ) });
    }
    catch( $e )
    {
        return( $self->error( "An error occured while decoding data using Storable::thaw: $e", ( length( $buffer ) <= 1024 ? "\nData is: '$buffer'" : '' ) ) );
    }
    
    if( scalar( @_ ) > 1 )
    {
        $_[1] = $data;
        return( length( $_[1] ) || "0E0" );
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
    # $self->message( 3, "Called to remove shared memory id \"$id\"." );
    return( $self->error( "No shared memory id! Have you opened it first?" ) ) if( !length( $id ) );
    my $semid = $self->semid;
    return( $self->error( "No semaphore set yet. You must open the shared memory first to remove semaphore." ) ) if( !length( $semid ) );
    $self->message( 3, "Removing shared memory segment with id '$id' and semaphore id '$semid'." );
    $self->unlock();
    # Remove share memory segment
    if( !defined( shmctl( $id, IPC::SysV::IPC_RMID, 0 ) ) )
    {
        $self->message( 3, "Failed to remove shared memory segment with id '$id': $!" );
        return( $self->error( "Unable to remove share memory segement id '$id' (IPC_RMID is '", IPC::SysV::IPC_RMID, "'): $!" ) );
    }
    # Remove semaphore
    my $rv;
    if( !defined( $rv = semctl( $semid, 0, IPC::SysV::IPC_RMID, 0 ) ) )
    {
        $self->message( 3, "Failed to remove semaphore with id '$semid': $!" );
        $self->error( "Warning only: could not remove the semaphore id \"$semid\": $!" );
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
    $self->message( 3, "Removing semaphore with id '$semid' for shared memory segment with id '$id'." );
    $self->unlock();
    my $rv;
    if( !defined( $rv = semctl( $semid, 0, IPC::SysV::IPC_RMID, 0 ) ) )
    {
        $self->message( 3, "Failed to remove semaphore with id '$semid': $!" );
        $self->error( "Warning only: could not remove the semaphore id \"$semid\": $!" );
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

sub serial { return( shift->_set_get_scalar( 'serial', @_ ) ); }

sub shmstat
{
    my $self = shift( @_ );
    my $data = '';
    my $id = $self->id || return( $self->error( "No shared memory id set!" ) );
    shmctl( $id, IPC::SysV::IPC_STAT, $data ) or
        return( $self->error( "Unable to stat shared memory with id '$id': $!" ) );
    return( Module::Generic::SharedStat->new->unpack( $data ) );
}

sub size { return( shift->_set_get_scalar( 'size', @_ ) ); }

sub stat
{
    my $self = shift( @_ );
    my $id   = $self->semid;
    return( $self->error( "No semaphore set yet. You must open the shared memory first to set the semaphore." ) ) if( !length( $id ) );
    if( @_ )
    {
        if( @_ == 1 )
        {
            my $sem = shift( @_ );
            # $self->message( 3, "Retrieving semaphore value for '$sem'" );
            my $v = semctl( $id, $sem, IPC::SysV::GETVAL, 0 );
            return( $v ? 0 + $v : undef() );
        }
        else
        {
            my( $sem, $val ) = @_;
            # $self->message( 3, "Setting semaphore '$sem' with value '$val'." );
            semctl( $id, $sem, IPC::SysV::SETVAL, $val ) ||
                return( $self->error( "Unable to semctl with semaphore id '$id', semaphore '$sem', SETVAL='", IPC::SysV::SETVAL, "' and value='$val': $!" ) );
        }
    }
    else
    {
        my $data = '';
        if( wantarray() )
        {
            # $self->message( 3, "Returning all semaphore data." );
            semctl( $id, 0, IPC::SysV::GETALL, $data ) || return( () );
            return( ( unpack( "s$N*", $data ) ) );
        }
        else
        {
            # $self->message( 3, "Returning all semaphore data as Module::Generic::SemStat object." );
            semctl( $id, 0, IPC::SysV::IPC_STAT, $data ) ||
                return( $self->error( "Unable to stat semaphore with id '$id': $!" ) );
            return( Module::Generic::SemStat->new->unpack( $data ) );
        }
    }
}

sub supported { return( $SYSV_SUPPORTED ); }

sub unlock
{
    my $self = shift( @_ );
    return(1) if( !$self->locked );
    my $semid = $self->semid;
    return( $self->error( "No semaphore set yet. You must open the shared memory first to unlock semaphore." ) ) if( !length( $semid ) );
    # $self->message( 3, "Removing lock for semaphore id \"$semid\" and locked value '$self->{locked}'." );
    my $type = ( $self->locked | LOCK_UN );
    $type ^= LOCK_NB if( $type & LOCK_NB );
    if( defined( $self->op( @{$SEMOP_ARGS->{ $type }} ) ) )
    {
        $self->locked( 0 );
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
    # $self->message( 3, "Called from file $callinfo[1] at line $callinfo[2]" );
    # $self->message( 3, "Size limit set to '$size'" );
    # my $j = JSON->new->utf8->relaxed->allow_nonref->convert_blessed;
    my $encoded;
    try
    {
        # $encoded = $j->encode( $data );
        $encoded = Storable::freeze( $data );
    }
    catch( $e )
    {
        return( $self->error( "An error occured encoding data provided using Storable::freeze: $e. Data was: '$data'" ) );
    }
    
    if( length( $encoded ) > $size )
    {
        return( $self->error( "Data to write are ", length( $encoded ), " bytes long and exceed the maximum you have set of '$size'." ) );
    }
    # $self->message( 3, "Storing ", length( $encoded ), " bytes of data", ( length( $encoded ) <= 2048 ? ":\n'$encoded'" : '.' ) );
    # $size = length( $encoded );
    my $addr = $self->addr;
    if( $addr )
    {
        memwrite( $addr, $encoded, 0, $size ) ||
            return( $self->error( "Unable to write to shared memory address '$addr' using memwrite: $!" ) );
    }
    else
    {
        $self->message( 3, "shmwrite( $id, '$encoded', 0, $size )", { prefix => '>>>' } );
        # id, data, position, size
        shmwrite( $id, $encoded, 0, $size ) ||
            return( $self->error( "Unable to write to shared memory id '$id' with ", length( $encoded ), " bytes of data ($encoded) encoded and memory size of $size: $!" ) );
    }
    # $self->message( 3, "Successfully wrote ", length( $encoded ), " bytes of data to memory." );
    return( $self );
}

sub _str2key
{
    my $self = shift( @_ );
    my $key  = shift( @_ );
    if( !defined( $key ) || $key eq '' )
    {
        return( IPC::SysV::IPC_PRIVATE );
    }
    elsif( $key =~ /^\d+$/ )
    {
        my $id = IPC::SysV::ftok( __FILE__, $key ) ||
            return( $self->error( "Unable to get a key using IPC::SysV::ftok: $!" ) );
        return( $id );
    }
    else
    {
        my $id = 0;
        $id += $_ for( unpack( "C*", $key ) );
        # We use the root as a reliable and stable path.
        # I initially though about using __FILE__, but during testing this would be in ./blib/lib and beside one user might use a version of this module somewhere while the one used under Apache/mod_perl2 could be somewhere else and this would render the generation of the IPC key unreliable and unrepeatable
        my $val = IPC::SysV::ftok( File::Spec->rootdir(), $id );
        $self->message( 4, "Calling IPC::SysV::ftok for key '$key' with file '/' and numeric id '$id' returning '$val'." );
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

# XXX Module::Generic::SharedStat class
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
}

# XXX Module::Generic::SemStat class
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
}

1;

__END__

