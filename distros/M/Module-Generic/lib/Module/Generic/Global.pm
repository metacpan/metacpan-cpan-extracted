##----------------------------------------------------------------------------
## Module Generic - ~/lib/Module/Generic/Global.pm
## Version v1.1.1
## Copyright(c) 2026 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2025/05/06
## Modified 2026/03/14
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
        $MOD_PERL $REPO $MUTEX $ERRORS $LOCKS $STATS $ORDER $SIZES $CLEANUP $NS_LOCKS
        $LOCK_MUTEX $REFCOUNTS $DEBUG $PerlConfig $DEFAULT_SERIALISER $MAX_STORE_BYTES
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

    sub MOD_PERL () { CORE::return( $MOD_PERL ); }

    my $mpm;
    my $mpm_threaded    = 0;
    my $use_mutex       = 0;
    my $need_shared     = CAN_THREADS();
    our( $MUTEX, $LOCK_MUTEX );
    # The user data repository
    our $REPO           = {};
    # Special repository for error objects
    our $ERRORS         = {};
    # Used for repositories locking mechanism
    our $LOCKS          = {};
    # Light data used to collect statistic for reporting with stat()
    our $STATS          = {};
    # To keep track of the keys, and order them by age
    our $ORDER          = {};
    # To put a cap on data size in bytes
    our $SIZES          = {};
    # For cleanup_register
    our $CLEANUP        = {};
    # To perform locking on namespaces
    our $NS_LOCKS       = {};
    # To keep track of repositories that use a shared key. When it hits 0, it gets removed
    our $REFCOUNTS      = {};
    our $MAX_STORE_BYTES= 5242880;
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
        my %stats :shared;
        my %order :shared;
        my %sizes :shared;
        my %cleanup :shared;
        my %ns_locks :shared;
        my %refcounts :shared;
        $REPO     = \%repo;
        $ERRORS   = \%errs;
        $LOCKS    = \%locks;
        $STATS    = \%stats;
        # To keep track of the keys
        $ORDER    = \%order;
        $SIZES    = \%sizes;
        $CLEANUP  = \%cleanup;
        $NS_LOCKS = \%ns_locks;
        $REFCOUNTS = \%refcounts;
    }

    sub _NEED_SHARED () { CORE::return( $need_shared ); }
    sub USE_MUTEX () { CORE::return( $use_mutex ); }
    sub MPM () { CORE::return( $mpm ); }
    sub HAS_MPM_THREADS () { CORE::return( $mpm_threaded ); }

    our @EXPORT_OK = qw( CAN_THREADS HAS_THREADS IN_THREAD MOD_PERL MPM HAS_MPM_THREADS );
    our %EXPORT_TAGS = ( 'const' => [@EXPORT_OK] );
    our $DEFAULT_SERIALISER = 'Storable::Improved';
    our $VERSION = 'v1.1.1';
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
        return( $this->error( "No controller element was provided for this namespace $ns" ) ) if( !CORE::length( $what // '' ) );
    }
    my $opts = $this->_get_args_as_hash( @_ );

    my $ref = 
    {
        _namespace      => $ns,
        _key            => undef,
        _mode           => undef,
        _error          => undef,
        debug           => ( $opts->{debug} // $DEBUG // 0 ),
        serialiser      => ( $DEFAULT_SERIALISER || 'Storable::Improved' ),
        # Default value
        max_store_bytes => ( $MAX_STORE_BYTES // 0 ),
    };
    if( CORE::exists( $opts->{on_get} ) &&
        CORE::defined( $opts->{on_get} ) )
    {
        my( $cb, $args ) = $this->_get_args_for_callback( $opts->{on_get} );
        return if( !$cb && $this->error );
        $ref->{on_get}      = $cb if( defined( $cb ) );
        $ref->{on_get_args} = $args if( defined( $args ) );
    }

    if( CORE::exists( $opts->{serialiser} ) &&
        CORE::defined( $opts->{serialiser} ) )
    {
        $ref->{serialiser} = $opts->{serialiser};
    }
    elsif( CORE::exists( $opts->{serializer} ) &&
        CORE::defined( $opts->{serializer} ) )
    {
        $ref->{serialiser} = $opts->{serializer};
    }

    if( CORE::exists( $opts->{max_size} ) &&
        $opts->{max_size} =~ /^\d+$/ )
    {
        $ref->{max_size} = $opts->{max_size};
    }

    if( CORE::exists( $opts->{max_store_bytes} ) &&
        $opts->{max_store_bytes} =~ /^\d+$/ )
    {
        $ref->{max_store_bytes} = $opts->{max_store_bytes};
    }

    if( CORE::exists( $opts->{max_total_bytes} ) &&
        $opts->{max_total_bytes} =~ /^\d+$/ )
    {
        $ref->{max_total_bytes} = $opts->{max_total_bytes};
    }

    # Are we expected to keep a counter of callers using a given namespace, so that upon reaching 0, it gets automatically removed?
    if( CORE::exists( $opts->{refcount} ) )
    {
        if( ( defined( $opts->{refcount} ) &&
              CORE::length( $opts->{refcount} ) &&
              $opts->{refcount} =~ /^0|1$/
            )
            ||
            !defined( $opts->{refcount} )
            ||
            !CORE::length( $opts->{refcount} // '' ) )
        {
            $ref->{refcount} = $opts->{refcount};
        }
        else
        {
            require overload;
            return( $this->error( "Unsupported value for 'refcount' (", overload::StrVal( $opts->{refcount} // 'undef' ), "). It must be either 1, 0, undef or an empty string." ) );
        }
    }

    if( defined( $ref->{max_store_bytes} ) &&
        $ref->{max_store_bytes} =~ /^\d+$/ &&
        $ref->{max_store_bytes} > 0 &&
        defined( $ref->{max_total_bytes} ) &&
        $ref->{max_total_bytes} =~ /^\d+$/ &&
        $ref->{max_total_bytes} > 0 &&
        $ref->{max_store_bytes} > $ref->{max_total_bytes} )
    {
        warn( "You have set the maximum byte size of an element ($ref->{max_store_bytes}) to be greater than the total byte size alllwed for all elements ($ref->{max_total_bytes}" ) if( warnings::enabled() );
    }

    # The 'key', if any, must NOT be any reference. It must be a plain scalar.
    if( CORE::exists( $opts->{key} ) &&
        defined( $opts->{key} ) &&
        CORE::length( $opts->{key} ) &&
        ref( $opts->{key} ) )
    {
        require overload;
        if( Scalar::Util::blessed( $opts->{key} ) &&
            overload::Method( $opts->{key} => '""' ) )
        {
            $opts->{key} = "$opts->{key}";
        }
        else
        {
            return( $this->error( "The key you provided '$opts->{key}' (", overload::StrVal( $opts->{key} ), ") is a reference. You must pass a key as a plain scalar imstead." ) );
        }
    }

    my $self = bless( $ref => ( ref( $this ) || $this ) );

    # Special case if the context is 'system', and neither a class name, nor an object
    if( do{ no warnings; "$what" eq 'system' } )
    {
        $self->{_key}  = 'system';
        $self->{_mode} = 'system';
        # Enabled reference counts, so this repository gets removed when its count hits 0
        $self->{refcount} = 1;
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
        # Enabled reference counts, so this repository gets removed when its count hits 0
        $self->{refcount} = 1;
    }
    else
    {
        return( $self->error( "Module::Generic::Global->new requires either a class name or an object to be provided." ) );
    }

    # We are being required to keep track of reference counts, either explicitly by the caller, or implicitly by ourself based on the arguments we received.
    if( $self->{refcount} )
    {
        my $ns    = $self->{_namespace};
        my $key   = $self->{_key} // '';
        if( !CORE::exists( $REFCOUNTS->{ $ns } ) )
        {
            # $self->__message( 4, "The repository for namespace '$ns' does not exist yet, creating it now." );
            # $self->__message( 4, "_NEED_SHARED has value '", ( _NEED_SHARED // 'undef' ), "'" );
            if( _NEED_SHARED )
            {
                # $self->__message( 4, "Initialising shared repository for namespace '$ns'." );
                my %refcount :shared;
                $REFCOUNTS->{ $ns } = \%refcount;
            }
            else
            {
                # $self->__message( 4, "Initialising non-shared repository for namespace '$ns'." );
                $REFCOUNTS->{ $ns } = {};
            }
        }
        my $refns = $REFCOUNTS->{ $ns };
        if( !CORE::exists( $refns->{ $key } ) && _NEED_SHARED )
        {
            $self->_lock_write( $refns ) || return( $self->error( "Unable to lock namespace for new shared refcounts slot." ) );
            my $shared_refcount :shared = 0;
            $refns->{ $key } = $shared_refcount;
            $self->_unlock;
            $self->__message( 5, "Pre-shared new refcount slot for key '$key' in namespace '$ns'." );
        }

        my $refcount = \$refns->{ $key };
        $$refcount //= 0;
        $self->_lock_write( $refcount ) || return( $self->error( "Unable to lock the repository to write to it." ) );
        $$refcount++;
        $self->_unlock;
    }

    if( $opts->{auto_cleanup} )
    {
        my %cleanup_opts = ref( $opts->{auto_cleanup} ) eq 'HASH'
            ? %{$opts->{auto_cleanup}}
            : ();
        $self->cleanup_register( %cleanup_opts );
    }
    return( $self );
}

{
    no warnings 'once';
    *clear = \&remove;
}

sub cleanup
{
    my $self = shift( @_ );
    $self->_decrement;
    return( $self );
}

# Only for Apache/mod_perl
sub cleanup_register
{
    my $self = shift( @_ );
    my $opts = {};
    my $r;
    # Legacy
    if( @_ == 1 &&
        defined( $_[0] ) &&
        Scalar::Util::blessed( $_[0] ) &&
        $_[0]->isa( 'Apache2::RequestRec' ) )
    {
        $r = shift( @_ );
    }
    else
    {
        $opts = $self->_get_args_as_hash( @_ );
        $r = $opts->{r}; # Allow explicit
    }

    if( !ref( $self ) )
    {
        warn( "${self}::cleanup_register() cannot be called as a class function anymore. Use an instance instead." ) if( warnings::enabled() );
        return;
    }

    my $callback    = $opts->{callback} if( ref( $opts->{callback} ) eq 'CODE' );
    my $namespaces  = $opts->{namespaces} // [$self->{_namespace}]; # Default to self ns
    my %keep = map{ $_ => 1 } @{ $opts->{keep} || [] };
    if( !$r && $MOD_PERL )
    {
        local $@;
        $r = eval{ Apache2::RequestUtil->request };
        if( $@ || !$r || !Scalar::Util::blessed($r) || !$r->isa('Apache2::RequestRec') )
        {
            $self->__message( 3, "No valid Apache request for cleanup: $@" );
            return(1); # Skip
        }
    }
    return(1) unless( $r ); # Non-mod_perl: Rely on END

    my $r_id = Scalar::Util::refaddr( $r );
    $self->_lock_write( \$CLEANUP->{ $r_id } ) || return( $self->error( 'Lock fail for cleanup track.' ) );
    $CLEANUP->{ $r_id } //= { ns => {}, keep => {} };
    $CLEANUP->{ $r_id }->{ns}{ $_ } = 1 for( @$namespaces );
    %{$CLEANUP->{ $r_id }->{keep}} = %keep;
    $self->_unlock;

    my $weaken_self = $self;
    Scalar::Util::weaken( $weaken_self );
    local $@;
    eval
    {
        $r->pool->cleanup_register(sub
        {
            my $args = shift( @_ );
            my( $me, $this_r, $cb ) = @$args;
            return if( !$me );

            my $this_r_id = Scalar::Util::refaddr( $this_r );
            $me->_lock_read( $CLEANUP ) || return;
            my $data = $CLEANUP->{ $this_r_id };
            $me->_unlock;
            if( $data )
            {
                my @to_clear = grep{ !$data->{keep}->{ $_ } } keys( %{$data->{ns}} );
                if( @to_clear )
                {
                    $this_r->log->notice( "Clearing namespaces: ", join( ', ', @to_clear) ) if( $DEBUG );
                    foreach my $ns ( @to_clear )
                    {
                        delete( $REPO->{ $ns } );
                        delete( $ORDER->{ $ns } );
                        delete( $SIZES->{ $ns } );
                        delete( $NS_LOCKS->{ $ns } );

                        foreach my $k ( keys( %$STATS ) )
                        {
                            next if( index( $k, $ns . ';' ) != 0 );
                            delete( $STATS->{ $k } );
                        }
                    }
                }
                $me->_lock_write( $CLEANUP ) || return;
                delete( $CLEANUP->{ $this_r_id } );
                $me->_unlock;
            }
            $cb->( $me, $this_r ) if( $cb );
        }, [ $weaken_self, $r, $callback ] );
    };
    $self->__message( 3, "Cleanup register error: $@" ) if( $@ );
    return(1);
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
        # $self->__message( 4, "Is \$ERRORS shared ? ", ( HAS_THREADS && threads::shared::is_shared( $ERRORS ) ? 'yes' : 'no' ) );
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
    return(0) if( !CORE::exists( $REPO->{ $ns } ) );
    return( CORE::exists( $REPO->{ $ns }->{ $key } ) ? 1 : 0 );
}

sub get
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    my $ns   = $self->{_namespace} || die( "No namespace is set." );
    my $key  = $self->{_key} || die( "No key is set." );
    my( $cb, $args );
    if( CORE::exists( $opts->{on_get} ) &&
        CORE::defined( $opts->{on_get} ) )
    {
        ( $cb, $args ) = $self->_get_args_for_callback( $opts->{on_get} );
        return if( !$cb && $self->error );
    }
    else
    {
        $cb   = $self->{on_get} if( CORE::exists( $self->{on_get} ) );
        $args = $self->{on_get_args} if( CORE::exists( $self->{on_get_args} ) );
    }
    $self->__message( 7, "Called for namespace '$ns' and key '$key' from class ", [caller]->[0], " at line ", [caller]->[2], " in sub ", [caller(1)]->[3] );
    # Make sure the repository is shared if needed
    $self->_share_repo( $ns );
 
     # We avoid autovivification
    if( !CORE::exists( $REPO->{ $ns }->{ $key } ) )
    {
        $self->__message( 7, "No data to deserialise yet." );
        return;
    }

    # $self->__message( 4, "\$REPO->{ $ns } is ", overload::StrVal( $REPO->{ $ns } ) );
    # $self->__message( 4, "HAS_THREADS is '", ( HAS_THREADS // 'undef' ), "'" );
    # $self->__message( 4, "Is \$REPO->{ $ns } shared already ? ", ( HAS_THREADS && threads::shared::is_shared( $REPO->{ $ns } ) ? 'yes' : 'no' ) );
    my $ref  = \$REPO->{ $ns }->{ $key };
    $$ref //= undef;
    $self->_lock_read( $ref ) || return( $self->error( "Unable to lock the repository to read from it." ) );
    my $store = $$ref;
    $self->_unlock;
    if( CORE::length( $store // '' ) )
    {
        $self->__message( 7, "Deserialising stored data '$store'" );
        my $value = $self->_deserialise( $store );
        if( !defined( $value ) && $self->error )
        {
            return;
        }

        if( defined( $value ) && Scalar::Util::blessed( $value ) && $value->isa( 'Module::Generic::Global::Scalar' ) )
        {
            $value = $value->as_string;
        }
        if( defined( $cb ) )
        {
            local $@;
            my $rv = eval
            {
                local $_ = $self;
                $cb->( $value, ( defined( $args ) ? @$args : () ) );
            };
            if( $@ )
            {
                return( $self->error( "Error with callback after deserialising object: $@" ) );
            }
            return( $rv );
        }
        return( $value );
    }
    else
    {
        $self->__message( 7, "No data to deserialise yet." );
        return( $store );
    }
}

sub key { return( shift->{_key} ); }

sub length
{
    my( $self ) = @_;
    my $ns  = $self->{_namespace} || die( "No namespace is set." );

    $self->_share_repo( $ns );

    if( !CORE::exists( $REPO->{ $ns } ) )
    {
        $self->__message( 7, "The following keys were found for namespace '$ns': ''" );
        $self->__message( 7, "ORDER repo contains: ''" );
        return(0);
    }

    my @keys = CORE::keys( %{ $REPO->{ $ns } } );
    $self->__message( 5, "Found ", scalar( @keys ), " keys: '", join( ', ', @keys ), "'" );

    # Optional: if your "deleted" state is empty string, you probably want to exclude them
    # to avoid resurrected empty slots being counted.
    # This requires reading each value carefully without autoviv: we already have keys, so it's safe.
    my @alive;
    for my $k ( @keys )
    {
        next if( !CORE::exists( $REPO->{ $ns }->{ $k } ) );

        my $ref = \$REPO->{ $ns }->{ $k };
        $$ref //= '';
        $self->_lock_read( $ref ) || next;
        my $v = $$ref;
        $self->_unlock;

        # next if( !defined( $v ) || $v eq '' );
        push( @alive, $k );
    }

    $self->__message( 7, "The following keys were found for namespace '$ns': '", join( ', ', sort( @alive ) ), "'" );

    if( CORE::exists( $ORDER->{ $ns } ) )
    {
        my $order_ref = $ORDER->{ $ns };
        $self->_lock_read( $order_ref ) || return( $self->error( "Unable to lock order to read it." ) );
        my @order = @{$ORDER->{ $ns }};
        $self->_unlock;
        $self->__message( 7, "ORDER repo contains: '", join( ', ', @order ), "'" );
    }
    else
    {
        $self->__message( 7, "ORDER repo contains: ''" );
    }

    return( scalar( @alive ) );
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
            $self->__message( 3, "Error locking \$lock_ref (", overload::StrVal( $lock_ref // 'undef' ), "): $@" );
            return( $self->error({
                message => "Failed to acquire shared lock for key $key: $@",
                class => 'Module::Generic::Global::Exception',
                code => 503
            }) );
        }
        $self->__message( 4, "Acquired shared lock for key $key" );
        # We return the value returned by CORE::lock, which, when it goes out of scopre in the caller's block, the lock also will be automatically removed.
        return( $rv );
    }
    elsif( $MUTEX )
    {
        my $rv = $self->_lock_mutex( $LOCK_MUTEX, delay => RETRY_DELAY, rw => 1 );
        if( !$rv )
        {
            $self->__message( 3, "Failed to acquire shared lock for key $key after ", MAX_RETRIES, " retries" );
            return( $self->error( {
                message => "Failed to acquire shared lock for key $key after ", MAX_RETRIES, " retries",
                class => 'Module::Generic::Global::Exception',
                code => 503
            } ) );
        }
        $self->__message( 4, "Acquired shared lock for key $key with mutex" );
        # Return a special private object that will unlock the mutex when it gets out of scope, just like CORE::lock() does, so the user does not have to worry about calling unlock()
        return( Module::Generic::Global::Guard->new( $LOCK_MUTEX ) );
    }
    return(1);
}

sub max_store_bytes
{
    my $self = shift( @_ );
    $self->{max_store_bytes} = shift( @_ ) if( @_ );
    return( $self->{max_store_bytes} );
}

sub namespace { return( shift->{_namespace} ); }

sub remove
{
    my $self = shift( @_ );
    my $ns   = $self->{_namespace} || die( "No namespace is set." );
    my $key  = $self->{_key} || die( "No key is set." );
    # Make sure the repository is shared if needed
    $self->_share_repo( $ns );
    if( !CORE::exists( $REPO->{ $ns }->{ $key } ) )
    {
        # $self->__message( 4, "The repository \$REPO->{ $ns }->{ $key } does not exist, so there is nothing to remove." );
        return(1);
    }
    my $ref  = \$REPO->{ $ns }->{ $key };
    $$ref //= '';
    $self->_lock_write( $ref ) || return( $self->error( "Unable to lock the repository to write to it." ) );
    my $removed_len = CORE::length( $$ref // '' );
    CORE::delete( $REPO->{ $ns }->{ $key } );
    $self->_unlock;

    # The last one out of the door, please shut the light: we remove the namespace if re are using refcounts.
    # It can be called in void.
    $self->_decrement;

    # Housekeeping
    if( $removed_len > 0 )
    {
        $self->_lock_write( $SIZES->{ $ns } ) || return( $self->error( "Unable to update sizes on remove." ) );
        ${$SIZES->{ $ns }} -= $removed_len;
        $self->_unlock;
    }

    # We remove from order array to keep it clean
    my $order_ref = $ORDER->{ $ns };
    $self->_lock_write( $order_ref ) || return( $self->error( "Unable to lock order array for removal." ) );
    @{$ORDER->{ $ns }} = grep{ CORE::length( $_ // '' ) && $_ ne $key } @{$ORDER->{ $ns }};
    $self->_unlock;

    # Collect some statistics
    my $stat_key = join( ';', $ns, $key );
    if( CORE::exists( $STATS->{ $stat_key } ) )
    {
        $self->_lock_write( $STATS ) || return( $self->error( "Unable to lock stats for share check." ) );
        CORE::delete( $STATS->{ $stat_key } );
        $self->_unlock;
    }
    return(1);
}

sub set
{
    my( $self, $value ) = @_;
    my $ns  = $self->{_namespace} || die( "No namespace is set." );
    my $key = $self->{_key} || die( "No key is set." );
    $self->__message( 7, "Called for namespace '$ns' and key '$key' from class ", [caller]->[0], " at line ", [caller]->[2], " in sub ", [caller(1)]->[3] );
    $self->__message( 7, "Requested to store value '", overload::StrVal( $value // 'undef' ), "'" );
    my $raw_len;
    if( !ref( $value ) )
    {
        $raw_len = CORE::length( $value // '' );
        $value = Module::Generic::Global::Scalar->new( \$value );
    }
    local $@;
    my $store = $self->_serialise( $value );
    if( !defined( $store ) && $self->error )
    {
        return;
    }

    # Source of truth for accounting: actual stored bytes
    my $len    = CORE::length( $store // '' );
    $raw_len //= $len;
    # Check for the total bytes stores in this namespace, and if we exceed or not our threshold
    my $max = $self->max_store_bytes;
    # Warn about some nonsense whereby the maximum bytes size of an element is higher than the total byte size of all elements.
    if( defined( $max ) &&
        $max =~ /^\d+$/ &&
        $max > 0 &&
        defined( $self->{max_total_bytes} ) &&
        $self->{max_total_bytes} =~ /^\d+$/ &&
        $self->{max_total_bytes} > 0 &&
        $max > $self->{max_total_bytes} )
    {
        warn( "You have set the maximum byte size of an element ($max) to be greater than the total byte size alllwed for all elements ($self->{max_total_bytes}" ) if( warnings::enabled() );
    }

    $self->__message( 4, "Checking if byte length of value provided ($raw_len) is bigger than maximum allowed ($max)" );
    if( defined( $max ) &&
        $max =~ /^\d+$/ &&
        $max > 0 &&
        $raw_len > $max )
    {
        $self->__message( 4, "The value to be stored is $raw_len bytes, which exceeds the maximum allowed of $max bytes. Returning an error now." );
        return( $self->error( "Refusing to store ${raw_len} bytes in Module::Generic::Global (limit ${max})." ) );
    }

    # Make sure the repository is shared if needed (moved up for early init)
    $self->_share_repo( $ns );

    # Pre-create shared slot if new key and in shared mode (fixes invalid shared scalar on autoviv)
    my $is_new_key = CORE::exists( $REPO->{ $ns }->{ $key } ) ? 0 : 1;

    if( !CORE::exists( $REPO->{ $ns }->{ $key } ) && _NEED_SHARED )
    {
        # Lock per-ns shared scalar
        $self->_lock_write( $NS_LOCKS->{ $ns } ) || return( $self->error( "Unable to lock namespace for new shared slot." ) );
        my $shared_slot :shared = '';
        $REPO->{ $ns }->{ $key } = $shared_slot;
        $self->_unlock;
        $self->__message( 5, "Pre-shared new slot for key '$key' in namespace '$ns'." );
    }

    $self->__message( 7, "Value to store is ", $len, " bytes long (", overload::StrVal( $store ), ")." );
    my $old_len = 0;
    if( CORE::exists( $REPO->{ $ns }->{ $key } ) )
    {
        my $ref = \$REPO->{ $ns }->{ $key };
        $$ref //= '';
        $self->_lock_read( $ref ) || return( $self->error( "Unable to read old len." ) );
        $old_len = CORE::length( $$ref // '' );
        $self->_unlock;
    }

    my $delta = $len - $old_len;
    if( $self->{max_total_bytes} && $self->{max_total_bytes} > 0 )
    {
        $self->_lock_read( $SIZES->{ $ns } ) || return( $self->error( "Unable to lock sizes." ) );
        my $current_total = ${$SIZES->{ $ns }} // 0;
        $self->_unlock;
        # No need to check for previous entry to evictate, since this new one already exceeds the tal
        if( $len > $self->{max_total_bytes} )
        {
            $self->__message( 6, "The new value has a size of ${len} bytes, which exceeds the maximum total bytes allowed ($self->{max_total_bytes})." );
            return( $self->error( "Refusing to store ", ( $len ), " bytes;  The byte size of this value exceeds in itself the total byte value size of $self->{max_total_bytes} bytes for this key ${key}." ) );
        }

        # Only o this if we exceed the threshold. Very straightforward, very fast.
        # We make sure that this one new item byte size does not exceed as itself, the maximum allowed.
        if( ( $current_total + $delta ) > $self->{max_total_bytes} )
        {
            $self->__message( 4, "The new total byte size (", ( $current_total + $delta ), ") would exceed the maximum of '$self->{max_total_bytes}'. Evicting older entries." );
            my $order_ref = $ORDER->{ $ns };
            $self->_lock_write( $order_ref ) || return( $self->error( "Unable to lock order for total eviction." ) );
            while( @{$ORDER->{ $ns }} && $current_total + $delta > $self->{max_total_bytes} )
            {
                my $evict_key = shift( @{$ORDER->{ $ns }} );
                # Do not evict self if overwrite
                if( CORE::exists( $REPO->{ $ns }->{ $evict_key } ) && $evict_key ne $key )
                {
                    my $evict_ref = \$REPO->{ $ns }->{ $evict_key };
                    $$evict_ref //= '';
                    $self->_lock_write( $evict_ref ) || last;
                    my $evict_len = CORE::length( $$evict_ref // '' );
                    CORE::delete( $REPO->{ $ns }->{ $evict_key } );
                    $self->_unlock;
                    # Update sizes (lock separately to avoid deep nest)
                    $self->_lock_write( $SIZES->{ $ns } ) || last;
                    ${$SIZES->{ $ns }} -= $evict_len;
                    $self->_unlock;
                    # Clear stat too
                    my $evict_stat_key = join( ';', $ns, $evict_key );
                    if( CORE::exists( $STATS->{ $evict_stat_key } ) )
                    {
                        my $evict_stat_ref = \$STATS->{ $evict_stat_key };
                        $$evict_stat_ref //= 0;
                        $self->_lock_write( $evict_stat_ref ) || last;
                        CORE::delete( $STATS->{ $evict_stat_key } );
                        $self->_unlock;
                    }
                    $current_total -= $evict_len;
                    $self->__message( 4, "Evicted '$evict_key' ($evict_len bytes) from '$ns' for max_total_bytes ($self->{max_total_bytes})." );
                }
            }
            $self->_unlock; # Unlock order
            if( $current_total + $delta > $self->{max_total_bytes} )
            {
                return( $self->error( "Refusing to store ", ( $len ), " bytes; the new total (", ( $current_total + $delta ), ") would exceed max_total_bytes ($self->{max_total_bytes}) even after eviction." ) );
            }
        }
    }

    if( $self->{max_size} &&
        $self->{max_size} =~ /^\d+$/ &&
        $self->{max_size} > 0 &&
        $is_new_key &&
        scalar( grep{ $_ ne $key } keys( %{$REPO->{ $ns }} ) ) >= $self->{max_size} )
    {
        $self->__message( 4, "The size of repository for namespace '$ns' is '", scalar( keys( %{$REPO->{ $ns }} ) ), "', which exceeds the maximum size allowed ($self->{max_size})." );
        my $order_ref = $ORDER->{ $ns };
        $self->_lock_write( $order_ref ) || return( $self->error( "Unable to lock order array for eviction." ) );
        while( @{$ORDER->{ $ns }} )
        {
            my $old_key = shift( @{$ORDER->{ $ns }} );
            $self->__message( 4, "Checking keys to evit: processing key '$old_key' with namespace size of '", scalar( keys( %{$REPO->{ $ns }} ) ), "'" );
            if( CORE::exists( $REPO->{ $ns }->{ $old_key } ) )
            {
                my $old_ref = \$REPO->{ $ns }->{ $old_key };
                $$old_ref //= '';
                $self->_lock_write( $old_ref ) || last;
                my $old_bytes = CORE::length( $$old_ref // '' );
                CORE::delete( $REPO->{ $ns }->{ $old_key } );
                $self->_unlock;

                $self->_lock_write( $SIZES->{ $ns } ) || last;
                ${$SIZES->{ $ns }} -= $old_bytes;
                $self->_unlock;

                my $old_stat_key = join( ';', $ns, $old_key );
                if( CORE::exists( $STATS->{ $old_stat_key } ) )
                {
                    my $old_stat_ref = \$STATS->{ $old_stat_key };
                    $$old_stat_ref //= 0;
                    $self->_lock_write( $old_stat_ref ) || last;
                    CORE::delete( $STATS->{ $old_stat_key } );
                    $self->_unlock;
                }

                $self->__message( 4, "The total number of items in namespace '$ns' is now ", scalar( keys( %{$REPO->{ $ns }} ) ), ". Evicted oldest key '$old_key' from namespace '$ns' to enforce max_size of '$self->{max_size}'." );
                last;
            }
        }
        $self->_unlock;
    }

    # $self->__message( 4, "\$REPO->{ $ns } is ", overload::StrVal( $REPO->{ $ns } ) );
    my $ref = \$REPO->{ $ns }->{ $key };
    $$ref //= '';
    $self->_lock_write( $ref ) || return( $self->error( "Unable to lock the repository to write to it." ) );
    $$ref = $store;

    if( $delta != 0 )
    {
        $self->_lock_write( $SIZES->{ $ns } ) || return( $self->error( "Unable to update sizes." ) );
        ${$SIZES->{ $ns }} += $delta;
        $self->_unlock;
    }

    # Refresh recency: move key to the end (new OR overwrite)
    my $order_ref = $ORDER->{ $ns };
    $self->_lock_write( $order_ref ) || return( $self->error( "Unable to lock order array for insertion." ) );

    @{$ORDER->{ $ns }} = grep{ ( $_ // '' ) ne $key } @{$ORDER->{ $ns }};
    push( @{$ORDER->{ $ns }}, $key );

    $self->_unlock;

    # Collect some statistics
    my $stat_key = join( ';', $ns, $key );
    my $stat_ref = \$STATS->{ $stat_key };
    $$stat_ref //= 0;
    $self->_lock_write( $stat_ref ) || return( $self->error( "Unable to lock stats." ) );
    $$stat_ref = $len;
    $self->_unlock;
    return(1);
}

sub stat
{
    my( $self, $limit ) = @_;
    $limit ||= 20;

    my @items;
    $self->_lock_read( $STATS ) || return;
    @items = sort{ ( $STATS->{ $b } || 0 ) <=> ( $STATS->{ $a } || 0 ) } keys( %$STATS );
    $self->_unlock;
    $self->__message( 4, "STATS contains ", scalar( @items ) );

    splice( @items, $limit ) if( @items > $limit );

    my $out = [];
    foreach my $k ( @items )
    {
        push( @$out, { key => $k, bytes => ( $STATS->{ $k } || 0 ) } );
    }
    return( $out );
}

sub unlock
{
    my $self = shift( @_ );
    return(1) unless( defined( $LOCK_MUTEX ) );
    local $@;
    eval
    {
        $LOCK_MUTEX->unlock;
    };
    $self->__message( 3, "Unlock error: $@" ) if( $@ );
    return(1);
}

sub _decrement
{
    my $self = shift( @_ );
    return(1) unless( $self->{refcount} );
    my $ns  = $self->{_namespace};
    my $key = $self->{_key} // '';
    $self->_share_repo( $ns );
    return(1) if( !CORE::exists( $REFCOUNTS->{ $ns }->{ $key } ) );
    my $ref = \$REFCOUNTS->{ $ns }->{ $key };
    $$ref //= 0;
    $self->_lock_write( $ref ) || return( $self->error( "Unable to lock refcounts counter for update." ) );
    if( $$ref > 0 )
    {
        $$ref--;
    }
    # A bit paranoid given the only place where this is reduced is here, but why not?
    elsif( $$ref < 0 )
    {
        $self->__message( 6, "Refcount underflow with value '", $$ref, "' for $ns;$key" );
        $$ref = 0;
    }
    if( $$ref == 0 )
    {
        $self->remove;
        CORE::delete( $REFCOUNTS->{ $ns }->{ $key } );
    }
    $self->_unlock;
    return(1);
}

sub _deserialise
{
    my $self = shift( @_ );
    my $data = shift( @_ );
    return( '' ) if( !CORE::length( $data ) );
    my $serialiser = $self->{serialiser} || $DEFAULT_SERIALISER || 'Storable::Improved';
    # try-catch
    local $@;
    if( $serialiser eq 'CBOR' || $serialiser eq 'CBOR::XS' )
    {
        eval( "require CBOR::XS;" );
        if( $@ )
        {
            return( $self->error( "Unable to load serialiser CBOR::XS: $@" ) );
        }
    }
    else
    {
        eval( "require $serialiser;" );
        if( $@ )
        {
            return( $self->error( "Unable to load serialiser $serialiser: $@" ) );
        }
        if( $serialiser eq 'Sereal' )
        {
            eval( "require Sereal::Decoder;" );
            if( $@ )
            {
                return( $self->error( "Unable to load serialiser Sereal::Decoder: $@" ) );
            }
        }
    }

    if( ref( $serialiser ) eq 'CODE' )
    {
        my $ref = eval
        {
            return( $serialiser->( $data, 'thaw' ) );
        };
        if( $@ )
        {
            return( $self->error( "Error trying to deserialise data with user-provided callback: $@" ) );
        }
        return( $ref );
    }
    elsif( $serialiser eq 'CBOR' || $serialiser eq 'CBOR::XS' )
    {
        my $cbor = CBOR::XS->new;
        $cbor->allow_sharing(1);
        my $ref;
        eval
        {
            ( $ref, my $bytes ) = $cbor->decode_prefix( $data );
        };
        if( $@ )
        {
            return( $self->error( "Error trying to deserialise data with $serialiser: $@" ) );
        }
        return( $ref );
    }
    elsif( $serialiser eq 'CBOR::Free' )
    {
        my $ref = eval
        {
            no warnings;
            return( CBOR::Free::decode( $data ) );
        };
        if( $@ )
        {
            return( $self->error( "Error trying to deserialise data with $serialiser: $@" ) );
        }
        return( $ref );
    }
    elsif( $serialiser eq 'Sereal' )
    {
        my $dec = Sereal::Decoder->new;
        my $is_sereal = sub
        {
            my $type = Sereal::Decoder->looks_like_sereal( $_[0] );
        };
        my $decoded;
        eval
        {
            $is_sereal->( $data ) if( $self->debug );
            $dec->decode( $data => $decoded );
        };
        if( $@ )
        {
            return( $self->error( "Error trying to deserialise with $serialiser ", CORE::length( $data ), " bytes of data (", ( CORE::length( $data ) > 128 ? ( substr( $data, 0, 128 ) . '(trimmed)' ) : $data ), ": $@" ) );
        }
        return( $decoded );
    }
    elsif( $serialiser eq 'Storable::Improved' || $serialiser eq 'Storable' )
    {
        my $rv = eval
        {
            my $code = $serialiser->can( 'thaw' );
            if( !defined( $code ) )
            {
                die( "The class $serialiser does not support the method 'thaw'." );
            }
            return( $code->( $data ) );
        };
        if( $@ )
        {
            return( $self->error( "Error trying to deserialise data with $serialiser: $@" ) );
        }
        return( $rv );
    }
    else
    {
        return( $self->error( "Unsupporterd serialiser \"$serialiser\"." ) );
    }
}

sub _get_args_as_hash
{
    my $self = shift( @_ );
    my $ref  = {};
    if( scalar( @_ ) == 1 && defined( $_[0] ) && ref( $_[0] ) eq 'HASH' )
    {
        $ref = shift( @_ );
    }
    else
    {
        my %args = @_;
        $ref = \%args;
    }
    return( $ref );
}

sub _get_args_for_callback
{
    my $self = shift( @_ );
    my $this = shift( @_ ) || return;
    my( $cb, $args );
    # The user has provided the callback as an array. For example:
    # on_get => [
    #     sub{ "Hello world!" },
    #     [qw( arg1 arg2 arg3 )],
    # ];
    #
    # or:
    # on_get => [
    #     sub{ "Hello world!" },
    #     qw( arg1 arg2 arg3 ),
    # ];
    if( CORE::ref( $this ) eq 'ARRAY' )
    {
        if( scalar( @$this ) )
        {
            if( CORE::ref( $this->[0] ) ne 'CODE' )
            {
                return( $self->error( "Option on_get must be a CODE reference." ) );
            }
            $cb = $this->[0];
            if( scalar( @$this ) > 1 )
            {
                # If the user provided an array reference as the second argument, we use it as the list of parameters to pass the callback
                if( scalar( @$this ) == 2 &&
                    CORE::ref( $this->[1] ) eq 'ARRAY' )
                {
                    $args = $this->[1];
                }
                # Otherwise, the user has passed a list of arguments that will become the list of parameters to pass the callback
                else
                {
                    $args = [@$this[1..$#$this]];
                }
            }
        }
    }
    # The user has provided just on argument, and it is the callback itself
    elsif( CORE::ref( $this ) eq 'CODE' )
    {
        $cb = $this;
    }
    else
    {
        return( $self->error( "Option on_get must be a CODE reference." ) );
    }
    # We make sure that if there is no $args, then there is no second argument whose value would be undef.
    # Instead, the callback would see only 1 argument.
    return( $cb, ( defined( $args ) ? $args : () ) ) if( defined( $cb ) );
    return;
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
        my $rc = eval{ $rw ? $mutex->trywrlock : $mutex->tryrdlock };
        if( $@ )
        {
            warn( "Unable to acquire ", ( $rw ? 'write' : 'read' ), " lock using mutex from APR::ThreadRWLock: $@" );
            return;
        }

        if( !$rc )
        {
            $self->__message( 4, 'Acquired ' . ( $rw ? 'write' : 'read' ) . ' lock.' );
            return(1);
        }

        if( $rc == &APR::Const::EAGAIN || $rc == &APR::Const::EBUSY )
        {
            # Exponential backoff
            my $delay = $base_delay * ( 2 ** $retry );
            # Sleep for delay µs
            select( undef, undef, undef, $delay / 1_000_000.0 );
            next;
        }
    }

    $self->__message( 3, 'Failed to acquire lock after ' . MAX_RETRIES . ' retries.' );
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

sub __message
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
    if( $MOD_PERL )
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

sub _serialise
{
    my $self = shift( @_ );
    my $data = shift( @_ );
    return( '' ) if( !CORE::defined( $data ) );
    return( '' ) if( Scalar::Util::blessed( $data ) && $data->isa( 'Module::Generic::Null' ) );
    return( '' ) if( !CORE::length( $data // '' ) );
    my $serialiser = $self->{serialiser} || $DEFAULT_SERIALISER || 'Storable::Improved';
    if( $serialiser eq 'CBOR' || $serialiser eq 'CBOR::XS' )
    {
        eval( "require CBOR::XS;" );
        if( $@ )
        {
            return( $self->error( "Unable to load serialiser CBOR::XS: $@" ) );
        }
    }
    else
    {
        eval( "require $serialiser;" );
        if( $@ )
        {
            return( $self->error( "Unable to load serialiser $serialiser: $@" ) );
        }
        if( $serialiser eq 'Sereal' )
        {
            eval( "require Sereal::Encoder;" );
            if( $@ )
            {
                return( $self->error( "Unable to load serialiser Sereal::Encoder: $@" ) );
            }
        }
    }

    # try-catch
    local $@;
    if( ref( $serialiser ) eq 'CODE' )
    {
        my $serialised = eval
        {
            return( $serialiser->( $data, 'freeze' ) );
        };
        if( $@ )
        {
            return( $self->error( "Error trying to serialise data with user-provided callback: $@" ) );
        }
        return( $serialised );
    }
    elsif( $serialiser eq 'CBOR' || $serialiser eq 'CBOR::XS' )
    {
        my $cbor = CBOR::XS->new;
        $cbor->allow_sharing(1);
        my $serialised = eval
        {
            $cbor->encode( $data );
        };
        if( $@ )
        {
            return( $self->error( "Error trying to serialise data with $serialiser: $@" ) );
        }
        return( $serialised );
    }
    elsif( $serialiser eq 'CBOR::Free' )
    {
        my $serialised = eval
        {
            CBOR::Free::encode( $data );
        };
        if( $@ )
        {
            return( $self->error( "Error trying to serialise data with $serialiser: $@" ) );
        }
        return( $serialised );
    }
    elsif( $serialiser eq 'Sereal' )
    {
        my $enc = Sereal::Encoder->new;
        my $serialised = eval
        {
            $enc->encode( $data );
        };
        if( $@ )
        {
            return( $self->error( "Error trying to serialise data with $serialiser: $@" ) );
        }
        return( $serialised );
    }
    elsif( $serialiser eq 'Storable::Improved' || $serialiser eq 'Storable' )
    {
        my $serialised = eval
        {
            my $code = $serialiser->can( 'freeze' );
            if( !defined( $code ) )
            {
                die( "Class $serialiser has no method 'freeze' to serialise data." );
            }
            return( $code->( $data ) );
        };
        if( $@ )
        {
            return( $self->error( "Error trying to serialise data with $serialiser: $@" ) );
        }
        return( $serialised );
    }
    else
    {
        return( $self->error( "Unsupporterd serialiser \"$serialiser\"." ) );
    }
}

sub _share_repo
{
    my $self = shift( @_ );
    my $ns   = shift( @_ ) || die( "No namespace is set." );
    if( !CORE::exists( $REPO->{ $ns } ) )
    {
        # $self->__message( 4, "The repository for namespace '$ns' does not exist yet, creating it now." );
        # $self->__message( 4, "_NEED_SHARED has value '", ( _NEED_SHARED // 'undef' ), "'" );
        if( _NEED_SHARED )
        {
            # $self->__message( 4, "Initialising shared repository for namespace '$ns'." );
            my %sub_repo :shared;
            $REPO->{ $ns } = \%sub_repo;
        }
        else
        {
            # $self->__message( 4, "Initialising non-shared repository for namespace '$ns'." );
            $REPO->{ $ns } = {};
        }
    }
    else
    {
        # $REPO->{ $ns } already exists.
        # $self->__message( 4, "\$REPO->{ $ns } (", overload::StrVal( $REPO->{ $ns } ), ") already exists, and is shared ? ", ( HAS_THREADS && threads::shared::is_shared( $REPO->{ $ns } ) ? 'yes' : 'no' ) );
    }

    # To keep track of they keys in a given namespace
    if( !CORE::exists( $ORDER->{ $ns } ) )
    {
        if( _NEED_SHARED )
        {
            my @sub_order :shared;
            $ORDER->{ $ns } = \@sub_order;
        }
        else
        {
            $ORDER->{ $ns } = [];
        }
    }

    # To keep track of repositories size, and to later act accordingly
    if( !CORE::exists( $SIZES->{ $ns } ) )
    {
        if( _NEED_SHARED )
        {
            my $sub_size :shared = 0;
            $SIZES->{ $ns } = \$sub_size;
        }
        else
        {
            my $sub_size = 0;
            $SIZES->{ $ns } = \$sub_size;
        }
    }

    if( !CORE::exists( $NS_LOCKS->{ $ns } ) )
    {
        if( _NEED_SHARED )
        {
            my $ns_lock :shared = 0;
            $NS_LOCKS->{ $ns } = \$ns_lock;
        }
        else
        {
            my $ns_lock = 0;
            $NS_LOCKS->{ $ns } = \$ns_lock;
        }
    }

    if( $self->{refcount} )
    {
        if( !CORE::exists( $REFCOUNTS->{ $ns } ) )
        {
            if( _NEED_SHARED )
            {
                my %refcounts :shared;
                $REFCOUNTS->{ $ns } = \%refcounts;
            }
            else
            {
                $REFCOUNTS->{ $ns } = {};
            }
        }
    }
    return(1);
}

sub _unlock
{
    $MUTEX->unlock if( USE_MUTEX );
    return(1);
}

# NOTE: END
END
{
    # On threaded Perls, clearing shared hashes while other threads may still be running
    # or in their own destruction phase causes a SEGV in threads::shared. We therefore
    # skip the cleanup when threads are active, and let Perl's own global destruction
    # handle the memory.
    if( _NEED_SHARED && $INC{'threads.pm'} )
    {
        my @running = grep { $_->is_running } threads->list;
        return if( @running );
    }
    %$REPO      = ();
    %$ERRORS    = ();
    %$LOCKS     = ();
    %$STATS     = ();
    %$ORDER     = ();
    %$SIZES     = ();
    %$CLEANUP   = ();
    %$NS_LOCKS  = ();
    %$REFCOUNTS = ();
};

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
        if( $serialiser eq 'Sereal' )
        {
            require Sereal::Encoder;
            require version;

            if( version->parse( Sereal::Encoder->VERSION ) <= version->parse( '4.023' ) )
            {
                CORE::return( [$class, $$self] );
            }
        }
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

    use Module::Generic::Global ':const';

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
        # do something safely
    } # lock released at end of scope

    # With limits
    my $limited = Module::Generic::Global->new( 'bounded' => 'My::Module',
        max_size        => 10,          # max keys in namespace
        max_store_bytes => 1024,        # max bytes per stored item (serialised)
        max_total_bytes => 4096         # max bytes total in namespace (serialised)
    );
    $limited->set( 'data' ); # Evicts if over

    # With auto-cleanup (mod_perl)
    my $auto = Module::Generic::Global->new( 'temp' => 'My::Module',
        auto_cleanup => 1  # Auto-registers cleanup for self namespace
    );
    # Or with options
    my $custom_auto = Module::Generic::Global->new(
        'multi' => 'My::Module',
        auto_cleanup =>
        {
            namespaces => ['temp', 'cache'],
            keep       => ['persistent'],
            callback   => sub
            {
                my( $repo, $r ) = @_;
                $r->log->notice( "Cleanup for " . $repo->namespace );
            },
        }
    );

    # Manual cleanup register (mod_perl)
    $repo->cleanup_register( r => $apache_r ); # clears default namespace unless overridden
    $repo->cleanup_register(
        r          => $apache_r,
        namespaces => ['extra'],
        keep       => ['save'],
        callback   => sub { ... },
    );

=head1 VERSION

    v1.1.1

=head1 DESCRIPTION

This module provides contextual, thread/process-safe global storage, organised by namespace and a context key derived from a class name, object identity, or the special C<system> context. Supports Perl ithreads or APR-based threading environments.

It has no dependencies except for L<Scalar::Util> and L<Storable::Improved>

It is designed to work in:

=over 4

=item * single-process non-threaded Perl

=item * Perl ithreads (L<threads> / L<threads::shared>)

=item * mod_perl under threaded MPMs (Worker/Event), including a fallback to L<APR::ThreadRWLock> when shared variables are not available

=back

Values are serialised before storage (default C<Storable::Improved>) and deserialised on retrieval.

The repository used is locked in read or write mode before being accessed ensuring no collision and integrity.

It is designed to store one value at a time in the specified namespace in the global repository.

=head2 Notes on context and scope

The repository is stored in memory. This means:

=over 4

=item * Under a multi-process server (such as Apache), the C<system> context is per-process.

=item * Under threads, values may be shared within a process depending on the runtime environment and the locking backend.

=back

In other words: C<system> means "system within this process/runtime context", not "system across all server processes".

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

    # Declaring a callback used by the get() method
    my $repo = Module::Generic::Global->new( 'cache' => $obj,
        key => $unique_key,
        on_get => sub
        {
            my $cache = shift( @_ );
            my $repo  = $_; # The object is accessible as $_
        },
        serialiser => 'Sereal',
    );

    # Or by providing some values in the callback
    my $repo = Module::Generic::Global->new( 'cache' => $obj,
        key => $unique_key,
        on_get => [sub
            {
                my $cache = shift( @_ );
                my $repo  = $_; # The object is accessible as $_
            },
            host => 'localhost', user => 'john', password => 'some secret', port => 12345
        ]
    );

    # or by providing the arguments as an array reference
    my $repo = Module::Generic::Global->new( 'cache' => $obj,
        key => $unique_key,
        on_get => [sub
            {
                my $cache = shift( @_ );
                my $repo  = $_; # The object is accessible as $_
            },
            [ host => 'localhost', user => 'john', password => 'some secret', port => 12345 ]
        ]
    );

=head2 new

Creates a new repository under a given namespace, and context, and return the new class instance.

A context key is composed of:

=over 4

=item 1. the class name, or the object ID retrieved with L<Scalar::Util/refaddr> if a blessed C<object> was provided,

=item 2. the current process ID, and

=item 3. optionally the thread L<tid|threads/tid> if running under a thread.

=back

However, if a context is C<system>, then the C<key> is also automatically set to C<system>.

For object-level repositories, when running under Perl ithreads and C<threads> is loaded, the thread id is included in the default key.

=head3 Possible options

=over 4

=item * C<auto_cleanup>

Enable auto cleanup mode. This is disabled by default. When enabled, this will empty the global repository. When running under mod_perl, this will call cleanup_register using L<Apache2::RequestUtil/request>. If C<GlobalRequest> of mod_perl is not enabled, or an error occurs, it will be caught, so this is safe to use.

Supported values are:

=over 8

=item * C<0> (default)

=item * C<1> (enable with default behaviour)

=item * a hash reference of options passed to L</cleanup_register>

=back

Example:

    Module::Generic::Global->new( 'cache' => $module_class, 
        auto_cleanup =>
        {
            namespaces => ['ns1','ns2'],
            keep => ['persistent'],
            callback => sub
            {
                my( $repo, $r ) = @_;
                $r->log->notice( "Module::Generic::Global clean up ", $repo->namespace, " occurred." );
            }
        }
    );

C<auto_cleanup> does not accept a plain CODE reference as a mode; use the hashref form and pass C<callback> instead.

=item * C<key>

Specifies explicitly a key to use instead of the default computed key.

Please note that this option would be discarded if the C<context> is set to C<system>

=item * C<max_size>

Maximum number of keys in a namespace (integer > 0). If exceeded on C<set>, older entries are evicted.

Eviction order is based on the internal ordering list, which is updated on successful C<set>. Overwriting an existing key refreshes its recency.

=item * C<max_store_bytes>

Maximum allowed size (in bytes) for a single stored value (integer > 0). The size is based on the serialised representation (and for scalars, the raw scalar size is also checked).

Default: 5MB (5242880).

=item * C<max_total_bytes>

Maximum allowed total size (in bytes) for all stored values in a namespace (integer > 0). If exceeded on C<set>, older entries are evicted until the new total fits, otherwise C<set> fails.

Eviction order is based on the internal ordering list, which is updated on successful C<set>. Overwriting an existing key refreshes its recency.

=item * C<on_get>

Registers a callback that is automatically executed after a successful call to L</get>.

This is useful to restore contextual dependencies after deserialisation (e.g. re-attaching a database connection object).

The callback can be provided as:

=over 8

=item * a code reference

    on_get => sub { ... }

=item * an array reference of callback + arguments

    on_get => [
        sub { my( $value, @args ) = @_; ... },
        [ 'arg1', 'arg2' ],
    ];

or:

    on_get => [
        sub { my( $value, @args ) = @_; ... },
        'arg1',
        'arg2',
    ];

=back

When the callback is executed, C<$_> is locally set to the current repository object instance.

This allows the callback to access the repository without altering the callback argument list.

Example:

    on_get => sub
    {
        my( $value ) = @_;
        my $repo = $_;
        return( $value );
    };

You may override the callback per-call by passing C<on_get> to L</get>.

=item * C<refcount>

When the C<refcount> option is provided (boolean C<0>/C<1>/empty string or C<undef>), the repository enables reference counting for automatic cleanup.

C<Module::Generic::Global> will count increment on creation and decrement on destroy-entries remove when hitting C<0>. Implicitly enabled for class-level contexts (string controller, no key) to manage shared lifetime. For keyed or object-level, opt-in via C<< refcount => 1 >>.

=item * C<serialiser> or C<serializer>

Specify a serialiser to use instead of the default value set in the global variable C<$DEFAULT_SERIALISER>, which is, by default, set to C<Storable::Improved>

The serialiser will be used to freeze and thaw the data.

Supported serialiser are:

=over 8

=item * C<CBOR> or C<CBOR::XS>

=item * C<CBOR::Free>

=item * C<Sereal>

=item * C<Storable> or C<Storable::Improved>

=item * A CODE reference, called as C<< $serialiser->( $data, 'freeze' ) >> or C<< $serialiser->( $data, 'thaw' ) >>

=back

When a code reference is provided, the following arguments will be provided:

=over 8

=item 1. the data to serialise or to deserialiser

=item 2. the key word C<freeze> or C<thaw> depending on the action.

=back

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

=for Pod::Coverage clear

=head2 clear_error

    $repo->clear_error;
    Module::Generic::Global->clear_error;

This clear the error for the current object, and the latest recorded error stored as a global variable.

=for Pod::Coverage cleanup

=for Pod::Coverage debug

=head2 error

    $repo->error( "Something went wrong: ", $some_value );
    my $exception = $repo->error;

Used as a mutator, and this sets an L<exception object|Module::Generic::Exception>, and returns C<undef> in scalar context, or an empty list in list context.

In accessor mode, this returns the currently set L<exception object|Module::Generic::Exception>, if any.

=head2 exists

Returns true (C<1>) if a value is currently stored under the context, o false (C<0>) otherwise. This only checks that an entry exists, not whether that entry has a true value.

=head2 get

Retrieves the stored value, deserialising it using the preferred serialiser if it was serialised, and return it.

If an error occurs, it returns C<undef> in scalar context, or an empty list in list context.

The callback registered via the C<on_get> option (constructor) is executed after deserialisation.
You may also override the callback on a per-call basis by passing C<on_get> to C<get()>.

=head3 Examples

=head4 Basic usage

    my $repo = Module::Generic::Global->new( table_cache => 'system' );
    my $cache = $repo->get;

=head4 Using an on_get callback declared once at construction time

This is useful when your cached objects require contextual restoration after deserialisation.

    my $repo = Module::Generic::Global->new(
        table_cache => 'system',
        on_get => sub
        {
            my( $value ) = @_;
            my $repo = $_;

            # Example of a post-thaw adjustment
            # $value->some_init_method if( ref( $value ) );

            return( $value );
        }
    );

    my $cache = $repo->get;

=head4 Passing extra arguments to the callback

    my $repo = Module::Generic::Global->new(
        table_cache => 'system',
        on_get => [
            sub
            {
                my( $value, $prefix ) = @_;
                my $repo = $_;
                # Do something with $value and $prefix
                return( $value );
            },
            "tables-cache: ",
        ],
    );

    my $cache = $repo->get;

=head4 Overriding the callback explicitly at get() time

This overrides the callback that was optionally provided at construction.

    my $cache = $repo->get(
        on_get => sub
        {
            my( $value ) = @_;
            my $repo = $_;
            return( $value );
        }
    );

=head4 Re-attaching a database connection after deserialisation

This pattern is typical when serialising objects that should not store runtime resources such as DBI handles.

    my $repo = Module::Generic::Global->new(
        table_cache => 'system',
        on_get => sub
        {
            my( $tables ) = @_;
            my $repo = $_;

            return if( !ref( $tables ) );

            # Example: rebind a connection object after thaw
            # $tables->dbo( $dbo );

            return( $tables );
        }
    );

    my $tables = $repo->get;

=head2 key

Returns the computed or explicit key used by this instance.

This is read-only.

=head2 length

    my $repo = Module::Generic::Global->new( 'my_repo' => 'My::Module' );
    say $repo->length;

Returns the number of keys currently present in the namespace (as seen in the repository).

=head2 lock

    {
        $repo->lock;
        # Do some computing
        # Lock is freed automatically when it gets out of scope
    }

Sets a lock to ensure the manipulation done is thread-safe. If the code runs in a single thread environment, then this does not do anything.

When the lock gets out of scope, it is automatically removed.

=head2 namespace

Returns the current namespace used in this instance. This is read-only.

=head2 remove

Removes the stored value for the current namespace and key, updates ordering and size accounting, and removes per-key stats.

This can also be called as C<clear>

=head2 set

    $repo->set( { foo => 42 } );

Stores a scalar or serialisable reference in the current namespace and context. This overwrite any previous value for the same context.

The value provided is serialised using the preferred serialiser before it is stored in the global repository.

On success, updates:

=over 4

=item * per-namespace total bytes accounting

=item * per-key stored byte stats

=item * ordering list (the key is moved to the end on every successful set, including overwrites)

=back

If limits are configured (C<max_store_bytes>, C<max_total_bytes>, C<max_size>), older entries may be evicted on set.

Returns true upon success, and upon error, return C<undef> in scalar context, or an empty list in list context.

=head2 stat

Returns an array reference of hash references describing the largest entries in C<$STATS> (sorted by stored bytes), limited by the provided limit (default 20).

It contains the following properties:

=over 4

=item * C<bytes>

The size in bytes for the current value.

=item * C<key>

The repository key.

=back

=head2 unlock

    $repo->unlock;

This is used to remove the lock set when under Apache2 ModPerl by using L<APR::ThreadRWLock/unlock>

It is usually not necessary to call this explicitly, because when the lock set previously gets out of scope, it is automatically removed.

=for Pod::Coverage USE_MUTEX

=head1 CONSTANTS

The constants can be imported into your namespace with:

    use Module::Generic::Global ':const';

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

=item * B<Reference Counting>

When C<refcount> is enabled upon instantiation, repositories use internal counts to auto-remove entries on last reference destroy, preventing leaks in shared contexts. Counts are per-namespace/key, thread-safe via locking.

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
