##----------------------------------------------------------------------------
## Contextual Global Storage - ~/lib/Module/Generic/Global.pm
## Version v0.1.0
## Copyright(c) 2025 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2025/05/06
## Modified 2025/05/06
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Module::Generic::Global;
BEGIN
{
    use strict;
    use warnings;
    use warnings::register;
    use parent qw( Exporter );
    use vars qw(
        $MOD_PERL $REPO $MUTEX $ERRORS $LOCKS $LOCK_MUTEX $DEBUG $PerlConfig
        @EXPORT_OK %EXPORT_TAGS $VERSION
    );
    use Config;
    use Scalar::Util ();
    use Storable::Improved ();
    # mod_perl/2.0.10
    if( CORE::exists( $ENV{MOD_PERL} )
        &&
        ( ( $MOD_PERL ) = $ENV{MOD_PERL} =~ /^mod_perl\/(\d+\.[\d\.]+)/ ) )
    {
        select( ( select( STDOUT ), $| = 1 )[0] );
        require Apache2::Log;
        require Apache2::ServerUtil;
        require Apache2::RequestRec;
        require Apache2::RequestUtil;
        require Apache2::ServerRec;
        require ModPerl::Util;
        require Apache2::MPM;
        require Apache2::Const;
        Apache2::Const->import( compile => qw( :log OK ) );
    }
    our $PerlConfig = { %Config };
    # Maximum retries and delay (microseconds) for locking with APR mutex
    use constant MAX_RETRIES => ( ( $ENV{MG_MAX_RETRIES} && $ENV{MG_MAX_RETRIES} =~ /^\d+$/ ) ? $ENV{MG_MAX_RETRIES} : 10 );
    use constant RETRY_DELAY => ( ( $ENV{MG_RETRY_DELAY} && $ENV{MG_RETRY_DELAY} =~ /^\d+$/ ) ? $ENV{MG_RETRY_DELAY} : 10_000 );  # 10ms
    use constant ERROR_DELAY => ( ( $ENV{MG_ERROR_DELAY} && $ENV{MG_ERROR_DELAY} =~ /^\d+$/ ) ? $ENV{MG_ERROR_DELAY} : 5_000 );   # 5ms (faster for errors)
    # use constant CAN_THREADS => ( $Config{useithreads} ? 1 : 0 );
    sub CAN_THREADS () { CORE::return( $PerlConfig->{useithreads} ? 1 : 0 ); }
    # The following 2 constants are defined as not immutable, because whether threads has been loaded or not could change during runtime. Using 'constant' would not cut it.
    sub HAS_THREADS () { CORE::return( $PerlConfig->{useithreads} && $INC{'threads.pm'} ? 1 : 0 ); }

    sub IN_THREAD () { CORE::return( $PerlConfig->{useithreads} && $INC{'threads.pm'} && threads->tid != 0 ? 1 : 0 ); }

    use constant MOD_PERL => $MOD_PERL;

    my $mpm;
    my $mpm_threaded    = 0;
    my $use_mutex       = 0;
    my $need_shared     = CAN_THREADS();
    our( $MUTEX, $LOCK_MUTEX );
    our $REPO           = {};
    our $ERRORS         = {};
    our $LOCKS          = {};
    # Check if we are running under Apache Worker/Event MPM
    if( $MOD_PERL )
    {
        my $rc;
        local $@;
        eval{ $rc = Apache2::MPM->is_threaded };
        if( $rc )
        {
            $mpm_threaded = 1;
            # Normally, Perl must be compiled with -Duseithreads to work under threaded Apache, but we double check that
            if( $PerlConfig->{useithreads} )
            {
                local $@;
                # try-catch
                eval
                {
                    require threads;
                    require threads::shared;
                    threads->import();
                    threads::shared->import();
                };

                if( $@ )
                {
                    warn( "Unable to initialise mod_perl threading support: $@" );
                }
                else
                {
                    $need_shared = 1;
                }
            }
            # Somehow, a race condition occurred, and we need to fallback to APR::ThreadRWLock as mutex
            unless( $need_shared )
            {
                require APR::ThreadRWLock;
                require APR::Const;
                APR::Const->import( compile => qw( :error ) );
                my $pool = Apache2::ServerUtil->server->process->pool;
                # For our main repository
                $MUTEX = APR::ThreadRWLock->new( $pool );
                # For the lock service
                $LOCK_MUTEX = APR::ThreadRWLock->new( $pool );
                $use_mutex = 1;
            }
            # else the user is running under Apache Prefork, which is safe for global variables
            if( !$need_shared && !$MUTEX )
            {
                warn( "mod_perl detected with threaded MPM, but Perl is not threaded ($PerlConfig->{useithreads}=0) and mutex creation failed. Global repositories may be corrupted, and locks may be inefficient without thread-safety." );
            }
        }
        elsif( $@ )
        {
            warn( "ModPerl seems to be enabled, but could not get the threaded status of Apache: $@" );
        }
        # otherwise, we are running under Apache Prefork, and no locking is required

        eval
        {
            my $type = Apache2::MPM->show;
            $mpm = lc( $type ) if( defined( $type ) );
        };
    }

    if( $need_shared )
    {
        unless( $INC{'threads.pm'} )
        {
            local $@;
            # try-catch
            eval
            {
                require threads;
                threads->import();
            };
            if( $@ )
            {
                warn( "Unable to load threads: $@" );
            }
        }
        unless( $INC{'threads/shared.pm'} )
        {
            local $@;
            # try-catch
            eval
            {
                require threads::shared;
                threads::shared->import();
            };
            if( $@ )
            {
                warn( "Unable to load threads::shared: $@" );
            }
        }
        my %repo :shared;
        my %errs :shared;
        my %locks :shared;
        $REPO   = \%repo;
        $ERRORS = \%errs;
        $LOCKS  = \%locks;
    }

    sub _NEED_SHARED () { CORE::return( $need_shared ); }
    sub USE_MUTEX () { CORE::return( $use_mutex ); }
    sub MPM () { CORE::return( $mpm ); }
    sub HAS_MPM_THREADS () { CORE::return( $mpm_threaded ); }

    our @EXPORT_OK = qw( CAN_THREADS HAS_THREADS IN_THREAD MOD_PERL MPM HAS_MPM_THREADS );
    our %EXPORT_TAGS = ( 'const' => [@EXPORT_OK] );

    our $VERSION = 'v0.1.0';
};

use strict;
use warnings;

# Object-level:
# Module::Generic::Global->new( 'my_repo' => $blessed_object ) || die( Module::Generic::Global->error );
# Class-level:
# Module::Generic::Global->new( 'my_repo' => 'My::Module' ) || die( Module::Generic::Global->error );
sub new
{
    my $this = shift( @_ );
    my $ns   = shift( @_ ) || return( $this->error( "No namespace was provided." ) );
    my $what = shift( @_ );
    unless( defined( $what ) && CORE::ref( $what ) )
    {
        return( $this->error( "No controller element was provided for this namespace $ns" ) ) if( !$what );
    }
    my $opts = $this->_get_args_as_hash( @_ );

    my $ref = 
    {
        _namespace  => $ns,
        _key        => undef,
        _mode       => undef,
        _error      => undef,
        debug       => ( $opts->{debug} // $DEBUG // 0 ),
    };
    my $self = bless( $ref => ( ref( $this ) || $this ) );

    # Special case if the context is 'system', and neither a class name, nor an object
    if( do{ no warnings; "$what" eq 'system' } )
    {
        $self->{_key}  = 'system';
        $self->{_mode} = 'system';
    }
    elsif( Scalar::Util::blessed( $what ) )
    {
        my $id = Scalar::Util::refaddr( $what );
        # Object-level keys have granular identification down to the thread ID if possible
        $self->{_key}  = $opts->{key} ? $opts->{key} : join( ';', $id, $$, ( HAS_THREADS ? threads->tid : () ) );
        $self->{_mode} = 'object';
        # For locks
        $self->{_class_key}  = join( ';', ref( $what ), $$ );
    }
    # I am not going to do a sanity check on the class name provided.
    elsif( !ref( $what ) )
    {
        my $class = $what;
        # Class-level keys have granular identification only down to the process ID, so they can be shared among threads, if need be.
        $self->{_key}  = $opts->{key} ? $opts->{key} : join( ';', $class, $$ );
        $self->{_mode} = 'class';
    }
    else
    {
        return( $self->error( "Module::Generic::Global->new requires either a class name or an object to be provided." ) );
    }
    return( $self );
}

{
    no warnings 'once';
    *clear = \&remove;
}

sub cleanup_register
{
    my( $this, $r ) = @_;
    # Apache memory cleanup
    if( $r && Scalar::Util::blessed( $r ) && $r->isa( 'Apache2::RequestRec' ) )
    {
        eval
        {
            $r->pool->cleanup_register(sub
            {
                my $r = shift( @_ );
                $r->log->notice( "Clearing REPO keys: ", join( ", ", keys %$REPO ) ) if( $DEBUG );
                %$REPO      = ();
                %$ERRORS    = ();
                %$LOCKS     = ();
            }, $r );
        };
    }
}

sub clear_error
{
    my $self  = shift( @_ );
    my $class = ref( $self ) || $self;
    my $err_key = HAS_THREADS() ? join( ';', $class, $$, threads->tid ) : join( ';', $class, $$ );

    $self->{_error} = undef if( ref( $self ) );
    $self->_lock_write( $ERRORS, delay => ERROR_DELAY ) || die( "Unable to get a lock on \$ERRORS" );
    eval
    {
        CORE::delete( $ERRORS->{ $err_key } );
    };
    $self->_unlock;
    return( $self );
}

sub debug
{
    my $self = shift( @_ );
    $self->{debug} = shift( @_ ) if( @_ );
    return( $self->{debug} );
}

sub error
{
    my $self = shift( @_ );
    my $class = ref( $self ) || $self;
    my $err_key = HAS_THREADS ? join( ';', $class, $$, threads->tid ) : join( ';', $class, $$ );
    if( @_ )
    {
        my $msg = join( '', @_ );
        my $ex = Module::Generic::Global::Exception->new({ message => $msg, code => 500, skip_frames => 1 });
        warn( $ex ) if( warnings::enabled() );
        $self->_lock_write( $ERRORS, delay => ERROR_DELAY ) || die( "Unable to get a lock on \$ERRORS" );
        $self->{_error} = $ex if( ref( $self ) );
        eval
        {
            $ERRORS->{ $err_key } = Storable::Improved::freeze( $ex );
        };
        $self->_unlock;
        if( $@ )
        {
            warn( "Error serialising exception object: $@" ) if( warnings::enabled() );
        }
        return;
    }
    my $o;
    $o = $self->{_error} if( ref( $self ) );
    unless( $o )
    {
        $self->_lock_read( $ERRORS, delay => ERROR_DELAY ) || die( "Unable to get a lock on \$ERRORS" );
        if( my $store = $ERRORS->{ $err_key } )
        {
            # try-catch
            local $@;
            eval
            {
                $o = Storable::Improved::thaw( $store );
            };
            if( $@ )
            {
                warn( "Error deserialising stored exception object: $@" ) if( warnings::enabled() );
            }
        }
    }
    return( $o );
}

sub exists
{
    my $self = shift( @_ );
    my $ns   = $self->{_namespace} || die( "No namespace is set." );
    my $key  = $self->{_key} || die( "No key is set." );
    # Make sure the repository is shared if needed
    $self->_share_repo( $ns );
    return( CORE::exists( $REPO->{ $ns }->{ $key } ) ? 1 : 0 );
}

sub get
{
    my $self = shift( @_ );
    my $ns   = $self->{_namespace} || die( "No namespace is set." );
    my $key  = $self->{_key} || die( "No key is set." );
    # Make sure the repository is shared if needed
    $self->_share_repo( $ns );
    my $ref  = \$REPO->{ $ns }->{ $key };
    $$ref //= undef;
    $self->_lock_read( $ref ) || return( $self->error( "Unable to lock the repository to read from it." ) );
    my $store = $$ref;
    $self->_unlock;
    if( CORE::length( $store // '' ) )
    {
        my $value;
        local $@;
        eval
        {
            $value = Storable::Improved::thaw( $store );
        };
        if( $@ )
        {
            return( $self->error( "Failed to deserialise data: $@" ) );
        }
        if( defined( $value ) && Scalar::Util::blessed( $value ) && $value->isa( 'Module::Generic::Global::Scalar' ) )
        {
            $value = $value->as_string;
        }
        return( $value );
    }
    else
    {
        return( $store );
    }
}

sub length
{
    my $self = shift( @_ );
    my $ns   = $self->{_namespace} || die( "No namespace is set." );
    # Make sure the repository is shared if needed
    $self->_share_repo( $ns );
    return(0) unless( CORE::exists( $REPO->{ $ns } ) && CORE::ref( $REPO->{ $ns } ) eq 'HASH' );
    return( scalar( keys( %{$REPO->{ $ns }} ) ) );
}

sub lock
{
    my $self = shift( @_ );
    # A lock is class and process-wide, so if our object was created for object-scope, we use the class key instead of the key
    my $key = ( $self->{_mode} eq 'class' || $self->{_mode} eq 'system' ) ? $self->{_key} : $self->{_class_key};
    die( "No key found in our object!" ) if( !$key );
    if( HAS_THREADS && !$MUTEX )
    {
        my $lock_ref = \$LOCKS->{ $key };
        $$lock_ref //= 0;
        # try-catch
        my $rv;
        eval{ $rv = CORE::lock( $lock_ref ) };
        if( $@ )
        {
            return( $self->error({
                message => "Failed to acquire shared lock for key $key: $@",
                class => 'Module::Generic::Global::Exception',
                code => 503
            }) );
        }
        # We return the value returned by CORE::lock, which, when it goes out of scopre in the caller's block, the lock also will be automatically removed.
        return( $rv );
    }
    elsif( $MUTEX )
    {
        my $rv = $self->_lock_mutex( $LOCK_MUTEX, delay => RETRY_DELAY, rw => 1 );
        if( !$rv )
        {
            return( $self->error( {
                message => "Failed to acquire shared lock for key $key after ", MAX_RETRIES, " retries",
                class => 'Module::Generic::Global::Exception',
                code => 503
            } ) );
        }
        # Return a special private object that will unlock the mutex when it gets out of scope, just like CORE::lock() does, so the user does not have to worry about calling unlock()
        return( Module::Generic::Global::Guard->new( $LOCK_MUTEX ) );
    }
    return(1);
}

sub remove
{
    my $self = shift( @_ );
    my $ns   = $self->{_namespace} || die( "No namespace is set." );
    my $key  = $self->{_key} || die( "No key is set." );
    # Make sure the repository is shared if needed
    $self->_share_repo( $ns );
    if( !CORE::exists( $REPO->{ $ns }->{ $key } ) )
    {
        return(1);
    }
    my $ref  = \$REPO->{ $ns }->{ $key };
    $$ref //= '';
    $self->_lock_write( $ref ) || return( $self->error( "Unable to lock the repository to write to it." ) );
    CORE::delete( $REPO->{ $ns }->{ $key } );
    $self->_unlock;
    return(1);
}

sub set
{
    my( $self, $value ) = @_;
    my $ns  = $self->{_namespace} || die( "No namespace is set." );
    my $key = $self->{_key} || die( "No key is set." );
    $value = ref( $value // '' ) ? $value : Module::Generic::Global::Scalar->new( \$value );
    my $store = eval{ Storable::Improved::freeze( $value ) };
    local $@;
    if( $@ )
    {
        return( $self->error( "Failed to serialise object: $@" ) );
    }
    # Make sure the repository is shared if needed
    $self->_share_repo( $ns );
    my $ref = \$REPO->{ $ns }->{ $key };
    $$ref //= '';
    $self->_lock_write( $ref ) || return( $self->error( "Unable to lock the repository to write to it." ) );
    $$ref = $store;
    $self->_unlock;
    return(1);
}

sub unlock
{
    my $self = shift( @_ );
    return(1) unless( defined( $LOCK_MUTEX ) );
    $LOCK_MUTEX->unlock;
    return(1);
}

sub _get_args_as_hash
{
    my $self = shift( @_ );
    my $ref  = {};
    if( scalar( @_ ) == 1 && defined( $_[0] ) && ref( $_[0] ) eq 'HASH' )
    {
        $ref = shift( @_ );
    }
    elsif( !( scalar( @_ ) % 2 ) )
    {
        $ref = { @_ };
    }
    return( $ref );
}

sub _lock
{
    my $self = shift( @_ );
    my $ref  = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    my $rw = $opts->{rw} // 0;
    if( HAS_THREADS && !$MUTEX )
    {
        # try-catch
        local $@;
        my $rv;
        eval{ $rv = CORE::lock( $ref ) };
        if( $@ )
        {
            warn( "Error locking \$ref (", overload::StrVal( $ref // 'undef' ), "): $@" );
            return;
        }
        return( $rv );
    }
    elsif( $MUTEX )
    {
        $opts->{delay} //= RETRY_DELAY;
        return( $self->_lock_mutex( $MUTEX, %$opts ) );
    }
    return(1);
}

sub _lock_mutex
{
    my $self = shift( @_ );
    my $mutex = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    # Mutex is not defined
    return(0) unless( $mutex );
    warn( "No base delay was specified." ) if( !CORE::exists( $opts->{delay} ) );
    my $base_delay = $opts->{delay} // RETRY_DELAY;
    die( "No read or write mode was specified." ) if( !CORE::exists( $opts->{rw} ) || !CORE::length( $opts->{rw} ) );
    my $rw = $opts->{rw};
    for( my $retry = 0 ; $retry < MAX_RETRIES ; $retry++ )
    {
        # try-catch
        local $@;
        my $rc;
        eval{ $rc = $rw ? $mutex->trywrlock : $mutex->tryrdlock };
        if( $@ )
        {
            warn( "Unable to acquire ", ( $rw ? 'write' : 'read' ), " lock using mutex from APR::ThreadRWLock: $@" );
            return;
        }
        return(1) if( !$rc );
        if( $rc == &APR::Const::EAGAIN || $rc == &APR::Const::EBUSY )
        {
            # Exponential backoff
            my $delay = $base_delay * ( 2 ** $retry );
            # Sleep for delay µs
            select( undef, undef, undef, $delay / 1_000_000.0 );
            next;
        }
    }

    warn( "Failed to acquire write lock" );
    return(0);
}

sub _lock_write
{
    my $self = shift( @_ );
    my $ref  = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    $opts->{rw} = 1;
    return( $self->_lock( $ref, %$opts ) );
}

sub _lock_read
{
    my $self = shift( @_ );
    my $ref  = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    $opts->{rw} = 0;
    return( $self->_lock( $ref, %$opts ) );
}

sub _message
{
    my $self = shift( @_ );
    my $required_level;
    if( $_[0] =~ /^\d{1,2}$/ )
    {
        $required_level = shift( @_ );
    }
    else
    {
        $required_level = 0;
    }
    return if( !$self->{debug} || $self->{debug} < $required_level );
    my $msg = join( '', map( ref( $_ ) eq 'CODE' ? $_->() : $_, @_ ) );
    my $frame = 0;
    my $sub_pack = (caller(1))[3] || '';
    my( $pkg, $file, $line ) = caller( $frame );
    my $sub = ( caller( $frame + 1 ) )[3] // '';
    my $sub2;
    if( CORE::length( $sub ) )
    {
        $sub2 = substr( $sub, rindex( $sub, '::' ) + 2 );
    }
    else
    {
        $sub2 = 'main';
    }

    my $proc_info = " [PID: $$]";
    if( HAS_THREADS )
    {
        my $tid = threads->tid;
        $proc_info .= ' -> [thread id ' . $tid . ']' if( $tid );
    }

    $msg =~ s/\n$//gs;
    my $long_msg = "## ${pkg}::${sub2}() [$line]${proc_info}: " . join( "\n## ", split( /\n/, $msg ) );
    my( $r, $s );
    if( MOD_PERL )
    {
        # try-catch
        local $@;
        eval
        {
            $r = Apache2::RequestUtil->request;
        };
        if( $@ )
        {
            warn( "Could not get the global Apache2::ApacheRec: $@" );
        }

        if( $r )
        {
            $r->log->debug( $msg );
        }
        else
        {
            $s = Apache2::ServerUtil->server;
            $s->log->debug( $msg );
        }
    }
    else
    {
        print( STDERR $long_msg, "\n" );
    }
    return(1);
}

sub _share_repo
{
    my $self = shift( @_ );
    my $ns   = shift( @_ ) || die( "No namespace is set." );
    if( !CORE::exists( $REPO->{ $ns } ) )
    {
        if( _NEED_SHARED )
        {
            my %sub_repo :shared;
            $REPO->{ $ns } = \%sub_repo;
        }
        else
        {
            $REPO->{ $ns } = {};
        }
    }
    else
    {
        # $REPO->{ $ns } already exists.
    }
    return(1);
}

sub _unlock
{
    $MUTEX->unlock if( USE_MUTEX );
    return(1);
}

{
    # NOTE: Module::Generic::Global::Guard
    package
        Module::Generic::Global::Guard;
    use strict;
    use warnings;
    our $VERSION = 'v0.1.0';

    sub new
    {
        my $this = shift( @_ );
        my $mutex = shift( @_ );
        return( bless( { mutex => $mutex } => ( ref( $this ) || $this ) ) );
    }

    sub DESTROY
    {
        # <https://perldoc.perl.org/perlobj#Destructors>
        CORE::local( $., $@, $!, $^E, $? );
        CORE::return if( ${^GLOBAL_PHASE} eq 'DESTRUCT' );
        my $self = CORE::shift( @_ );
        CORE::return if( !CORE::defined( $self ) );
        return(1) unless( $self->{mutex} && ref( $self->{mutex} ) );
        $self->{mutex}->unlock;
        return(1);
    };
}

{
    # NOTE: Module::Generic::Global::Scalar
    package
        Module::Generic::Global::Scalar;
    BEGIN
    {
        use strict;
        use warnings;
        use vars qw( $VERSION );
        use overload (
            '""'    => sub{ ${$_[0]} },
            bool    => sub{1},
            fallback => 1,
        );
        our $VERSION = 'v0.1.0';
    };
    use strict;
    use warnings;

    sub new
    {
        my $this = shift( @_ );
        if( @_ != 1 )
        {
            die( 'Bad usage: Module::Generic::Global::Scalar->new( \"Hello world" );' );
        }
        my $str;
        if( ref( $_[0] ) eq 'SCALAR' )
        {
            $str = ${$_[0]};
        }
        elsif( !ref( $_[0] ) )
        {
            $str = $_[0];
        }
        else
        {
            die( "Unsupported value provided: ", overload::StrVal( $_[0] // 'undef' ) );
        }
        return( bless( \$str => ( ref( $this ) || $this ) ) );
    }

    sub as_string { return( ${$_[0]} ); }

    sub FREEZE
    {
        my $self = CORE::shift( @_ );
        my $serialiser = CORE::shift( @_ ) // '';
        my $class = CORE::ref( $self ) || $self;
        # Return an array reference rather than a list so this works with Sereal and CBOR
        # On or before Sereal version 4.023, Sereal did not support multiple values returned
        CORE::return( [$class, $$self] ) if( $serialiser eq 'Sereal' && Sereal::Encoder->VERSION <= version->parse( '4.023' ) );
        # But Storable want a list with the first element being the serialised element
        CORE::return( $$self );
    }

    sub STORABLE_freeze { CORE::return( CORE::shift->FREEZE( @_ ) ); }

    sub STORABLE_thaw { CORE::return( CORE::shift->THAW( @_ ) ); }

    sub THAW
    {
        my( $self, undef, @args ) = @_;
        my( $class, $str );
        if( CORE::scalar( @args ) == 1 && CORE::ref( $args[0] ) eq 'ARRAY' )
        {
            ( $class, $str ) = @{$args[0]};
        }
        else
        {
            $class = CORE::ref( $self ) || $self;
            $str = CORE::shift( @args );
        }
        my $new;
        # Storable pattern requires to modify the object it created rather than returning a new one
        if( CORE::ref( $self ) )
        {
            $$self = $str;
            $new = $self;
        }
        else
        {
            $new = CORE::return( $class->new( $str ) );
        }
        CORE::return( $new );
    }

    sub TO_JSON { CORE::return( ${$_[0]} ); }
}

{
    # NOTE: Module::Generic::Global::Exception
    package
        Module::Generic::Global::Exception;
    BEGIN
    {
        use strict;
        use warnings;
        use vars qw( $VERSION $CALLER_LEVEL $CALLER_INTERNAL );
        use Scalar::Util;
        use Devel::StackTrace;
        use overload (
            '""'    => 'as_string',
            bool    => sub{1},
            fallback => 1,
        );
        $CALLER_LEVEL = 0;
        $CALLER_INTERNAL->{'Module::Generic::Global'}++;
        $CALLER_INTERNAL->{'Module::Generic::Global::Exception'}++;
        our $VERSION = 'v0.1.0';
    };
    use strict;
    use warnings;

    sub new
    {
        my $this = shift( @_ );
        my $class = ref( $this ) || $this;
        my $self = bless( {} => $class );
        my $args = {};
        if( @_ )
        {
            if( Scalar::Util::blessed( $_[0] ) && $_[0]->isa( 'Module::Generic::Exception' ) )
            {
                $args->{object} = shift( @_ );
            }
            elsif( ref( $_[0] ) eq 'HASH' )
            {
                $args  = shift( @_ );
            }
            else
            {
                $args->{message} = join( '', map( ref( $_ ) eq 'CODE' ? $_->() : $_, @_ ) );
            }
        }

        unless( length( $args->{skip_frames} ) )
        {
            # NOTE: Taken from Carp to find the right point in the stack to start from
            no strict 'refs';
            my $caller_func;
            $caller_func = \&{"CORE::GLOBAL::caller"} if( defined( &{"CORE::GLOBAL::caller"} ) );
            my $call_pack = $caller_func ? $caller_func->() : caller();
            ## Check if this is an internal package or a package inheriting from us
            local $CALLER_LEVEL = ( $CALLER_INTERNAL->{ $call_pack } || bless( {} => $call_pack )->isa( 'Module::Generic::Exception' ) ) 
                ? $CALLER_LEVEL 
                : $CALLER_LEVEL + 1;
            my $error_start_frame = sub 
            {
                my $i;
                my $lvl = $CALLER_LEVEL;
                {
                    ++$i;
                    my @caller = $caller_func ? $caller_func->( $i ) : caller( $i );
                    my $pkg = $caller[0];
                    unless( defined( $pkg ) ) 
                    {
                        if( defined( $caller[2] ) ) 
                        {
                            # this can happen when the stash has been deleted
                            # in that case, just assume that it's a reasonable place to
                            # stop (the file and line data will still be intact in any
                            # case) - the only issue is that we can't detect if the
                            # deleted package was internal (so don't do that then)
                            # -doy
                            redo unless( 0 > --$lvl );
                            last;
                        }
                        else 
                        {
                            return(2);
                        }
                    }
                    redo if( $CALLER_INTERNAL->{ $pkg } );
                    redo unless( 0 > --$lvl );
                }
                return( $i - 1 );
            };

            $args->{skip_frames} = $error_start_frame->();
        }

        my $skip_frame = $args->{skip_frames} || 0;
        # Skip one frame to exclude us
        $skip_frame++;

        my $trace = Devel::StackTrace->new( skip_frames => $skip_frame, indent => 1 );
        my $frame = $trace->next_frame;
        my $frame2 = $trace->next_frame;
        $trace->reset_pointer;
        if( ref( $args->{object} ) && Scalar::Util::blessed( $args->{object} ) && ( $args->{object}->isa( 'Module::Generic::Exception' ) || $args->{object}->isa( 'Module::Generic::Global::Exception' ) ) )
        {
            my $o = $args->{object};
            $self->{message} = $o->message;
            $self->{code} = $o->code;
            $self->{type} = $o->type;
            $self->{retry_after} = $o->retry_after;
        }
        else
        {
            # print( STDERR __PACKAGE__, "::init() Got here with args: ", Module::Generic->dump( $args ), "\n" );
            $self->{message} = $args->{message} || '';
            $self->{code} = $args->{code} if( exists( $args->{code} ) );
            $self->{type} = $args->{type} if( exists( $args->{type} ) );
            $self->{retry_after} = $args->{retry_after} if( exists( $args->{retry_after} ) );
            # I do not want to alter the original hash reference, which may adversely affect the calling code if they depend on its content for further execution for example.
            my $copy = {};
            %$copy = %$args;
            CORE::delete( @$copy{ qw( message code type retry_after skip_frames file line subroutine ) } );
            # print( STDERR __PACKAGE__, "::init() Following non-standard keys to set up: '", join( "', '", sort( keys( %$copy ) ) ), "'\n" );
            # Do we have some non-standard parameters?
            foreach my $p ( keys( %$copy ) )
            {
                my $p2 = $p;
                $p2 =~ tr/-/_/;
                $p2 =~ s/[^a-zA-Z0-9\_]+//g;
                $p2 =~ s/^\d+//g;
                # We do not want to trigger an error by calling non-existing subroutines
                if( my $subref = $self->can( $p2 ) )
                {
                    $self->{ $p2 } = $copy->{ $p };
                }
            }
        }
        $self->{file} = $frame->filename;
        $self->{line} = $frame->line;
        ## The caller sub routine ( caller( n ) )[3] returns the sub called by our caller instead of the sub that called our caller, so we go one frame back to get it
        $self->{subroutine} = $frame2->subroutine if( $frame2 );
        $self->{package} = $frame->package;
        $self->{trace} = $trace;
        return( $self );
    }

    # This is important as stringification is called by die, so as per the manual page, we need to end with new line
    # And will add the stack trace
    sub as_string
    {
        no overloading;
        my $self = shift( @_ );
        return( $self->{_cache} ) if( $self->{_cache} && !CORE::length( $self->{_reset} ) );
        my $str = $self->message;
        if( defined( $str ) && 
            Scalar::Util::blessed( $str ) &&
            overload::Method( $str => '""' ) )
        {
            use overloading;
            $str = "$str";
        }
        $str =~ s/\r?\n$//g;
        $str .= sprintf( " within package %s at line %d in file %s\n%s", $self->package, $self->line, $self->file, $self->trace->as_string );
        $self->{_cache} = $str;
        CORE::delete( $self->{_reset} );
        return( $str );
    }

    sub caught 
    {
        my( $class, $e ) = @_;
        return if( ref( $class ) );
        return unless( Scalar::Util::blessed( $e ) && $e->isa( $class ) );
        return( $e );
    }

    sub cause { return( shift->{cause} ); }

    sub code { return( shift->{code} ); }

    sub file { return( shift->{file} ); }

    sub lang { return( shift->{lang} ); }

    sub line { return( shift->{line} ); }

    sub locale { return( shift->{locale} ); }

    sub message { return( shift->{message} ); }

    sub package { return( shift->{package} ); }

    # From perlfunc docmentation on "die":
    # "If LIST was empty or made an empty string, and $@ contains an
    # object reference that has a "PROPAGATE" method, that method will
    # be called with additional file and line number parameters. The
    # return value replaces the value in $@; i.e., as if "$@ = eval {
    # $@->PROPAGATE(__FILE__, __LINE__) };" were called."
    sub PROPAGATE
    {
        my( $self, $file, $line ) = @_;
        if( defined( $file ) && defined( $line ) )
        {
            my $clone = $self->clone;
            $clone->file( $file );
            $clone->line( $line );
            return( $clone );
        }
        return( $self );
    }

    sub rethrow 
    {
        my $self = shift( @_ );
        return if( !Scalar::Util::blessed( $self ) );
        die( $self );
    }

    sub retry_after { return( shift->{retry_after} ); }

    sub subroutine { return( shift->{subroutine} ); }

    sub trace
    {
        my $self = shift( @_ );
        $self->{trace} = shift( @_ ) if( @_ );
        return( $self->{trace} );
    }

    sub throw
    {
        my $self = shift( @_ );
        my $e;
        if( @_ )
        {
            my $msg  = shift( @_ );
            $e = $self->new({
                skip_frames => 1,
                message => $msg,
            });
        }
        else
        {
            $e = $self;
        }
        die( $e );
    }

    sub type { return( shift->{type} ); }
}

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

Module::Generic::Global - Contextual global storage by namespace, class or object

=head1 SYNOPSIS

    use Module::Generic::Global;

    # Class-level global repository
    my $repo = Module::Generic::Global->new( 'errors' => 'My::Module' );
    $repo->set( $exception );
    my $err = $repo->get;

    # Object-level global repository
    my $repo2 = Module::Generic::Global->new( 'cache' => $obj );
    $repo2->set( { foo => 42 } );
    my $data = $repo2->get;

    # System-level repository
    # Here 'system' is a special keyword
    my $repo = Module::Generic::Global->new( 'system_setting' => 'system' );
    # Inside Some::Module:
    $repo->set( $some_value );
    # Inside Another::Module
    my $repo = Module::Generic::Global->new( 'system_setting' => 'system' );
    my $value = $repo->get; # $some_value retrieved

    {
        $repo->lock;
        # Do something
        # Lock is freed once it is out of scope
    }

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

This module provides contextual, thread/process-safe global storage for modules that want to isolate data per-class or per-object, or even across modules (with the C<system> context), using namespaces. Supports Perl ithreads or APR-based threading environments.

It can be used to store and access data in global repository whether Perl operates under a single process, under threads, including Apache Worker/Event MPM with mod_perl2

The repository used is locked in read or write mode before being accessed ensuring no collision and integrity.

It is designed to store one value at a time in the specified namespace in the global repository.

=head1 CONSTRUCTOR

    # System-level repository
    # 'system' is a special keyword
    my $repo = Module::Generic::Global->new( 'global_settings' => 'system' );

    # Class-level global repository
    my $repo = Module::Generic::Global->new( 'errors' => 'My::Module' );
    my $repo = Module::Generic::Global->new( 'errors' => 'My::Module', key => $unique_key );
    my $repo = Module::Generic::Global->new( 'errors' => 'My::Module', { key => $unique_key } );

    # Object-level global repository
    my $repo2 = Module::Generic::Global->new( 'cache' => $obj );
    my $repo2 = Module::Generic::Global->new( 'cache' => $obj, key => $unique_key );
    my $repo2 = Module::Generic::Global->new( 'cache' => $obj, { key => $unique_key } );

=head2 new

Creates a new repository under a given namespace, and context, and return the new class instance.

A context key is composed of:

=over 4

=item 1. the class name, or the object ID retrieved with L<Scalar::Util/refaddr> if a blessed C<object> was provided,

=item 2. the current process ID, and

=item 3. optionally the thread L<tid|threads/tid> if running under a thread.

=back

However, if a context is C<system>, then the C<key> is also automatically set to C<system>.

Possible options are:

=over 4

=item * C<key>

Specifies explicitly a key to use

Please note that this option would be discarded if the C<context> is set to C<system>

=back

=head1 METHODS

=head2 cleanup_register

    # In your Apache/mod_perl2 script
    sub handler : method
    {
        my( $class, $r ) = @_;
        my $repo = Module::Generic::Global->new( 'errors' => 'My::Module' );
        $repo->cleanup_register( $r );
        # Rest of your code
    }

This prepares a cleanup callback to empty the global variables when the Apache/mod_perl2 request is complete.

It takes an L<Apache2::RequestRec> as its sole argument.

=head2 Pod::Coverage clear

=head2 clear_error

    $repo->clear_error;
    Module::Generic::Global->clear_error;

This clear the error for the current object, and the latest recorded error stored as a global variable.

=head2 Pod::Coverage debug

=head2 error

    $repo->error( "Something went wrong: ", $some_value );
    my $exception = $repo->error;

Used as a mutator, and this sets an L<exception object|Module::Generic::Exception>, and returns C<undef> in scalar context, or an empty list in list context.

In accessor mode, this returns the currently set L<exception object|Module::Generic::Exception>, if any.

=head2 exists

Returns true (C<1>) if a value is currently stored under the context, o false (C<0>) otherwise. This only checks that an entry exists, not whether that entry has a true value.

=head2 get

Retrieves the stored value, deserialising it using L<Storable::Improved> if it was serialised, and return it.

If an error occurs, it returns C<undef> in scalar context, or an empty list in list context.

=head2 length

    my $repo = Module::Generic::Global->new( 'my_repo' => 'My::Module' );
    say $repo->length;

Returns the number of elements in the namespace.

=head2 lock

    {
        $repo->lock;
        # Do some computing
        # Lock is freed automatically when it gets out of scope
    }

Sets a lock to ensure the manipulation done is thread-safe. If the code runs in a single thread environment, then this does not do anything.

When the lock gets out of scope, it is automatically removed.

=head2 remove

Removes the stored value for the current context.

This can also be called as C<clear>

=head2 set

    $repo->set( { foo => 42 } );

Stores a scalar or serialisable reference in the current namespace and context. This overwrite any previous value for the same context.

The value provided is serialised using L<Storable::Improved> before it is stored in the global repository.

Returns true upon success, and upon error, return C<undef> in scalar context, or an empty list in list context.

=head2 unlock

    $repo->unlock;

This is used to remove the lock set when under Apache2 ModPerl by using L<APR::ThreadRWLock/unlock>

It is usually not necessary to call this explicitly, because when the lock set previously gets out of scope, it is automatically removed.

=for Pod::Coverage USE_MUTEX

=head1 CONSTANTS

The constants that can be imported into your namespace are:

=head2 CAN_THREADS

This returns true (C<1>) or false (C<0>) depending on whether Perl was compiled with C<ithreads> (Interpreter Threads) or not.

=head2 HAS_THREADS

This returns true (C<1>) or false (C<0>) depending on whether Perl was compiled with C<ithreads> (Interpreter Threads) or not, and whether L<threads> has been loaded.

This is not actually a constant. Its value will change if L<threads> has been loaded or not. For example:

    use Module::Generic::Global ':const';

    say HAS_THREADS ? 'yes' : 'no'; # no
    require threads;
    say HAS_THREADS ? 'yes' : 'no'; # yes

=head2 IN_THREAD

This returns true (C<1>) or false (C<0>) depending on whether Perl was compiled with C<ithreads> (Interpreter Threads) or not, and whether L<threads> has been loaded, and we are inside a thread (L<tid|threads/tid> returns a non-zero value). For example:

    use Module::Generic::Global ':const';

    say IN_THREAD ? 'yes' : 'no'; # no
    require threads;
    say IN_THREAD ? 'yes' : 'no'; # no
    my $thr = threads->create(sub
    {
        say IN_THREAD ? 'yes' : 'no'; # yes
    });
    $thr->join;

Note that this only works for Perl threads

=head2 MOD_PERL

This returns the L<ModPerl|https://perl.apache.org/docs/2.0/index.html> version if running under L<ModPerl|https://perl.apache.org/docs/2.0/index.html>, or C<undef> otherwise.

=head2 MPM

This returns the Apache MPM (Multi-Processing Modules) used if running under ModPerl. Possible values are L<prefork|https://httpd.apache.org/docs/current/en/mod/prefork.html>, L<worker|https://httpd.apache.org/docs/current/mod/worker.html>, L<event|https://httpd.apache.org/docs/current/mod/event.html>, L<winnt|https://httpd.apache.org/docs/current/en/mod/mpm_winnt.html> or C<undef> if not running under ModPerl.

This uses L<Apache2::MPM/show> to make that determination.

=head2 HAS_MPM_THREADS

This returns true (C<1>) or false (C<0>) depending on whether the code is running under ModPerl, and the Apache MPM (Multi-Processing Modules) used is threaded (e.g. C<worker>, or C<event>). This uses L<Apache2::MPM/is_threaded> to make that determination.

See L<Apache2::MPM>

=head1 THREAD & PROCESS SAFETY

This module is designed to be fully thread-safe and process-safe, ensuring data integrity across Perl ithreads and mod_perl’s threaded Multi-Processing Modules (MPMs) such as Worker or Event. It uses robust synchronisation mechanisms to prevent data corruption and race conditions in concurrent environments.

=head2 Synchronisation Mechanisms

L<Module::Generic::Global> employs the following synchronisation strategies:

=over 4

=item * B<Perl ithreads>

When Perl is compiled with ithreads support (C<CAN_THREADS> is true) and the L<threads> module is loaded (C<HAS_THREADS> is true), global repositories (C<$REPO>, C<$ERRORS>, C<$LOCKS>) are marked C<:shared> using L<threads::shared>. Access to these repositories is protected by L<perlfunc/lock> to ensure thread-safe read and write operations.

=item * B<mod_perl Threaded MPMs>

In mod_perl environments with threaded MPMs (e.g., Worker or Event, where C<HAS_MPM_THREADS> is true), the module uses L<APR::ThreadRWLock> for locking if Perl lacks ithreads support or L<threads> is not loaded, which is very unlikely, since mod_perl would normally would not work under threaded MPM if perl was not compiled with threads. This ensures thread-safety within Apache threads sharing the same process.

=item * B<Non-Threaded Environments>

In single-threaded environments (e.g., mod_perl Prefork MPM or non-threaded Perl), locking is skipped, as no concurrent access occurs within a process. Data is isolated per-process via the process ID (C<$$>) in context keys.

=back

=head2 Shared Data Initialisation

To prevent race conditions during dynamic conversion of global variables to shared ones, the module adopts a conservative approach. At startup, if C<CAN_THREADS> is true (Perl supports ithreads), the global repositories are initialised as C<:shared>:

=over 4

=item * C<$REPO>: Stores data for all namespaces and context keys.

=item * C<$ERRORS>: Stores error objects for error handling.

=item * C<$LOCKS>: Manages lock state for thread-safe operations.

=back

This upfront initialisation ensures thread-safety without the risk of mid-air clashes that could occur if private globals were converted dynamically when threads are loaded.

=head2 Context Key Isolation

Data is stored in repositories using context keys that ensure isolation:

=over 4

=item * B<Class-Level Keys>

For class-level repositories (e.g., C<< $class->new( 'ns' => 'My::Module' ) >>), keys are formatted as C<< <class>;<pid> >> (e.g., C<My::Module;1234>). This isolates data per class and process, preventing cross-process interference.

=item * B<Object-Level Keys>

For object-level repositories (e.g., C<< $class->new( 'ns' => $obj ) >>), keys are:

=over 4

=item - B<Non-Threaded>: C<< <refaddr>;<pid> >> (e.g., C<1234567;1234>), where C<refaddr> is the object’s reference address from L<Scalar::Util/refaddr>.

=item - B<Threaded>: C<< <refaddr>;<pid>;<tid> >> (e.g., C<1234567;1234;1>), where C<tid> is the thread ID from L<threads/tid>.

=back

The inclusion of C<tid> when C<HAS_THREADS> is true ensures thread-level isolation for object-level data. Repositories created in non-threaded environments cannot be overwritten by threaded ones, and vice versa, due to differing key formats.

=back

=head2 Error Handling

Errors are stored in both instance-level (C<< $self->{_error} >>) and class-level (C<$ERRORS> repository under the C<errors> namespace) storage, supporting patterns like C<< My::Module->new || die( My::Module->error ) >>. Each class-process-thread combination (keyed by C<< <class>;<pid>[;<tid>] >>) stores at most one error, with subsequent errors overwriting the previous entry to prevent memory growth. Errors are serialised using L<Storable::Improved> for compatibility with C<threads::shared>.

=head2 mod_perl Considerations

In mod_perl environments:

=over 4

=item * B<Prefork MPM>

Data is per-process, requiring no additional synchronisation, as each process operates independently.

=item * B<Threaded MPMs (Worker/Event)>

Threads within a process share the same Perl interpreter clone, necessitating thread-safety. Since mod_perl requires threaded Perl (C<$Config{useithreads}> true), L<threads::shared> and L<perlfunc/lock> are used unless L<threads> is not loaded, in which case L<APR::ThreadRWLock> is employed. Users should call L</cleanup_register> in handlers to clear shared repositories after each request, preventing memory leaks.

=item * B<Thread-Unsafe Functions>

Certain Perl functions (e.g., C<localtime>, C<readdir>, C<srand>) and operations (e.g., C<chdir>, C<umask>, C<chroot>) are unsafe in threaded MPMs, as they may affect all threads in a process. Users must avoid these and consult L<perlthrtut|http://perldoc.perl.org/perlthrtut.html> and L<mod_perl documentation|https://perl.apache.org/docs/2.0/user/coding/coding.html#Thread_environment_Issues> for guidance.

=back

=head2 Thread-Safety Considerations

The module’s thread-safety relies on:

=over 4

=item * B<Shared Repositories>: Initialised as C<:shared> when C<CAN_THREADS> is true, ensuring safe access across threads.

=item * B<Locking>: L<perlfunc/lock> or L<APR::ThreadRWLock> protects all read/write operations.

=item * B<Key Isolation>: Thread-specific keys (C<< <refaddr>;<pid>;<tid> >>) isolate object-level data when created in different threads.

=back

In environments where C<%INC> manipulation (e.g., by L<forks>) emulates L<threads>, C<HAS_THREADS> and C<IN_THREAD> may return true. This is generally safe, as L<forks> provides a compatible C<tid> method, but users in untrusted environments should verify C<$INC{'threads.pm'}> points to the actual L<threads> module.

For maximum safety, users running mod_perl with threaded MPMs should ensure Perl is compiled with ithreads and explicitly load L<threads>, or use Prefork MPM for single-threaded operation.

=head2 Environment Variables

The following environment variables influence thread-safety:

=over 4

=item * C<MG_MAX_RETRIES>: Sets the number of lock retry attempts (default: 10).

=item * C<MG_RETRY_DELAY>: Sets the base retry delay for data operations (microseconds, default: 10,000).

=item * C<MG_ERROR_DELAY>: Sets the base retry delay for error operations (microseconds, default: 5,000).

=back

=head1 SEE ALSO

L<Module::Generic>, L<Storable::Improved>, L<Module::Generic::Exception>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2025 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut

