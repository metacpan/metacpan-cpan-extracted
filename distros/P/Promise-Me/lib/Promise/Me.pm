##----------------------------------------------------------------------------
## Promise - ~/lib/Promise/Me.pm
## Version v0.2.1
## Copyright(c) 2022 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2021/05/28
## Modified 2022/03/30
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Promise::Me;
BEGIN
{
    use Config;
    use strict;
    use warnings;
    use warnings::register;
    use parent qw( Module::Generic );
    use vars qw( $KIDS $DEBUG $FILTER_RE_FUNC_ARGS $FILTER_RE_SHARED_ATTRIBUTE 
                 $SHARED_MEMORY_SIZE $SHARED $VERSION $SHARE_MEDIUM $SHARE_FALLBACK 
                 $SHARE_AUTO_DESTROY $OBJECTS_REPO );
    use Clone;
    use Filter::Util::Call ();
    use Module::Generic::File::Cache v0.1.0;
    use Module::Generic::SharedMem v0.2.3 qw( :all );
    use Nice::Try;
    use POSIX qw( WNOHANG WIFEXITED WEXITSTATUS WIFSIGNALED );
    use PPI;
    use Scalar::Util;
    use Want;
    our $KIDS = {};
    our @EXPORT = qw( async await share unshare lock unlock );
    our @EXPORT_OK = qw( share unshare lock unlock );
    our %EXPORT_TAGS = (
            all     => [qw( share unshare lock unlock )],
            lock    => [qw( lock unlock )],
            share   => [qw( share unshare )],
    );
    Exporter::export_ok_tags( 'all', 'lock', 'share' );
    our $DEBUG = 0;
    # share( $this ):
    # share( \$this );
    # share ( ( \$this ), (( @that ) ), %plop );
    # share 
    #   ( ( \$this ), (( @that ) ), %plop );
    our $FILTER_RE_FUNC_ARGS = qr{
        (?<func>
            \b(?:share|unshare|lock|unlock)\b
            [[:blank:]\h\v]*
            (?!\{)
        )
        (?<args>
            (?:
                (?:
                    [[:blank:]\h\v]
                    |
                    \(
                )*
                \\?[\$\@\%\*]\w+
                (?:[[:blank:]\h\v]|\)|,)*
            )+
        )
    }x;
    # my $val : shared;
    # our $val : shared = 'John';
    # our( $plop, @truc ) : shared = ( '2', qw( Pierre Paul ) );
    our $FILTER_RE_SHARED_ATTRIBUTE;
    if( $INC{'threads.pm'} )
    {
        $FILTER_RE_SHARED_ATTRIBUTE = qr{
            (
                (?:my|our)
                (
                    (?:
                        [[:blank:]\h\v]
                        |
                        \(
                    )*
                    \\?[\$\@\%\*]\w+
                    (?:[[:blank:]\h\v]|\)|,)*
                )+
                \:[[:blank:]\h\v]*
            )
            \b(?:pshared)\b
        }x;
    }
    else
    {
        $FILTER_RE_SHARED_ATTRIBUTE = qr{
            (
                (?:my|our)
                (
                    (?:
                        [[:blank:]\h\v]
                        |
                        \(
                    )*
                    \\?[\$\@\%\*]\w+
                    (?:[[:blank:]\h\v]|\)|,)*
                )+
                \:[[:blank:]\h\v]*
            )
            \b(?:pshared|shared)\b
        }x;
    }
    our $SHARED_MEMORY_SIZE = ( 64 * 1024 );
    use constant SHARED_MEMORY_BLOCK => ( 64 * 1024 );
    our $SHARED  = {};
    our $SHARE_MEDIUM = 'memory';
    # If shared memory block is not supported, should we fall back to cache file?
    our $SHARE_FALLBACK = 1;
    our $SHARE_AUTO_DESTROY = 1;
    # A repository of objects that is used by END and DESTROY to remove the shared
    # space only when no proces is using it, since the processes run asynchronously
    our $OBJECTS_REPO = [];
    our $VERSION = 'v0.2.1';
};

sub import
{
    my $class = shift( @_ );
    my $hash = {};
    for( my $i = 0; $i < scalar( @_ ); $i++ )
    {
        if( $_[$i] eq 'debug' || 
            $_[$i] eq 'debug_code' || 
            $_[$i] eq 'debug_file' ||
            $_[$i] eq 'no_filter' )
        {
            $hash->{ $_[$i] } = $_[$i+1];
            CORE::splice( @_, $i, 2 );
            $i--;
        }
    }
    $hash->{debug} = 0 if( !CORE::exists( $hash->{debug} ) );
    $hash->{no_filter} = 0 if( !CORE::exists( $hash->{no_filter} ) );
    $hash->{debug_code} = 0 if( !CORE::exists( $hash->{debug_code} ) );
    Filter::Util::Call::filter_add( bless( $hash => ( ref( $class ) || $class ) ) );
    my $caller = caller;
    no strict 'refs';
    for( qw( ARRAY HASH SCALAR ) )
    {
        *{"${caller}\::MODIFY_${_}_ATTRIBUTES"} = sub
        {
            my( $pack, $ref, $attr ) = @_;
            {
                if( $attr eq 'Promise_shared' )
                {
                    my $type = lc( ref( $ref ) );
                    if( $type !~ /^(array|hash|scalar)$/ )
                    {
                        warnings::warn( "Unsupported variable type '$type': '$ref'\n" ) if( warnings::enabled() || $DEBUG );
                        return;
                    }
                    &{"${class}\::share"}( $ref );
                }
            }
            return;
        };
    }
    $class->export_to_level( 1, @_ );
}

sub filter
{
    my( $self ) = @_ ;
    my( $status, $last_line );
    my $line = 0;
    my $code = '';
    if( $self->{no_filter} )
    {
        Filter::Util::Call::filter_del();
        $status = 1;
        $self->message( 3, "Skiping filtering." );
        return( $status );
    }
    while( $status = Filter::Util::Call::filter_read() )
    {
        return( $status ) if( $status < 0 );
        $line++;
        if( /^__(?:DATA|END)__/ )
        {
            $last_line = $_;
            last;
        }
        
        s{
            $FILTER_RE_FUNC_ARGS
        }
        {
            my $func = $+{func};
            my $args = $+{args};
            # print( STDERR "Func is '$+{func}' and args are: '$+{args}'\n" );
            $args =~ s,(?<!\\)([\$\@\%\*]\w+),\\$1,g;
            "$func$args";
        }gexs;
        
        s{
            $FILTER_RE_SHARED_ATTRIBUTE
        }
        {
            "${1}Promise_shared"
        }gsex;
        
        s#(\b(?:share|lock|unlock|unshare)\b[[:blank:]\h]*(?!{)\(?[[:blank:]\h]*)(?=[mo\$\@\%])#$1\\#gs;
        $code .= $_;
        $_ = '';
    }
    return( $line ) if( !$line );
    unless( $status < 0 )
    {
        $code = ' ' . $code;
        my $doc = PPI::Document->new( \$code, readonly => 1 ) || die( "Unable to parse: ", PPI::Document->errstr, "\n$code\n" );
        if( $doc = $self->_parse( $doc ) )
        {
            $_ = $doc->serialize;
        }
        # Rollback
        else
        {
            $_ = $code;
        }
        if( CORE::length( $last_line ) )
        {
            $_ .= $last_line;
        }
    }
    unless( $status <= 0 )
    {
        while( $status = Filter::Util::Call::filter_read() )
        {
            return( $status ) if( $status < 0 );
            $line++;
        }
    }
    if( $self->{debug_file} )
    {
        if( open( my $fh, ">$self->{debug_file}" ) )
        {
            binmode( $fh, ':utf8' );
            print( $fh $_ );
            close( $fh );
        }
    }
    return( $line );
}

sub init
{
    my $self = shift( @_ );
    my $name;
    if( @_ >= 2 && !ref( $_[0] ) && ref( $_[1] ) eq 'CODE' )
    {
        $name = shift( @_ );
    }
    my $code = shift( @_ );
    return( $self->error( "No code was provided to execute." ) ) if( !defined( $code ) || ref( $code ) ne 'CODE' );
    $self->{args}  = [];
    $self->{result_shared_mem_size} = '';
    $self->{shared_vars_mem_size}   = $SHARED_MEMORY_SIZE;
    $self->{use_async} = 0;
    # By default, should we use file cache to store shared data or memory?
    $self->{use_cache_file} = ( $SHARE_MEDIUM eq 'file' );
    # XXX Probably should remove as it is not used
    $self->{timeout} = 0;
    $self->{name}  = $name;
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ );
    # async sub my_subroutine { }
    if( $self->{use_async} )
    {
        # If it fails, it will trigger reject()
        $self->{_code} = sub
        {
            $self->resolve( scalar( @{$self->{args}} ) ? $code->( @{$self->{args}} ) : $code->() );
        };
    }
    # Promise::Me->new(sub{ my( $resolve, $reject ) = @_; });
    else
    {
        $self->{_code} = sub
        {
            $code->(
                sub{ $self->resolve( @_ ) },
                sub{ $self->reject( @_ ) },
            );
        };
    }
    $self->{_handlers} = [];
    $self->{_no_more_chaining} = 0;
    $self->{executed}     = 0;
    $self->{exit_bit}     = '';
    $self->{exit_signal}  = '';
    $self->{exit_status}  = '';
    $self->{has_coredump} = 0;
    $self->{is_child}     = 0;
    $self->{pid}          = $$;
    $self->{share_auto_destroy} = 1;
    # promise status; data space shared between child and parent through shared memory
    $self->{shared}       = {};
    $self->{shared_key}   = 'pm' . $$;
    $self->{shared_space_destroy} = 1;
    $self->{global}       = {};
    $self->{global_key}   = 'gl' . $$;
    # This will be set to true if the chain ends with a call to wait()
    # Promise::Me->new(sub{})->then->catch->wait;
    $self->{wait}         = 0;
    # Check if there are any variables to share
    # Because this is stored in a global variable, we use the caller's package name as namespace
    my $pack = caller(1);
    # Resulting values from exec, or then when there are no more handler but there could be later
    $self->{_saved_values} = [];
    $self->{_shared_from} = $pack;
    push( @$OBJECTS_REPO, $self );

#     unless( Want::want( 'OBJECT' ) )
#     {
#         $self->no_more_chaining(1);
#         $self->exec;
#     }
    return( $self );
}

sub add_final_handler
{
    my $self = shift( @_ );
    my $code = shift( @_ ) || return( $self->error( "No code reference was provided to add a final handler." ) );
    return( $self->error( "Final handler provided is not a code reference." ) ) if( ref( $code ) ne 'CODE' );
    push( @{$self->{_handlers}}, { type => 'finally', handler => $code });
    return( $self );
}

sub add_resolve_handler
{
    my $self = shift( @_ );
    my $code = shift( @_ ) || return( $self->error( "No code reference was provided to add a resolve handler." ) );
    return( $self->error( "Resolve handler provided is not a code reference." ) ) if( ref( $code ) ne 'CODE' );
    push( @{$self->{_handlers}}, { type => 'then', handler => $code });
    return( $self );
}

sub add_reject_handler
{
    my $self = shift( @_ );
    my $code = shift( @_ ) || return( $self->error( "No code reference was provided to add a reject handler." ) );
    return( $self->error( "Reject handler provided is not a code reference." ) ) if( ref( $code ) ne 'CODE' );
    push( @{$self->{_handlers}}, { type => 'catch', handler => $code });
    return( $self );
}

sub all
{
    my $this  = shift( @_ );
    return( __PACKAGE__->error( __PACKAGE__, "->all must be called as a class function such as: ", __PACKAGE__, "->all()" ) ) if( ref( $this ) || $this ne 'Promise::Me' );
    my $opts  = {};
    $opts = pop( @_ ) if( ref( $_[-1] ) eq 'HASH' );
    $opts->{timeout} //= 0;
    $opts->{race} //= 0;
    my @proms = ( scalar( @_ ) == 1 && Scalar::Util::reftype( $_[0] ) eq 'ARRAY' ) ? @{$_[0]} : @_;
    # Make sure we are being provided with our objects
    @proms = grep{ Scalar::Util::blessed( $_ ) && $_->isa( 'Promise::Me' ) } @proms;
    return( $this->new(sub
    {
        my( $resolve, $reject ) = @_;
        # We make a copy that we can manipulate, remove, etc
        my @promises = @proms;
        my @results;
        # Size the array
        $#results = $#proms;
        my $done = {};
        my $keep_going = 1;
        local $SIG{ALRM} = sub{ $keep_going = 0 };
        alarm( $opts->{timeout} ) if( $opts->{timeout} =~ /^\d+$/ );
        COLLECT: while($keep_going)
        {
            for( my $i = 0; $i < scalar( @promises ); $i++ )
            {
                next if( CORE::exists( $done->{ $i } ) );
                my $p = $promises[$i];
                if( $p->rejected )
                {
                    $done->{ $i } = 0;
                    $reject->( $p->result );
                    last COLLECT;
                }
                elsif( $p->resolved )
                {
                    $done->{ $i } = 1;
                    if( $opts->{race} )
                    {
                        @results = $p->result;
                        $resolve->( @results );
                        last COLLECT;
                    }
                    else
                    {
                        $results[$i] = $p->result;
                        CORE::splice( @promises, $i, 1 );
                        $i--;
                    }
                }
            }
            last COLLECT if( !scalar( @promises ) );
        }
        alarm(0);
        if( $opts->{race} )
        {
            scalar( @results ) > 1 ? @results : $results[0];
        }
        else
        {
            if( !$keep_going )
            {
                $reject->( Promise::Me::Exception->new( 'timeout' ) );
            }
            else
            {
                $resolve->( \@results );
            }
        }
    }) );
}

sub args { return( shift->_set_get_array_as_object( 'args', @_ ) ); }

sub timeout { return( shift->_set_get_scalar( 'timeout', @_ ) ); }

sub async { return( Promise::Me->new( @_ ) ); }

# Called as a function. Takes promise objects as arguments, possibly with an hash 
# reference of options at the end
# away( $p1, $p2 );
# away( $p1, $p2, { timeout => 2 });
sub await
{
    my $opts = {};
    $opts    = pop( @_ ) if( ref( $_[-1] ) eq 'HASH' );
    my @promises = @_;
    return if( !scalar( @promises ) );
    @promises = grep{ Scalar::Util::blessed( $_ ) && $_->isa( 'Promise::Me' ) } @promises;
    my @results;
    # Pre-size the array
    $#results = $#promises;
    my $timeout = 0;
    $opts->{timeout} //= 3;
    local $SIG{ALRM} = sub
    {
        $timeout++;
        print( STDERR __PACKAGE__, "::await: Reached timeout of $opts->{timeout} seconds.\n" ) if( $DEBUG );
    };
    CORE::alarm( $opts->{timeout} );
    printf( STDERR "%s::await: %d promise(s) to process.\n", __PACKAGE__, scalar( @promises ) ) if( $DEBUG >= 4 );
    CHECK_KIDS: while( !$timeout )
    {
        for( my $i = 0; $i <= $#promises; $i++ )
        {
            my $prom = $promises[$i];
            my $pid  = $prom->child;
            my $prefix = '[' . ( $prom->is_child ? 'child' : 'parent' ) . ']';
            # Already removed
            if( !CORE::exists( $KIDS->{ $pid } ) )
            {
                # $prom->message( 6, "${prefix} Child pid $pid has already been completed, moving on to the next one." );
                splice( @promises, $i, 1 );
                $i--;
                next;
            }

            # $prom->message( 6, "${prefix} Checking id child pid '$pid' is still up. Position is $i out of $#promises" );
            my $rv = waitpid( $pid, POSIX::WNOHANG );
            if( $rv == 0 )
            {
                # $prom->message( 6, "${prefix} Child pid '$pid' is still running, waiting for it." );
            }
            elsif( $rv > 0 )
            {
                # $prom->message( 6, "${prefix} Child process with pid '$pid' finally exited." );
                CORE::delete( $KIDS->{ $pid } );
                $prom->_set_exit_values( $? );
                # $prom->message( 4, "resolved value is '", $prom->resolved, "' and rejected is '", $prom->rejected, "'." );
                if( !$prom->resolved && !$prom->rejected )
                {
                    # $prom->message( 4, "${prefix} Promise is not yet resolved nor rejected. Child exited with value ($?) -> ", $prom->exit_status, " (", ( $? >> 8 ), ")." );
                    # exit with value > 0 meaning an error occurred
                    if( $prom->exit_status )
                    {
                        my $err = '';
                        if( $prom->exit_signal )
                        {
                            $err = 'Asynchronous process killed by signal.';
                        }
                        elsif( $prom->exit_status )
                        {
                            $err = 'Asynchronous process exited due to an error.';
                        }
                        $prom->reject( Promise::Me::Exception->new( $err ) );
                    }
                    else
                    {
                        $prom->resolve;
                    }
                }
                $results[$i] = $prom->result;
            }
            # Child process has already exited
            elsif( $rv == -1 )
            {
                CORE::delete( $KIDS->{ $pid } );
                next CHECK_KIDS;
            }
        }
        last if( !scalar( @promises ) );
        # Mixing alarm and sleep yield weird results, so we temporarily back it up 
        # and deactivate it
        my $alarm = CORE::alarm(0);
        sleep(0.5);
        CORE::alarm( $alarm );
    }
    CORE::alarm(0);
    print( STDERR __PACKAGE__, "::await: Finished awaiting for the processes\n" ) if( $DEBUG >= 4 );
    return( scalar( @results ) > 1 ? @results : $results[0] );
}

sub catch
{
    my $self = shift( @_ );
    @_ = () if( scalar( @_ ) == 1 && !defined( $_[0] ) );
    if( @_ )
    {
        my $code = shift( @_ );
        return( $self->error( "catch() only accepts a code references. Value provided was '$code'." ) ) if( ref( $code ) ne 'CODE' );
        $self->add_reject_handler( $code );
    }
    
    # Is there more chaining, or is this the end of the chain?
    # If the latter, we then start executing our codes
    unless( Want::want( 'OBJECT' ) )
    {
        $self->no_more_chaining(1);
        $self->exec;
    }
    return( $self );
}

sub child { return( shift->_set_get_scalar( 'child', @_ ) ); }

sub exec
{
    my $self = shift( @_ );
    # Block signal for fork
    my $sigset = POSIX::SigSet->new( POSIX::SIGINT );
    POSIX::sigprocmask( POSIX::SIG_BLOCK, $sigset ) || 
        return( $self->error( "Cannot block SIGINT for fork: $!" ) );
    select((select(STDOUT), $|=1)[0]);
    select((select(STDERR), $|=1)[0]);
    $self->executed(1);
    
    my $pid = fork();
    # Parent
    if( $pid )
    {
        # $self->kids->push( $pid );
        $KIDS->{ $pid } = { me => $self };
        $self->child( $pid );
        POSIX::sigprocmask( POSIX::SIG_UNBLOCK, $sigset ) || 
            return( $self->error( "Cannot unblock SIGINT for fork: $!" ) );
        my $shm = $self->_set_shared_space();
        $shm->lock( LOCK_EX );
        $shm->write( $self->{shared} );
        $shm->unlock;
        # If we are to wait for the child to exit, there is no CHLD signal handler
        if( $self->{wait} )
        {
            # $self->message( 3, "[parent] Requested to wait for child process pid '$pid'. Checking it is still there." );
            # Is the child still there?
            if( kill( 0 => $pid ) || $!{EPERM} )
            {
                # $self->message( 3, "[parent] Child process with pid '$pid' is still running, waiting for it to complete." );
                # Blocking wait
                waitpid( $pid, 0 );
                $self->_set_exit_values( $? );
                if( WIFEXITED($?) )
                {
                    # $self->message( 3, "[parent] Child with pid '$pid' exited with bit value '$?' (exit=$self->{exit_status}, signal=$self->{exit_signal}, coredump=$self->{has_coredump})." );
                }
                else
                {
                    # $self->message( 3, "[parent] Child with pid '$pid' exited with bit value '$?' -> $!" );
                }
            }
            else
            {
                # $self->message( 3, "[parent] Child process with pid '$pid' is already completed." );
            }
        }
        else
        {
            # We let perl handle itself the reaping of the child process
            local $SIG{CHLD} = 'IGNORE';
        }
        return( $self );
    }
    # Child
    elsif( $pid == 0 )
    {
        $self->is_child(1);
        $self->pid( $$ );
        $self->_set_shared_space();
        # $self->messagef( 3, "[child] Within child with pid '$$', %d variables to share.", scalar( keys( %{$self->{_shared}} ) ) );
        
        try
        {
            # Possibly any arguments passed in the 'async sub some_routine'; or
            # Promise::Me->new( args => [@args] );
            my $args = $self->args;
            my $code = $self->{_code};
            # $self->messagef( 4, "[child] %d arguments set: '%s'.", scalar( @$args ), join( "', '", @$args ) );
            my @rv = @$args ? $code->( @$args ) : $code->();
            # $self->message( 3, "[child] Child code returned value is: ", ( scalar( @rv ) == 1 && Scalar::Util::blessed( $rv[0] ) ) ? ref( $rv[0] ) . ' object' : sub{ $self->dump( \@rv ) });
            # The code executed, returned a promise, so we use it and call the next 'then' 
            # in the chain with it.
            if( scalar( @rv ) && 
                Scalar::Util::blessed( $rv[0] ) && 
                $rv[0]->isa( 'Promise::Me' ) )
            {
                # $self->message( 3, "[child] Execution of the primary code returned a promise object, calling resolve on it, paassing ", scalar( @rv ), " arguments: [", join( ', ', map( overload::StrVal( $_ ), @rv ) ), "]" );
                shift( @rv )->resolve( @rv );
            }
            elsif( scalar( @rv ) )
            {
                # $self->message( 3, "[child] Execution of the primary code succeeded, calling resolve on it, paassing ", scalar( @rv ), " arguments: [", join( ', ', map( overload::StrVal( $_ ), @rv ) ), "]" );
                $self->resolve( @rv );
            }
        }
        catch( $e )
        {
            # $self->message( 3, "[child] Execution of the primary code failed with error '$e'. Calling reject." );
            if( Scalar::Util::blessed( $e ) )
            {
                $self->reject( $e );
            }
            else
            {
                $self->reject( Promise::Me::Exception->new( $e ) );
            }
        }
        exit(0);
    }
    else
    {
        my $err;
        if( $! == POSIX::EAGAIN() )
        {
            $err = "fork cannot allocate sufficient memory to copy the parent's page tables and allocate a task structure for the child.";
        }
        elsif( $! == POSIX::ENOMEM() )
        {
            $err = "fork failed to allocate the necessary kernel structures because memory is tight.";
        }
        else
        {
            $err = "Unable to fork a new process to execute promised code: $!";
        }
        return( $self->reject( Module::Promise::Exception->new( $err ) ) );
    }
    return( $self );
}

sub executed { return( shift->_set_get_boolean( 'executed', @_ ) ); }

sub exit_bit { return( shift->_set_get_scalar( 'exit_bit', @_ ) ); }

sub exit_signal { return( shift->_set_get_scalar( 'exit_signal', @_ ) ); }

sub exit_status { return( shift->_set_get_scalar( 'exit_status', @_ ) ); }

sub get_next_by_type
{
    my $self = shift( @_ );
    my $type = shift( @_ ) ||
        return( $self->error( "No type provided to get its next handler." ) );
    my $h = $self->{_handlers};
    my( $code, $pos );
    for( my $i = 0; $i < scalar( @$h ); $i++ )
    {
        if( $h->[$i]->{type} eq $type )
        {
            $code = $h->[$i]->{handler};
            $pos = $i;
            last;
        }
    }
    return if( !defined( $code ) );
    splice( @$h, 0, $pos + 1 );
    return( $code );
}

sub get_finally_handler { return( shift->get_next_by_type( 'finally' ) ); }

sub get_next_reject_handler { return( shift->get_next_by_type( 'catch' ) ); }

sub get_next_resolve_handler { return( shift->get_next_by_type( 'then' ) ); }

sub has_coredump { return( shift->_set_get_boolean( 'has_coredump', @_ ) ); }

sub is_child { return( shift->_set_get_boolean( 'is_child', @_ ) ); }

sub is_parent { return( !shift->is_child ); }

sub lock
{
    my $self;
    $self = shift( @_ ) if( scalar( @_ ) && Scalar::Util::blessed( $_[0] ) && $_[0]->isa( 'Promise::Me' ) );
    my $type;
    $type = pop( @_ ) if( !ref( $_[-1] ) );
    my $prefix = '[' . ( $self->is_child ? 'child' : 'parent' ) . ']';
    foreach my $ref ( @_ )
    {
        my $tied = tied( $ref );
        if( defined( $self ) )
        {
            $self->message( 4, "${prefix} Checking if variable '$ref' is tied -> ", sub{ ( Scalar::Util::blessed( $tied ) ? 'Yes' : 'No' ) });
        }
        else
        {
            print( STDERR __PACKAGE__, "::lock: Checking if variable '$ref' is tied -> ", ( Scalar::Util::blessed( $tied ) ? 'Yes' : 'No' ), "\n" ) if( $DEBUG >= 4 );
        }
        if( Scalar::Util::blessed( $tied ) &&
            $tied->isa( 'Promise::Me::Share' ) )
        {
            defined( $type ) ? $tied->lock( $type ) : $tied->lock;
        }
    }
    return( $self ) if( $self );
}

sub no_more_chaining { return( shift->_set_get_boolean( '_no_more_chaining', @_ ) ); }

sub pid { return( shift->_set_get_scalar( 'pid', @_ ) ); }

sub race
{
    my $this = shift( @_ );
    return( __PACKAGE__->error( __PACKAGE__, "->race must be called as a class function such as: ", __PACKAGE__, "->race()" ) ) if( ref( $this ) || $this ne 'Promise::Me' );
    my $opts = {};
    $opts = pop( @_ ) if( ref( $_[-1] ) eq 'HASH' );
    $opts->{race} = 1;
    return( $this->all( @_, $opts ) );
}

sub reject
{
    my $self = shift( @_ );
    my $vals = [@_];
    $self->rejected(1);
    # Maybe there is no more reject handler, like when we are at the end of the chain.
    my $code = $self->get_next_reject_handler();
    if( !defined( $code ) )
    {
        $self->{_saved_values} = $vals;
        return( $self );
    }
    try
    {
        my @rv = $code->( @$vals );
        # The code returned another promise
        if( scalar( @rv ) && 
            Scalar::Util::blessed( $rv[0] ) && 
            $rv[0]->isa( 'Promise::Me' ) )
        {
            # $self->message( 4, "${prefix} Calling reject handler returned a promise. Calling its resolve on it." );
            return( shift( @rv )->resolve( @rv ) );
        }
        # We call our next 'then' by resolving this with the arguments received
        elsif( scalar( @rv ) )
        {
            # $self->message( 4, "${prefix} Calling reject handler returned ", scalar( @rv ), " values. Calling our resolve on it: ", sub{ $self->dump( \@rv ) } );
            return( $self->resolve( @rv ) );
        }
        # Called in void
        else
        {
            # $self->message( 4, "${prefix} Called in void context, returning our own object." );
            return( $self );
        }
    }
    catch( $e )
    {
        if( Scalar::Util::blessed( $e ) )
        {
            # $self->message( 4, "${prefix} An error occurred while executing the reject handler. I received an object: $e" );
            return( $self->reject( $e ) );
        }
        else
        {
            # $self->message( 4, "${prefix} An error occurred while executing the reject handler. I received: $e" );
            return( $self->reject( Promise::Me::Exception->new( $e ) ) );
        }
    }
}

sub rejected { return( shift->_reject_resolve( 'rejected', @_ ) ); }

sub resolve
{
    my $self = shift( @_ );
    my $vals = [@_];
    my $prefix = '[' . ( $self->is_child ? 'child' : 'parent' ) . ']';
    if( $self->debug >= 3 )
    {
        my $trace = $self->_get_stack_trace;
        # $self->messagef( 3, "${prefix} Found %d handlers. Trace: %s", scalar( @{$self->{_handlers}} ), $trace->as_string );
    }
    # Maybe there is no more resolve handler, like when we are at the end of the chain.
    my $code = $self->get_next_resolve_handler();
    {
        no warnings;
        # $self->message( 4, "${prefix} Using code: '$code' (possibly none) for resolve handler." );
    }
    # # No more resolve handler. We are at the end of the chain. Mark this as resolved
    # No actually, marke this resolved right now, and if next iteration is a fail, 
    # then it will be marked differently
    $self->resolved(1);
    if( !defined( $code ) || !ref( $code ) )
    {
        # $self->messagef( 4, "${prefix} Storing resulting values '%s'.", join( ',', @$vals ) );
        $self->{_saved_values} = $vals;
        return( $self );
    }
    
    try
    {
        # $self->messagef( 4, "${prefix} Calling then with %d parameters; '%s'", scalar( @$vals ), join( "', '", @$vals ) );
        my @rv = $code->( @$vals );
        # $self->message( 4, "${prefix} Saving result from then execution: '", join( "', '", @rv ), "'" );
        $self->result( @rv );
        # The code returned another promise
        if( scalar( @rv ) && 
            Scalar::Util::blessed( $rv[0] ) && 
            $rv[0]->isa( 'Promise::Me' ) )
        {
            # $self->message( 4, "${prefix} Code returned a promise, calling resolve on it." );
            return( shift( @rv )->resolve( @rv ) );
        }
        # We call our next 'then' by resolving this with the arguments received
        elsif( scalar( @rv ) )
        {
            # $self->message( 4, "${prefix} Code returned ", scalar( @rv ), " value(s), calling our resolve with it: [", sub{ join( ', ', map( overload::StrVal( $_ ), @rv ) ) }, "]" );
            return( $self->resolve( @rv ) );
        }
        # Called in void
        else
        {
            # $self->message( 4, "${prefix} Code was called in void, returning self." );
            return( $self );
        }
    }
    catch( $e )
    {
        my $ex;
        if( Scalar::Util::blessed( $e ) )
        {
            # $self->message( 4, "${prefix} An error occurred while executing the resolve handler. I received an object: $e" );
            $ex = $e;
        }
        else
        {
            # $self->message( 4, "${prefix} An error occurred while executing the resolve handler. I received: $e" );
            $ex = Promise::Me::Exception->new( $e );
        }
        $self->result( $ex );
        return( $self->reject( $ex ) );
    }
}

sub resolved { return( shift->_reject_resolve( 'resolved', @_ ) ); }

sub result
{
    my $self = shift( @_ );
    my $shm = $self->shared_mem;
    my $prefix = '[' . ( $self->is_child ? 'child' : 'parent' ) . ']';
    if( @_ )
    {
        # We need to save the result provided as a 1 reference variable
        my $val = ( @_ == 1 && ref( $_[0] ) ) ? shift( @_ ) : [@_];
        if( $shm )
        {
            my $hash = $shm->read;
            # $self->message( 4, "${prefix} Retrieved hash from shared memory '$hash' for 'result' with value '$val'." );
            $hash->{result} = $val;
            # $self->message( 4, "${prefix} Saving hash to shared memory with value: ", sub{ $self->_is_object( $hash ) ? overload::StrVal( $hash ) : $self->dump( $hash ) });
            $shm->write( $hash );
        }
        else
        {
            # $self->message_colour( 4, "${prefix}  <red>Shared memory object not found.</>" );
            warnings::warn( "Shared space object not set or lost!\n" ) if( warnings::enabled() || $self->debug );
        }
    }
    else
    {
        my $hash = $shm->read;
        # $self->message( 4, "${prefix} Retrieved value of shared hash -> ", sub{ $self->_is_object( $hash ) ? overload::StrVal( $hash ) : $self->dump( $hash ) });
        $self->{shared} = $hash;
        return( $hash->{result} );
    }
}

sub result_shared_mem_size { return( shift->_set_get_mem_size( 'result_shared_mem_size', @_ ) ); }

# We merely register the variables the user wants to share
# Next time we will fork, we will share those registered variables
sub share
{
    my $self;
    $self = shift( @_ ) if( scalar( @_ ) && Scalar::Util::blessed( $_[0] ) && $_[0]->isa( 'Promise::Me' ) );
    # Sanity check
    foreach my $ref ( @_ )
    {
        my $type = lc( ref( $ref ) );
        print( STDERR __PACKAGE__, "::share: Checking variable '$ref'.\n" ) if( $DEBUG );
        if( $type !~ /^(array|hash|scalar)$/ )
        {
            warnings::warn( "Unsupported variable type '$type': '$ref'\n" ) if( warnings::enabled() || $DEBUG );
            next;
        }
    }
    printf( STDERR "%s::share: Calling _share_vars() for %d variables.\n", __PACKAGE__, scalar( @_ ) ) if( $DEBUG >= 4 );
    &_share_vars( [@_] ) || return;
    return(1);
}

sub share_auto_destroy { return( shift->_set_get_boolean( 'share_auto_destroy', @_ ) ); }

sub shared_mem { return( shift->_set_get_object_without_init( 'shared_mem', [qw( Module::Generic::SharedMem Module::Generic::File::Cache )], @_ ) ); }

sub shared_mem_global { return( shift->_set_get_object( 'shared_mem_global',[qw( Module::Generic::SharedMem Module::Generic::File::Cache )], @_ ) ); }

sub shared_space_destroy { return( shift->_set_get_boolean( 'shared_space_destroy', @_ ) ); }

sub shared_vars_mem_size { return( shift->_set_get_mem_size( 'shared_vars_mem_size', @_ ) ); }

# $d->then(sub{ do_something() })->catch()->finally();
sub then
{
    my $self = shift( @_ );
    @_ = () if( scalar( @_ ) == 1 && !defined( $_[0] ) );
    if( @_ )
    {
        my( $pass, $fail ) = @_;
        return( $self->error( "then() only accepts one or two code references. Value provided for resolve was '$pass'." ) ) if( ref( $pass ) ne 'CODE' );
        return( $self->error( "then() only accepts one or two code references. Value provided for reject was '$fail'." ) ) if( defined( $fail ) && ref( $fail ) ne 'CODE' );
        $self->add_resolve_handler( $pass );
        $self->add_reject_handler( $fail ) if( defined( $fail ) );
        my $vals = $self->{_saved_values} || [];
        # Now that we have a new handler, call resolve to process the saved values
        if( $self->executed && scalar( @$vals ) )
        {
            if( $self->rejected )
            {
                return( $self->reject( @$vals ) );
            }
            else
            {
                return( $self->resolve( @$vals ) );
            }
        }
    }
    
    # Is there more chaining, or is this the end of the chain?
    # If the latter, we then start executing our codes
    unless( Want::want( 'OBJECT' ) || $self->executed )
    {
        $self->no_more_chaining(1);
        $self->exec;
    }
    return( $self );
}

sub unlock
{
    my $self;
    $self = shift( @_ ) if( scalar( @_ ) && Scalar::Util::blessed( $_[0] ) && $_[0]->isa( 'Promise::Me' ) );
    my $type;
    $type = pop( @_ ) if( !ref( $_[-1] ) );
    my $prefix = '[' . ( $self->is_child ? 'child' : 'parent' ) . ']';
    foreach my $ref ( @_ )
    {
        my $tied = tied( $ref );
        if( defined( $self ) )
        {
            $self->message( 4, "${prefix} Checking if variable '$ref' is tied -> ", sub{ ( Scalar::Util::blessed( $tied ) ? 'Yes' : 'No' ) });
        }
        else
        {
            print( STDERR __PACKAGE__, "::unlock: Checking if variable '$ref' is tied -> ", ( Scalar::Util::blessed( $tied ) ? 'Yes' : 'No' ), "\n" ) if( $DEBUG >= 4 );
        }
        if( Scalar::Util::blessed( $tied ) &&
            $tied->isa( 'Promise::Me::Share' ) )
        {
            defined( $type ) ? $tied->unlock( $type ) : $tied->unlock;
        }
    }
    return( $self ) if( $self );
}

sub unshare
{
    my $self;
    $self = shift( @_ ) if( scalar( @_ ) && Scalar::Util::blessed( $_[0] ) && $_[0]->isa( 'Promise::Me' ) );
    my $pack = caller;
    $SHARED->{ $pack } = {} if( !CORE::exists( $SHARED->{ $pack } ) );
    my @removed = ();
    printf( STDERR "%s::unshare: Unsharing %d variables called from package '$pack'.\n", __PACKAGE__, scalar( @_ ) ) if( $DEBUG >= 3 );
    foreach my $ref ( @_ )
    {
        my $addr = Scalar::Util::refaddr( $ref );
        my $type = lc( ref( $ref ) );
        if( CORE::exists( $SHARED->{ $pack }->{ $addr } ) )
        {
            push( @removed, CORE::delete( $SHARED->{ $pack }->{ $addr } ) );
            next;
        }
        else
        {
            print( STDERR __PACKAGE__, "::unshare: Variable '$ref' of type '$type' could not be found in our registry.\n" ) if( $DEBUG >= 3 );
        }
    }
    return( scalar( @removed ) > 1 ? @removed : $removed[0] );
}

sub use_async { return( shift->_set_get_boolean( 'use_async', @_ ) ); }

sub wait
{
    my $self = shift( @_ );
    my @callinfo = caller;
    
    # $prom->wait(1)
    # $prom->wait(0)
    if( @_ )
    {
        $self->_set_get_boolean( 'wait', @_ );
    }
    # In chaining, without argument, we set this implicitly to true
    # $prom->then(sub{})->wait->catch(sub{})
    elsif( Want::want( 'OBJECT' ) )
    {
        $self->_set_get_boolean( 'wait', 1 );
    }
    elsif( Want::want( 'VOID' ) || Want::want( 'SCALAR' ) )
    {
        $self->_set_get_boolean( 'wait', 1 );
        $self->no_more_chaining(1);
        $self->exec;
    }
    else
    {
        return( $self->_set_get_boolean( 'wait' ) );
    }
    return( $self );
}

sub _browse
{
    my $self = shift( @_ );
    my $elem = shift( @_ );
    my $level = shift( @_ ) || 0;
    $self->message( 4, "Checking code '$elem'.\n--------" );
    $self->messagef( 4, "PPI element of class %s has children property '%s'.", $elem->class, $elem->{children} );
    return if( !$elem->children );
    foreach my $e ( $elem->elements )
    {
        printf( STDERR "%sElement: [%d] class %s, value '%s'\n", ( '.' x $level ), $e->line_number, $e->class, $e->content ) if( $DEBUG >= 4 );
        if( $e->can('children') && $e->children )
        {
            $self->_browse( $e, $level + 1 );
        }
    }
    $self->message( 4, "Done.\n--------" );
}

sub _parse
{
    my $self = shift( @_ );
    my $elem = shift( @_ );
    $self->_browse( $elem ) if( $self->debug );
    
    no warnings 'uninitialized';
    if( !Scalar::Util::blessed( $elem ) || !$elem->isa( 'PPI::Node' ) )
    {
        return( $self->_error( "Element provided to parse is not a PPI::Node object" ) );
    }
    
    # Check for PPI statements that would have caught some unrelated statements before
    my $sts = $elem->find(sub
    {
        my( $top, $this ) = @_;
        if( $this->class eq 'PPI::Statement' && substr( $this->content, 0, 5 ) ne 'async' )
        {
            $self->message( 4, "Checking for async keyword in this stateent '$this'" );
            my $found_async = $this->find_first(sub
            {
                my( $orig, $that ) = @_;
                return( $that->class eq 'PPI::Token::Word' && $that->content eq 'async' );
            });
        }
    });
    $sts ||= [];
    $self->messagef( 4, "Found %d statements containing an 'async' keyword.", scalar( @$sts ) );
    if( scalar( @$sts ) )
    {
        # We take everything from the 'async sub' up until the end of this statements and we move it to its own separate statement
        STATEMENT: foreach my $st ( @$sts )
        {
            my $temps = [];
            my $kids = [$st->children];
            for( my $i = 0; $i < scalar( @$kids ); $i++ )
            {
                my $e = $kids->[$i];
                if( $e->class eq 'PPI::Token::Word' &&
                    $e->content eq 'async' )
                {
                    if( $e->snext_sibling &&
                        $e->snext_sibling->class eq 'PPI::Token::Word' &&
                        $e->snext_sibling->content eq 'sub' )
                    {
                        push( @$temps, splice( @$kids, $i ) );
                        last;
                    }
                    else
                    {
                        require Carp;
                        Carp::croak( "You can only use async on a subroutine (including method) at line ", $e->line_number, "." );
                    }
                }
            }
            my $code = join( '', map( $_->content, @$temps ) );
            my $tmp  = PPI::Document->new( \$code, readonly => 1 ) || die( "Unable to parse: ", PPI::Document->errstr, "\n$code\n" );
            # PPI::Statement
            my $new = [$tmp->children]->[0];
            # Detach it from its current parent
            $new->remove;
            $_->delete for( @$temps );
            $st->__insert_after( $new ) || die( "Could not insert element of class '", $new->class, "' after former element of class '", $st->class, "'\n" );
        }
    }
    
    my $ref = $elem->find(sub
    {
        my( $top, $this ) = @_;
        return( $this->class eq 'PPI::Statement' && substr( $this->content, 0, 5 ) eq 'async' );
    });
    $ref ||= [];
    return( $self->_error( "Failed to find any async subroutines: $@" ) ) if( !defined( $ref ) );
    $self->messagef( 4, "Found %d match(es)", scalar( @$ref ) );
    return if( !scalar( @$ref ) );
    
    my $asyncs = [];
    foreach my $e ( @$ref )
    {
        $self->message( 4, "Checking '$e'" );
        if( $e->content !~ /^async[[:blank:]\h\v]+sub[[:blank:]\h\v]+/ )
        {
            require Carp;
            Carp::croak( "You can only use async on a subroutine (including method) at line ", $e->line_number, "." );
        }
        # Now, check if we do not have two consecutive async sub ... statements
        # $tmp_nodes will contains all the nodes from the start of the async to the end 
        # of the subroutine block.
        my $tmp_nodes = [];
        # We already know the first item is a valid async statement, so we state we are 
        # inside it and continue until we find a first block
        my $block_kids = [$e->children];
        my $prev_sib = $block_kids->[0];
        push( @$tmp_nodes, $prev_sib );
        my $to_remove = [];
        # The last element after which we insert the others
        my $last = $e;
        my $sib;
        # while( ( $sib = $prev_sib->next_sibling ) )
        # foreach my $sib ( @$block_kids )
        for( my $i = 1; $i < scalar( @$block_kids ); $i++ )
        {
            my $sib = $block_kids->[$i];
            $self->message( 4, "Checking sibling of class '", $sib->class, "' with value '$sib'." );
            if( scalar( @$tmp_nodes ) && $sib->class eq 'PPI::Structure::Block' )
            {
                $self->message( 3, "Ok, found the block: $sib" );
                push( @$tmp_nodes, $sib );
                my $code = join( '', map( $_->content, @$tmp_nodes ) );
                $self->message( 3, "Code collected is '$code'" );
                my $tmp  = PPI::Document->new( \$code, readonly => 1 ) || die( "Unable to parse: ", PPI::Document->errstr, "\n$code\n" );
                # PPI::Statement
                my $new = [$tmp->children]->[0];
                # Detach it from its current parent
                $new->remove;
                # Can insert another structure or another token
                $self->message( 4, "Inserting new code of class '", $new->class, "' after the old block of class '", $sib->class, "' who has a parent '", $sib->parent->class, "'." );
                $last->__insert_after( $new ) || die( "Could not insert element of class '", $new->class, "' after former element of class '", $sib->class, "'\n" );
                push( @$to_remove, @$tmp_nodes );
                # $prev_sib = $sib;
                $last = $new;
                push( @$asyncs, $new );
                $tmp_nodes = [];
                $self->message( 3, "New overal code so far is '$elem'" );
                # next;
            }
            elsif( !scalar( @$tmp_nodes ) && 
                   $sib->class eq 'PPI::Token::Word' &&
                   $sib->content eq 'async' )
            {
                $self->message( 4, "Found keyword 'async'." );
                if( $sib->snext_sibling && 
                    $sib->snext_sibling->class eq 'PPI::Token::Word' &&
                    $sib->snext_sibling->content eq 'sub' )
                {
                    push( @$tmp_nodes, $sib );
                }
                else
                {
                    require Carp;
                    Carp::croak( "You can only use async on a subroutine (including method) at line ", $sib->line_number, "." );
                }
            }
            elsif( scalar( @$tmp_nodes ) )
            {
                $self->message( 4, "\tAdding '$sib' to the buffer." );
                push( @$tmp_nodes, $sib );
            }
            else
            {
                $self->message( 4, "\tAdding '$sib' after the last inserted element '$last'" );
                $sib->remove;
                $last->__insert_after( $sib );
                $last = $sib;
            }
            $prev_sib = $sib;
        }
        # Remove what needs to be removed
        $_->delete for( @$to_remove );
        $self->message( 4, "After removal, overall code is now: '$elem'." );
    }
    foreach my $e ( @$asyncs )
    {
        my @kids  = $e->children;
        my $async = $kids[0];
        my $sub   = $async->snext_sibling;
        my $name  = $sub->snext_sibling;
        my $block = $e->find_first( 'PPI::Structure::Block' );
        my $nl_braces = {};
        my $this = $block;
        my $before = '';
        while( ( $this = $this->previous_sibling ) &&  $this->class eq 'PPI::Token::Whitespace' )
        {
            $before .= $this->content;
        }
        $self->message( 3, "Space before opening block is '$before'." );
        # We do not care about spaces after the block, because our element $e being 
        # processed only contains elements up to the closing brace. So whatever there is
        # after is not our concern.
        $nl_braces->{open_before} = () = $before =~ /(\v)/g;
        my $open_spacer = ( "\n" x $nl_braces->{open_before} );
        $self->message( 3, "$nl_braces->{open_before} new line(s) before opening brace." );
        
        $self->message( 3, "Found async '$async' and sub keyword '$sub' with name '$name' and block '$block'." );
        my $code  = qq{sub $name ${open_spacer}{ Promise::Me::async($name => sub $block, args => [\@_], use_async => 1); }};
        my $doc = PPI::Document->new( \$code, readonly => 1 ) || die( "Unable to parse: ", PPI::Document->errstr, "\n$code\n" );
        my $new = [$doc->children]->[0];
        # Need to detach it first from its current parent before we can re-allocate it
        $new->remove;
        $self->message( 3, "New code is of class '", $new->class, "' -> $new" );
        $e->replace( $new );
        $self->message( 3, "New code is now '$elem'." );
    }
    return( $elem );
}

sub _reject_resolve
{
    my $self = shift( @_ );
    my $what = shift( @_ );
    my $shm = $self->shared_mem;
    if( @_ )
    {
        my $val = shift( @_ );
        if( $shm )
        {
            my $hash = $shm->read;
            $hash = {} if( ref( $hash ) ne 'HASH' );
            $hash->{ $what } = $val;
            my $rv = $shm->write( $hash );
            return( $self->error( "Unable to write data to shared space using object (", overload::StrVal( $shm ), ")" ) ) if( !defined( $rv ) );
        }
        else
        {
            warnings::warn( "Shared space object not set or lost!\n" ) if( warnings::enabled() );
        }
        $self->_set_get_boolean( $what, $val );
    }
    else
    {
        my $hash = $shm->read;
        return( $hash ) unless( ref( $hash ) );
        $self->{shared} = $hash;
        return( $hash->{ $what } );
    }
    return( $self->_set_get_boolean( $what ) );
}

sub _set_exit_values
{
    my $self = shift( @_ );
    my $bit  = shift( @_ );
    $self->exit_status( ( $bit >> 8 ) );
    $self->exit_bit( $bit );
    $self->exit_signal( ( $bit & 127 ) );
    $self->has_coredump( ( $bit & 128 ) );
    return( $self );
}

sub _set_get_mem_size
{
    my $self  = shift( @_ );
    my $field = shift( @_ );
    if( @_ )
    {
        my $val = shift( @_ );
        if( CORE::defined( $val ) && CORE::length( $val ) )
        {
            my $map =
            {
            K => 1024,
            M => ( 1024 ** 2 ),
            G => ( 1024 ** 3 ),
            T => ( 1024 ** 4 ),
            };
            if( CORE::exists( $map->{ substr( $val, -1, 1 ) } ) )
            {
                $val = substr( $val, 0, length( $val ) - 1 ) * $map->{ substr( $val, -1, 1 ) };
            }
        }
        $self->_set_get_scalar( $field, int( $val ) );
    }
    return( $self->_set_get_scalar( $field, @_ ) );
}

sub _share_vars
{
    my $vars = shift( @_ );
    my $opts = {};
    $opts    = pop( @_ ) if( scalar( @_ ) && ref( $_[-1] ) eq 'HASH' );
    # Nothing to do
    return if( !scalar( @$vars ) );
    $opts->{use_cache_file} = ( $SHARE_MEDIUM eq 'file' );
    $opts->{fallback} = $SHARE_FALLBACK if( !CORE::exists( $opts->{fallback} ) || !CORE::length( $opts->{fallback} ) );
    
    my( $shm, $data );
    # By process id
    my $index = $$;
    unless( ref( $SHARED->{ $index } ) eq 'HASH' )
    {
        $SHARED->{ $index } = {};
    }
    
    if( scalar( keys( %{$SHARED->{ $index }} ) ) )
    {
        print( STDERR __PACKAGE__, "::_share_vars: Re-using already shared variables.\n" ) if( $DEBUG >= 4 );
        my $first = [keys( %{$SHARED->{ $index }} )]->[0];
        my $ref   = $SHARED->{ $index }->{ $first };
        my $type  = lc( ref( $ref ) );
        my $tied  = tied( $type eq 'array' ? @$ref : $type eq 'hash' ? %$ref : $$ref );
        unless( Scalar::Util::blessed( $tied ) && $tied->isa( 'Promise::Me::Share' ) )
        {
            die( "Weirdly enough, the tied object found for an already shared variable ($ref) seems to be gone!\n" );
        }
        $shm = $tied->shared;
        $data = $shm->read;
    }
    else
    {
        my $key = 'gl' . $$;
        print( STDERR __PACKAGE__, "::_share_vars: Initiating shared memory with key '$key'.\n" ) if( $DEBUG >= 4 );
        my $p =
        {
        create  => 1,
        # destroy => $SHARE_AUTO_DESTROY,
        # Actually, we need to control when to remove the shared memory space, and
        # this needs to happen when this module ends
        destroy => 0,
        key     => $key,
        mode    => 0666,
        storable => 1,
        };
        my $size = $SHARED_MEMORY_SIZE;
        $p->{size} = $size if( CORE::length( $size ) && int( $size ) > 0 );
        if( Module::Generic::SharedMem->supported && !$opts->{use_cache_file} )
        {
            my $s = Module::Generic::SharedMem->new( %$p ) || return( __PACKAGE__->error( "Unable to create shared memory object: ", Module::Generic::SharedMem->error ) );
            $shm = $s->open;
            if( !$shm )
            {
                if( $opts->{fallback} )
                {
                    my $c = Module::Generic::File::Cache->new( %$p ) ||
                        return( __PACKAGE__->error( "Unable to create a shared cache file or a shared memory: ", Module::Generic::File::Cache->error ) );
                }
                else
                {
                    return( __PACKAGE__->error( "Unable to open shared memory object: ", $s->error ) );
                }
            }
            else
            {
                $shm->attach;
            }
        }
        else
        {
            my $c = Module::Generic::File::Cache->new( %$p ) ||
                return( __PACKAGE__->error( "Unable to create a shared cache file: ", Module::Generic::File::Cache->error ) );
            $shm = $c->open || return( __PACKAGE__->error( "Unable to create a shared cache file: ", $c->error ) );
        }
        $data = {};
    }
    print( STDERR __PACKAGE__, "::_share_vars: Shared object is '$shm' and id is '", $shm->id, "'.\n" ) if( $DEBUG >= 4 );
    
    printf( STDERR "%s::_share_vars: Processing %d variables.\n", __PACKAGE__, scalar( @$vars ) ) if( $DEBUG >= 4 );
    my @objects = ();
    foreach my $ref ( @$vars )
    {
        my $type = lc( ref( $ref ) );
        if( $type !~ /^(array|hash|scalar)$/ )
        {
            warnings::warn( "Unsupported variable type '$type': '$ref'\n" ) if( warnings::enabled() || $DEBUG );
            next;
        }
        my $addr = Scalar::Util::refaddr( $ref );
        print( STDERR __PACKAGE__, "::_share_vars: Processing variable '$ref' with address '$addr'\n" ) if( $DEBUG >= 4 );
        my $pref =
        {
        addr    => $addr,
        # debug   => $self->debug,
        debug   => 7,
        shm     => $shm,
        # value   => $ref,
        };
        
        my $clone = Clone::clone( $ref );
        my $tied;
        if( $type eq 'array' )
        {
            $tied = tie( @$ref, 'Promise::Me::Share', $pref );
        }
        elsif( $type eq 'hash' )
        {
            $tied = tie( %$ref, 'Promise::Me::Share', $pref );
        }
        elsif( $type eq 'scalar' )
        {
            $tied = tie( $$ref, 'Promise::Me::Share', $pref );
        }

        CORE::defined( $tied ) || do
        {
            warnings::warn( "Unable to tie reference variable '$ref': $!\n" ) if( warnings::enabled() || $DEBUG );
            next;
        };
        $data->{ $addr } = $clone;
        push( @objects, $tied );
        $SHARED->{ $index }->{ $addr } = $ref;
    }
    print( STDERR __PACKAGE__, "::_share_vars: Saving data to shared memory.\n" ) if( $DEBUG >= 6 );
    $shm->lock( LOCK_EX );
    $shm->write( $data );
    $shm->unlock;
    print( STDERR __PACKAGE__, "::_share_vars: Done.\n" ) if( $DEBUG >= 6 );
    return( scalar( @objects ) > 1 ? @objects : $objects[0] );
}

# Used to create a shared space for processes to share result
sub _set_shared_space
{
    my $self = shift( @_ );
    my $key  = $self->{shared_key} ||
        return( $self->error( "No shared key found!" ) );
    my $p =
    {
        create  => 1,
        key     => $key,
        mode    => 0666,
        # debug   => $self->debug,
        storable => 1,
    };
    my $size = $self->result_shared_mem_size;
    $p->{size} = $size if( CORE::length( $size ) && int( $size ) > 0 );
    # If we are the child we do not destroy the shared memory, otherwise our parent 
    # would not have time to access the data we will have stored there. We just remove 
    # our semaphore
    if( $self->is_child )
    {
        $p->{destroy_semaphore} = 0;
    }
    
    my $shm;
    if( Module::Generic::SharedMem->supported && !$self->{use_cache_file} )
    {
        my $s = Module::Generic::SharedMem->new( %$p ) || return( $self->error( "Unable to create shared memory object: ", Module::Generic::SharedMem->error ) );
        $shm = $s->open;
        
        if( !$shm )
        {
            if( $s->error->message =~ /No[[:blank:]\h]+space[[:blank:]\h]+left/i )
            {
                my $s = Module::Generic::File::Cache->new( %$p ) || return( $self->error( "Unable to create shared cache file object: ", Module::Generic::File::Cache->error ) );
                $shm = $s->open ||
                    return( $self->error( "Unable to open shared cache file object: ", $s->error ) );
            }
            else
            {
                return( $self->error( "Unable to open shared memory object: ", $s->error ) );
            }
        }
        else
        {
            $shm->attach;
        }
    }
    else
    {
        my $s = Module::Generic::File::Cache->new( %$p ) || return( $self->error( "Unable to create shared cache file object: ", Module::Generic::File::Cache->error ) );
        $shm = $s->open ||
            return( $self->error( "Unable to open shared cache file object: ", $s->error ) );
    }
    $self->shared_mem( $shm );
    
    if( $self->is_parent )
    {
        $shm->reset( {} );
    }
    return( $shm );
}

sub DESTROY
{
    my $self = shift( @_ );
    my $child = $self->child;
    my $status = $self->exit_status;
    my $shm = $self->shared_mem;
    my $destroy = $self->shared_space_destroy;
    # If there is a child associated and it has exited and we still have a shared space 
    # object, then remove that shared space
    if( $destroy && $child && CORE::length( $status ) && $shm )
    {
        $shm->remove;
        my $addr = Scalar::Util::refaddr( $self );
        for( my $i = 0; $i < $#$OBJECTS_REPO; $i++ )
        {
            if( Scalar::Util::refaddr( $OBJECTS_REPO->[$i] ) eq $addr )
            {
                CORE::splice( @$OBJECTS_REPO, $i, 1 );
                last;
            }
        }
    }
};

# NOTE: END
END
{
    # Only the objects, which are initiated in the parent process are in here.
    for( my $i = 0; $i < $#$OBJECTS_REPO; $i++ )
    {
        my $o = $OBJECTS_REPO->[$i];
        # END block called by child process typically
        my $pid = $o->pid;
        next if( $pid ne $$ );
        my $shm;
        if( $o->shared_space_destroy && ( $shm = $o->shared_mem ) )
        {
            $shm->remove;
        }
        next if( !CORE::exists( $SHARED->{ $pid } ) );
        my $rv = kill( $pid, 0 );
        print( STDERR __PACKAGE__, "::END: [$$] Checking pid $pid -> ", ( $rv ? 'alive' : 'exited' ), "\n" ) if( $DEBUG >= 4 );
        my $first = [keys( %{$SHARED->{ $pid }} )]->[0];
        my $ref   = $SHARED->{ $pid }->{ $first };
        my $type  = lc( ref( $ref ) );
        my $tied  = tied( $type eq 'array' ? @$ref : $type eq 'hash' ? %$ref : $$ref );
        unless( Scalar::Util::blessed( $tied ) && $tied->isa( 'Promise::Me::Share' ) )
        {
            next;
        }
        $shm = $tied->shared;
        next if( !$shm );
        $shm->remove;
        CORE::delete( $SHARED->{ $pid } );
    }
};

# NOTE: PPI::Element class, modifying PPI::Element::replace to be more permissive
{
    package
        PPI::Element;
    
    no warnings 'redefine';
    sub replace {
        my $self    = ref $_[0] ? shift : return undef;
        # If our object and the other are not of the same class, PPI refuses to replace 
        # to avoid damages to perl code
        # my $other = _INSTANCE(shift, ref $self) or return undef;
        my $other = shift;
        # die "The ->replace method has not yet been implemented";
        $self->parent->__replace_child( $self, $other );
        1;
    }
}

# NOTE: Promise::Me::Exception
package
    Promise::Me::Exception;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Module::Generic::Exception );
    our $VERSION = 'v0.1.0';
};

# NOTE: Promise::Me::Share class
package
    Promise::Me::Share;
BEGIN
{
    use strict;
    use warnings;
    use warnings::register;
    use parent qw( Module::Generic );
    use vars qw( $DEBUG $VERSION );
    use Module::Generic::SharedMem qw( :all );
    use constant SHMEM_SIZE => 65536;
    our $DEBUG = $Promise::Me::DEBUG;
    our $VERSION = 'v0.1.0';
};

sub TIEARRAY
{
    my $class = shift( @_ );
    my $opts  = $class->_get_args_as_hash( @_ );
    $opts->{type} = 'array';
    my $self = $class->_tie( $opts ) || do
    {
        print( STDERR __PACKAGE__, "::TIEARRAY: Failed to create object with given options.\n" ) if( $DEBUG );
        warn( "Failed to create object with given options.\n" );
        return;
    };
    return( $self );
}

sub TIEHASH
{
    my $class = shift( @_ );
    my $opts  = $class->_get_args_as_hash( @_ );
    $opts->{type} = 'hash';
    my $self = $class->_tie( $opts ) || do
    {
        print( STDERR __PACKAGE__, "::TIEHASH: Failed to create object with given options.\n" ) if( $DEBUG );
        warn( "Failed to create object with given options.\n" );
        return;
    };
    return( $self );
}

sub TIESCALAR
{
    my $class = shift( @_ );
    my $opts  = $class->_get_args_as_hash( @_ );
    $opts->{type} = 'scalar';
    my $self = $class->_tie( $opts ) || do
    {
        print( STDERR __PACKAGE__, "::TIESCALAR: Failed to create object with given options.\n" ) if( $DEBUG );
        warn( "Failed to create object with given options.\n" );
        return;
    };
    return( $self );
}

sub CLEAR
{
    my $self = shift( @_ );
    my $locked = $self->locked;
    if( $self->{type} eq 'array' )
    {
        $self->{data} = [];
    }
    elsif( $self->{type} eq 'hash' )
    {
        $self->{data} = {};
    }
    elsif( $self->{type} eq 'scalar' )
    {
        $$self->{data} = \'';
    }
    
    if( $locked & LOCK_EX )
    {
        $self->{_changed}++;
    }
    else
    {
        $self->unload( $self->{data} ) || return( $self->pass_error );
    }
    return( 1 );
}

sub DELETE
{
    my $self = shift( @_ );
    my $key  = shift( @_ );
    my $locked = $self->locked;
    unless( $locked )
    {
        $self->{data} = $self->load || return( $self->pass_error );
    }
    my $val;
    if( $self->{type} eq 'array' )
    {
        $val = CORE::delete( $self->{data}->[ $key ] );
    }
    elsif( $self->{type} eq 'hash' )
    {
        $val = CORE::delete( $self->{data}->{ $key } );
    }
    
    if( $locked & LOCK_EX )
    {
        $self->{_changed}++;
    }
    else
    {
        $self->unload( $self->{data} ) || return( $self->pass_error );
    }
    return( $val );
}

sub EXISTS
{
    my $self = shift( @_ );
    my $key  = shift( @_ );
    my $locked = $self->locked;
    unless( $locked )
    {
        $self->{data} = $self->load || return( $self->pass_error );
    }
    if( $self->{type} eq 'array' )
    {
        return( CORE::exists( $self->{data}->[ $key ] ) );
    }
    elsif( $self->{type} eq 'hash' )
    {
        return( CORE::exists( $self->{data}->{ $key } ) );
    }
}

sub EXTEND { }

sub FETCH
{
    my $self = shift( @_ );
    if( caller eq __PACKAGE__ )
    {
        die( "I am called from within my own package\n" );
    }
    my $locked = $self->locked;
    my $data;
    if( $locked || $self->{_iterating} )
    {
        $data = $self->{data};
        $self->{_iterating} = '';
    }
    else
    {
        $data = $self->load || return( $self->pass_error );
    }
    
    my $val;
    if( $self->{type} eq 'array' )
    {
        my $key = shift( @_ );
        $val = $data->[$key];
    }
    elsif( $self->{type} eq 'hash' )
    {
        my $key = shift( @_ );
        $val = $data->{ $key };
    }
    elsif( $self->{type} eq 'scalar' )
    {
        $val = $$data;
    }
    return( $val );
}

sub FETCHSIZE
{
    my $self = shift( @_ );
    my $locked = $self->locked;
    unless( $locked )
    {
        $self->{data} = $self->load || return( $self->pass_error );
    }
    if( $self->{type} eq 'array' )
    {
        return( scalar( @{$self->{data}} ) );
    }
    elsif( $self->{type} eq 'hash' )
    {
        return( scalar( keys( %{$self->{data}} ) ) );
    }
    elsif( $self->{type} eq 'scalar' )
    {
        return( length( ${$self->{data}} ) );
    }
}

sub FIRSTKEY
{
    my $self = shift( @_ );
    my $locked = $self->locked;
    unless( $locked )
    {
        $self->{data} = $self->load || return( $self->pass_error );
    }
    my $reset = keys( %{$self->{data}} );
    my $first = each( %{$self->{data}} );
    $self->{_iterating} = 1;
    return( $first );
}

sub NEXTKEY
{
    my $self = shift( @_ );
    my $next = each( %{$self->{data}} );
    if( !defined( $next ) )
    {
        $self->{_iterating} = 0;
        return;
    }
    else
    {
        $self->{_iterating} = 1;
        return( $next );
    }
}

sub POP
{
    my $self = shift( @_ );
    my $locked = $self->locked;
    unless( $locked )
    {
        $self->{data} = $self->load || return( $self->pass_error );
    }
    my $val = pop( @{$self->{data}} );
    if( $locked & LOCK_EX )
    {
        $self->{_changed}++;
    }
    else
    {
        $self->unload( $self->{data} ) || return( $self->pass_error );
    }
    return( $val );
}

sub PUSH
{
    my $self = shift( @_ );
    my $locked = $self->locked;
    unless( $locked )
    {
        $self->{data} = $self->load || return( $self->pass_error );
    }
    push( @{$self->{data}}, @_ );
    if( $locked & LOCK_EX )
    {
        $self->{_changed}++;
    }
    else
    {
        $self->unload( $self->{data} ) || return( $self->pass_error );
    }
}

sub SCALAR
{
    my $self = shift( @_ );
    my $locked = $self->locked;
    unless( $locked )
    {
        $self->{data} = $self->load || return( $self->pass_error );
    }
    if( $self->{type} eq 'hash' )
    {
        return( scalar( keys( %{$self->{data}} ) ) );
    }
}

sub SHIFT
{
    my $self = shift( @_ );
    my $locked = $self->locked;
    unless( $locked )
    {
        $self->{data} = $self->load || return( $self->pass_error );
    }
    my $val = shift( @{$self->{data}} );
    if( $locked & LOCK_EX )
    {
        $self->{_changed}++;
    }
    else
    {
        $self->load( $self->{data} ) || return( $self->pass_error );
    }
    return( $val );
}

sub SPLICE
{
    my $self = shift( @_ );
    my( $offset, $length, @vals ) = @_;
    my $locked = $self->locked;
    unless( $locked )
    {
        $self->{data} = $self->load || return( $self->pass_error );
    }
    my @values = splice( @{$self->{data}}, $offset, $length, @vals );
    if( $locked & LOCK_EX )
    {
        $self->{_changed}++;
    }
    else
    {
        $self->unload( $self->{data} ) || return( $self->pass_error );
    }
    return( @values );
}

sub STORE
{
    my $self = shift( @_ );
    my $locked = $self->locked;
    unless( $locked )
    {
        $self->{data} = $self->load || return( $self->pass_error );
    }
    
    if( $self->{type} eq 'array' )
    {
        my( $key, $val ) = @_;
        $self->{data}->[$key] = $val;
    }
    elsif( $self->{type} eq 'hash' )
    {
        my( $key, $val ) = @_;
        $self->{data}->{ $key } = $val;
    }
    elsif( $self->{type} eq 'scalar' )
    {
        my $val = shift( @_ );
        $self->{data} = \$val;
    }
    
    if( $locked & LOCK_EX )
    {
        $self->{_changed}++;
    }
    else
    {
        $self->unload( $self->{data} ) || return( $self->pass_error );
    }
    return( 1 );
}

sub STORESIZE
{
    my $self = shift( @_ );
    my $len  = shift( @_ );
    my $locked = $self->locked;
    unless( $locked )
    {
        $self->{data} = $self->load || return( $self->pass_error );
    }
    $#{$self->{data}} = $len - 1;
    if( $locked & LOCK_EX )
    {
        $self->{_changed}++;
    }
    else
    {
        $self->unload( $self->{data} ) || return( $self->pass_error );
    }
    return( $len );
}

sub UNSHIFT
{
    my $self = shift( @_ );
    my $locked = $self->locked;
    unless( $locked )
    {
        $self->{data} = $self->load || return( $self->pass_error );
    }
    my $val = unshift( @{$self->{data}}, @_ );
    if( $locked & LOCK_EX )
    {
        $self->{_changed}++;
    }
    else
    {
        $self->unload( $self->{data} ) || return( $self->pass_error );
    }
    return( $val );
}

sub UNTIE
{
    my $self = shift( @_ );
}

sub addr { return( shift->{addr} ); }

sub load
{
    my $self = shift( @_ );
    my @info = caller;
    my $sub  = [caller(1)]->[3];
    my $sh   = $self->shared ||
        return( $self->error( "No shared memory object found." ) );
    my $repo = $sh->read;
    my $addr = $self->addr || return( $self->error( "No variable address found!" ) );
    my $data = $repo->{ $addr };
    if( my $obj = tied( $self->{type} eq 'array' ? @$data : $self->{type} eq 'hash' ? @$data : $$data ) )
    {
        die( "Data received ($data) is tied to class '", ref( $obj ), "'!\n" );
    }
    
    if( !ref( $data ) )
    {
        warn( "Shared memory block with id '", $sh->id, "' -> addr '$addr' does not contain a reference: '$data' (called from package $info[0] in file $info[1] at line $info[2] from subroutine $sub)\n" );
    }
    elsif( lc( ref( $data ) ) ne $self->{type} )
    {
        warn( "Data retrieved from shared memory with id '", $sh->id, "' -> addr '$addr' is expected to contain a reference of type '$self->{type}', but instead contains a reference of type '", lc( ref( $data ) ), "' (called from package $info[0] in file $info[1] at line $info[2] from subroutine $sub)\n" );
    }
    return( $data );
}

sub lock
{
    my $self = shift( @_ );
    my $sh   = $self->shared ||
        return( $self->error( "No shared memory object found." ) );
    my $repo = $sh->read;
    my $addr = $self->addr || return( $self->error( "No variable address found!" ) );
    $repo->{_lock} = {} if( !CORE::exists( $repo->{_lock} ) || ref( $repo->{_lock} ) ne 'HASH' );
    if( CORE::exists( $repo->{_lock}->{ $addr } ) )
    {
        warnings::warn( "Variable '", $self->{value}, "' with address '$self->{addr}' is already locked by process (", $repo->{_lock}->{ $addr }, "). Is it us? ", ( $repo->{_lock}->{ $addr } == $$ ? 'Yes' : 'No' ), "\n" ) if( warnings::enabled() || $DEBUG );
        return( $self );
    }
    $repo->{_lock}->{ $addr } = $$;
    $sh->write( $repo );
    return( $self );
}

sub locked
{
    my $self = shift( @_ );
    my $sh   = $self->shared ||
        return( $self->error( "No shared memory object found." ) );
    my $repo = $sh->read;
    my $addr = $self->addr || return( $self->error( "No variable address found!" ) );
    $repo->{_lock} = {} if( !CORE::exists( $repo->{_lock} ) || ref( $repo->{_lock} ) ne 'HASH' );
    return( CORE::exists( $repo->{_lock}->{ $addr } ) );
}

sub remove
{
    my $self = shift( @_ );
    my $sh   = $self->shared ||
        return( $self->error( "No shared memory object found." ) );
    my $repo = $sh->read;
    my $addr = $self->addr || return( $self->error( "No variable address found!" ) );
    CORE::delete( $repo->{ $addr } );
    $sh->write( $repo );
    return( $self );
}

# sub shared { return( shift->_set_get_scalar( 'shared', @_ ) ); }
sub shared { return( shift->{shared} ); }

sub unload
{
    my $self = shift( @_ );
    my $sh   = $self->shared ||
        return( $self->error( "No shared memory object found." ) );
    my $data = shift( @_ );
    my $addr = $self->addr || return( $self->error( "No variable address found!" ) );
    my $repo = $sh->read;
    $repo->{ $addr } = $data;
    $sh->write( $repo ) || return( $self->error( "Unable to write to shared memory block: ", $sh->error ) );
    return( $self );
}

sub unlock
{
    my $self = shift( @_ );
    my $sh   = $self->shared ||
        return( $self->error( "No shared memory object found." ) );
    my $repo = $sh->read;
    my $addr = $self->addr || return( $self->error( "No variable address found!" ) );
    if( $repo->{_lock}->{ $addr } != $$ )
    {
        return( $self->error( "Unable to remove the lock. This process ($$) is not the owner of the lock (", $repo->{_lock}->{ $addr }, ")." ) );
    }
    
    # Credits to IPC::Shareable for the idea
    if( $self->{_changed} )
    {
        $repo->{ $addr } = $self->{data};
        $self->{_changed} = 0;
    }
    CORE::delete( $repo->{_lock}->{ $addr } );
    $sh->write( $repo ) ||
        return( $self->error( "Unable to write to shared memory: ", $sh->error ) );
    return( $self );
}

sub _tie
{
    my $class = shift( @_ );
    my $opts  = $class->_get_args_as_hash( @_ );
    return( $class->error( "No shared memory object provided." ) ) if( !CORE::exists( $opts->{shm} ) || !CORE::length( $opts->{shm} ) || !Scalar::Util::blessed( $opts->{shm} ) );
    return( $class->error( "No data type was provided for shared memory tie." ) ) if( !CORE::length( $opts->{type} ) || !CORE::length( $opts->{type} ) );
    return( $class->error( "Data type '$opts->{type}' is unsupported." ) ) if( $opts->{type} !~ /^(array|hash|scalar)$/i );
#     if( !CORE::length( $opts->{type} ) && CORE::length( $opts->{value} ) )
#     {
#         return( $class->error( "Value provided ($opts->{value}) is not a reference!" ) ) if( !ref( $opts->{value} ) );
#         $opts->{type} = ref( $opts->{value} );
#     }
    $opts->{type} = lc( $opts->{type} );
    my $hash =
    {
    # addr    => Scalar::Util::refaddr( $opts->{value} ),
    addr    => $opts->{addr},
    debug   => ( $opts->{debug} // 0 ),
    shared  => $opts->{shm},
    type    => $opts->{type},
    };
    my $self = bless( $hash => ( ref( $class ) || $class ) );
    # $self->message( 3, "Options provided are: ", sub{ $self->dump( $opts ) });
    
    if( $opts->{type} eq 'scalar' )
    {
        $self->{data} = \'';
    }
    elsif( $opts->{type} eq 'array' )
    {
        $self->{data} = [];
    }
    elsif( $opts->{type} eq 'hash' )
    {
        $self->{data} = {};
    }
    return( $self );
}

sub DESTROY
{
    my $self = shift( @_ );
    my @info = caller();
    print( STDERR __PACKAGE__, "::DESTROY: called from package '$info[0]' in file '$info[1]' at line $info[2]\n" ) if( $DEBUG );
};

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

Promise::Me - Fork Based Promise with Asynchronous Execution, Async, Await and Shared Data

=head1 SYNOPSIS

    use Promise::Me; # exports async, await and share
    my $p = Promise::Me->new(sub
    {
        # Some regular code here
    })->then(sub
    {
        my $res = shift( @_ ); # return value from the code executed above
        # more processing...
    })->then(sub
    {
        my $more = shift( @_ ); # return value from the previous then
        # more processing...
    })->catch(sub
    {
        my $exception = shift( @_ ); # error that occured is caught here
    })->finally(sub
    {
        # final processing
    })->then(sub
    {
        # A last then may be added after finally
    };

    # You can share data among processes for all systems, including Windows
    my $data : shared = {};
    my( $name, %attributes, @options );
    share( $name, %attributes, @options );

    my $p1 = Promise::Me->new( $code_ref )->then(sub
    {
        my $res = shift( @_ );
        # more processing...
    })->catch(sub
    {
        my $err = shift( @_ );
        # Do something with the exception
    });

    my $p2 = Promise::Me->new( $code_ref )->then(sub
    {
        my $res = shift( @_ );
        # more processing...
    })->catch(sub
    {
        my $err = shift( @_ );
        # Do something with the exception
    });

    my @results = await( $p1, $p2 );

    # Wait for all promise to resolve. If one is rejected, this super promise is rejected
    my @results = Promise::Me->all( $p1, $p2 );

    # First promise that is resolved or rejected makes this super promise resolved and 
    # return the result
    my @results = Promise::Me->race( $p1, $p2 );

    # Automatically turns this subroutine into one that runs asynchronously and returns 
    # a promise
    async sub fetch_remote
    {
        # Do some http request that will run asynchronously thanks to 'async'
    }

    sub do_something
    {
        # some code here
        my $p = Promise::Me->new(sub
        {
            # some work that needs to run asynchronously
        })->then(sub
        {
            # More processing here
        })->catch(sub
        {
            # Oops something went wrong
            my $exception = shift( @_ );
        });
        # No need for this subroutine 'do_something' to be prefixed with 'async'.
        # This is not JavaScript you know
        await $p;
    }

    sub do_something
    {
        # some code here
        my $p = Promise::Me->new(sub
        {
            # some work that needs to run asynchronously
        })->then(sub
        {
            # More processing here
        })->catch(sub
        {
            # Oops something went wrong
            my $exception = shift( @_ );
        })->wait;
        # Always returns a reference
        my $result = $p->result;
    }

=head1 VERSION

    v0.2.1

=head1 DESCRIPTION

L<Promise::Me> is an implementation of the JavaScript promise using fork for asynchronous tasks. Fork is great, because it is well supported by all operating systems (L<except AmigaOS, RISC OS and VMS|perlport>) and effectively allows for asynchronous execution.

While JavaScript has asynchronous execution at its core, which means that two consecutive lines of code will execute simultaneously, under perl, those two lines would be executed one after the other. For example:

    # Assuming the function getRemote makes an http query of a remote resource that takes time
    let response = getRemote('https://example.com/api');
    console.log(response);

Under JavaScript, this would yield: C<undefined>, but in perl

    my $resp = $ua->get('https://example.com/api');
    say( $resp );

Would correctly return the response object, but it will hang until it gets the returned object whereas in JavaScript, it would not wait.

In JavaScript, because of this asynchronous execution, before people were using callback hooks, which resulted in "callback from hell", i.e. something like this[1]:

    getData(function(x){
        getMoreData(x, function(y){
            getMoreData(y, function(z){ 
                ...
            });
        });
    });

[1] Taken from this L<StackOverflow discussion|https://stackoverflow.com/questions/25098066/what-is-callback-hell-and-how-and-why-does-rx-solve-it>

And then, they came up with L<Promise|https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Promise>, so that instead of wrapping your code in a callback function you get instead a promise object that gets called when certain events get triggered, like so[2]:

    const myPromise = new Promise((resolve, reject) => {
      setTimeout(() => {
        resolve('foo');
      }, 300);
    });

    myPromise
      .then(handleResolvedA, handleRejectedA)
      .then(handleResolvedB, handleRejectedB)
      .then(handleResolvedC, handleRejectedC);

[2] Taken from L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Promise>

Chaining is easy to implement in perl and L<Promise::Me> does it too. Where it gets more tricky is returning a promise immediately without waiting for further execution, i.e. a deferred promise, like the following in JavaScript:

    function getRemote(url)
    {
        let promise = new Promise((resolve, reject) => 
        {
            setTimeout(() => reject(new Error("Whoops!")), 1000);
        });
        // Maybe do some other stuff here
        return( promise );
    }

In this example, under JavaScript, the C<promise> will be returned immediately. However, under perl, the equivalent code would be executed sequentially. For example, using the excellent module L<Promise::ES6>:

    sub get_remote
    {
        my $url = shift( @_ );
        my $p = Promise::ES6->new(sub($res)
        {
            $res->( Promise::ES6->resolve(123) );
        });
        # Do some more work that would take some time
        return( $p );
    }

In the example above, the promise C<$p> would not be returned until all the tasks are completed before the C<return> statement, contrary to JavaScript where it would be returned immediately.

So, in perl people have started to use loop such as L<AnyEvent> or L<IO::Async> with "conditional variable" to get that asynchronous execution, but you need to use loops. For example (taken from L<Promise::AsyncAwait>):

    use Promise::AsyncAwait;
    use Promise::XS;

    sub delay {
        my $secs = shift;

        my $d = Promise::XS::deferred();

        my $timer; $timer = AnyEvent->timer(
            after => $secs,
            cb => sub {
                undef $timer;
                $d->resolve($secs);
            },
        );

        return $d->promise();
    }

    async sub wait_plus_1 {
        my $num = await delay(0.01);

        return 1 + $num;
    }

    my $cv = AnyEvent->condvar();
    wait_plus_1()->then($cv, sub { $cv->croak(@_) });

    my ($got) = $cv->recv();

So, in the midst of this, I have tried to provide something without event loop by using fork instead as exemplified in the L</SYNOPSIS>

For a framework to do asynchronous tasks, you might also be interested in L<Coro>, from L<Marc A. Lehmann|https://metacpan.org/author/MLEHMANN> original author of L<AnyEvent> event loop.

=head1 METHODS

=head2 new

    my $p = Promise::Me->new(sub
    {
        # some code to run asynchronously
    });

    # or
    my $p = Promise::Me->new(sub
    {
        # some code to run asynchronously
    }, { debug => 4, result_shared_mem_size => 2097152, timeout => 2 });

Instantiate a new C<Promise::Me> object.

It takes a code reference such as an anonymous subroutine or a reference to a subroutine, and optionally an hash reference of options.

The options supported are:

=over 4

=item I<debug> integer

Sets the debug level. This can be quite verbose and will slow down the process, so use with caution.

=item I<result_shared_mem_size> integer

Sets the shared memory segment to store the asynchronous process results. This default to the value of the constant C<Module::Generic::SharedMem::SHM_BUFSIZ>, which is 64K bytes.

=item I<timeout> integer

Currently unused.

=item I<use_cache_file>

Boolean. If true, L<Promise::Me> will use a cache file instead of shared memory block. If you are on system that do not support shared memory, L<Promise::Me> will automatically revert to L<Module::Generic::File::Cache> to handle data shared among processes.

You can use the global package variable C<$SHARE_MEDIUM> to set the default value for all object instantiation.

C<$SHARE_MEDIUM> value can be either C<memory> for shared memory or C<file> for shared cache file.

=back

=head2 catch

This takes a code reference as its unique argument and is added to the chain of handlers.

It will be called upon an exception being met or if L</reject> is called.

=head2 reject

This takes one or more arguments that will be passed to the next L</catch> handler, if any.

It will mark the promise as C<rejected> and will go no further in the chain.

=head2 rejected

Takes a boolean value and sets or gets the C<rejected> status of the promise.

This is typically set by L</reject> and you should not call this directly, but use instead L</reject>.

=head2 resolve

This takes one or more arguments that will be passed to the next L</then> handler, if any.

It will mark the promise as C<resolved> and will the next L</then> handler.

=head2 resolved

Takes a boolean value and sets or gets the C<resolved> status of the promise.

This is typically set by L</resolve> and you should not call this directly, but use instead L</resolve>.

=head2 result

This sets or gets the result returned by the asynchronous process. The data is exchanged through shared memory.

This method is used internally in combination with L</await>, L</all> and L</race>

The value returned is always a reference, such as array, hash or scalar reference.

If the asynchronous process returns a simple string for example, C<result> will be an array reference containing that string.

Thus, unless the value returned is 1 element and it is a reference, it will be made of an array reference.

=head2 timeout

Sets gets a timeout. This is currently not used. There is no timeout for the asynchronous process.

If you want to set a timeout, you can use L</wait>, or L</await>

=head2 wait

This is a chain method whose purpose is to indicate that we must wait for the asynchronous process to complete.

    Promise::Me->new(sub
    {
        # Some operation to be run asynchronously
    })->then(sub
    {
        # Do some processing of the result
    })->catch(sub
    {
        # Cath any exceptions
    })->wait;

=head1 CLASS FUNCTIONS

=head2 all

Provided with one or more C<Promise::Me> objects, and this will wait for all of them to be resolved.

It returns an array equal in size to the number of promises provided initially.

However, if one promise is rejected, L</all> stops and returns it immediately.

    my @results = Promise::Me->all( $p1, $p2, $p3 );

Contrary to its JavaScript equivalent, you do not need to pass an array reference of promises, although you could.

    # Works too, but not mandatory
    my @results = Promise::Me->all( [ $p1, $p2, $p3 ] );

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Promise/all> for more information.

=head2 race

Provided with one or more C<Promise::Me> objects, and this will return the result of the first promise that resolves or is rejected.

Contrary to its JavaScript equivalent, you do not need to pass an array reference of promises, although you could.

    # Works too, but not mandatory
    my @results = Promise::Me->race( [ $p1, $p2, $p3 ] );

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Promise/race> for more information.

=head1 EXPORTED FUNCTIONS

=head2 async

This is a static function exported by default and that wrap the subroutine thus prefixed into one that returns a promise and return its code asynchronously.

For example:

    async sub fetch
    {
        my $ua = LWP::UserAgent->new;
        my $res = $ua->get( 'https://example.com' );
    }

This would be equivalent to:

    Promise::Me->new(sub
    {
        my $ua = LWP::UserAgent->new;
        my $res = $ua->get( 'https://example.com' );
    });

Of course, since, in our example above, C<fetch> would return a promise, you could chain L</then>, L</catch> and L</finally>, such as:

    async sub fetch
    {
        my $ua = LWP::UserAgent->new;
        my $res = $ua->get( 'https://example.com' );
    }->then(sub
    {
        my $res = shift( @_ );
        if( !$resp->is_success )
        {
            die( My::Exception->new( "Unable to fetch remote content." ) );
        }
    })->catch(sub
    {
        my $exception = shift( @_ );
        $logger->warn( $exception );
    })->finally(sub
    {
        $dbi->disconnect;
    });

See L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Statements/async_function> for more information on C<async>

=head2 await

Provided with one or more promises and L</await> will wait until each one of them is completed and return an array of their result with one entry per promise. Each promise result is a reference (array, hash, or scalar, or object for example)

    my @results = await( $p1, $p2, $p3 );

=head2 lock

This locks a shared variable.

    my $data : shared = {};
    lock( $data );
    $data->{location} = 'Tokyo';
    unlock( $data );

See L</"SHARED VARIABLES"> for more information about shared variables.

=head2 share

Provided with one or more variables and this will enable them to be shared with the asynchronous processes.

Currently supported variable types are: array, hash and scalar (string) reference.

    my( $name, @first_names, %preferences );
    share( $name, @first_names, %preferences );
    $name = 'Momo Taro';

    Promise::Me->new(sub
    {
        $preferences{name} = $name = 'Mr. ' . $name;
        print( "Hello $name\n" );
        $preferences{location} = 'Okayama';
        $preferences{lang} = 'ja_JP';
        $preferences{locale} = '桃太郎'; # Momo Taro
        my $rv = $tbl->insert( \%$preferences )->exec || die( My::Exception->new( $tbl->error ) );
        $rv;
    })->then(sub
    {
        my $mail = My::Mailer->new(
            to => $preferences{email},
            name => $preferences{name},
            body => $welcome_ja_file,
        );
        $mail->send || die( $mail->error );
    })->catch(sub
    {
        my $exception = shift( @_ );
        $logger->write( $exception );
    })->finally(sub
    {
        $dbh->disconnect;
    });

It will try to use shared memory or shared cache file depending on the value of the global package variable C<$SHARE_MEDIUM>

=head2 unlock

This unlocks a shared variable. It has no effect on variable that have not already been shared.

See L</"SHARED VARIABLES"> for more information about shared variables.

=head2 unshare

Unshare a variable. It has no effect on variable that have not already been shared.

This should only be called before the promise is created.

=head1 INTERNAL METHODS

=head2 add_final_handler

This is called each time a L</finally> method is called and will add to the chain the code reference provided.

=head2 add_reject_handler

This is called each time a L</catch> method is called and will add to the chain the code reference provided.

=head2 add_resolve_handler

This is called each time a L</then> method is called and will add to the chain the code reference provided.

=head2 args

This method is called upon promise object instantiation when initially called by L</async>.

It is used to capture arguments so they can be passed to the code executed asynchronously.

=head2 exec

This method is called at the end of the chain. It will prepare shared variable for the child process, launch a child process using L<perlfunc/fork> and will call the next L</then> handler if the code executed successfully, or L</reject> if there was an error.

=head2 exit_bit

This corresponds to C<$?>. After the child process exited, L</_set_exit_values> is called and sets the value for this.

=head2 exit_signal

This corresponds to the integer value of the signal, if any, used to interrupt the asynchronous process.

=head2 exit_status

This is the integer value of the exit for the asynchronous process. If a process exited normally, this value should be 0.

=head2 filter

This is called by the C<import> method to filter the code using perl filter with XS module L<Filter::Util::Call> and enables data sharing, and implementation of async subroutine prefix. It relies on XS module L<PPI> for parsing perl code.

=head2 get_finally_handler

This is called when all chaining is complete to get the L</finally> handler, if any.

=head2 get_next_by_type

Get the next handler by type, i.e. C<then>, C<catch> or C<finally>

=head2 get_next_reject_handler

This is called to get the next L</catch> handler when a promise has been rejected, such as when an error has occurred.

=head2 get_next_resolve_handler

This is called to get the next L</then> handler and execute its code passing it the return value from previous block in the chain.

=head2 has_coredump

Returns true if the asynchronous process last exited with a core dump, false otherwise.

=head2 is_child

Returns true if we are called from within the asynchronous process.

=head2 is_parent

Returns true if we are called from within the main parent process.

=head2 no_more_chaining

This is set to true automatically when the end of the method chain has been reached.

=head2 pid

Returns the pid of the asynchronous process.

=head2 share_auto_destroy

This is a promise instantiation option. When set to true, the shared variables will be automatically removed from memory upon end of the main process.

This is true by default. If you want to set it to false, you can do:

    Promise::Me->new(sub
    {
        # some code here
    }, {share_auto_destroy => 0})->then(sub
    {
        # some more work here, etc.
    });

=head2 shared_mem

This returns the L<Module::Generic::SharedMem> object used for sharing data and result between the main parent process and the asynchronous child process.

=head2 shared_space_destroy

Boolean. Default to true. If true, the shared space used by the parent and child processes will be destroy automatically. Disable this if you want to debug or take a sneak peek into the data. The shared space will be either shared memory of cache file depending on the value of C<$SHARE_MEDIUM>

=head2 use_async

This is a boolean value which is set automatically when a promise is instantiated from L</async>.

It enables subroutine arguments to be passed to the code being run asynchronously.

=head1 PRIVATE METHODS

=head2 _browse

Used for debugging purpose only, this will print out the L<PPI> structure of the code filtered and parsed.

=head2 _parse

After the code has been collected, this method will quickly parse it and make changes to enable L</async>

=head2 _reject_resolve

This is a common code called by either L</resolve> or L</reject>

=head2 _set_exit_values

This is called upon the exit of the asynchronous process to set some general value about how the process exited.

See L</exit_bit>, L</exit_signal> and L</exit_status>

=head2 _set_shared_space

This is called in L</exec> to share data including result between main parent process and asynchronous process.

=head1 SHARED VARIABLES

It is important to be able to share variables between processes in a seamless way.

When the asynchronous process is executed, the main process first fork and from this point on all data is being duplicated in an impermeable way so that if a variable is modified, it would have no effect on its alter ego in the other process; thus the need for shareable variables.

You can enable shared variables in two ways:

=over 4

=item 1. declaring the variable as shared

    my $name : shared;
    # Initiate a value
    my $location : shared = 'Tokyo';
    # you can also use 'pshared'
    my $favorite_programming_language : pshared = 'perl';
    # You can share array, hash and scalar
    my %preferences : shared;
    my @names : shared;

=item 2. calling L</share>

    my( $name, %prefs, @middle_names );
    share( $name, %prefs, @middle_names );

=back

Once shared, you can use those variables normally and their values will be shared between the parent process and the asynchronous process.

For example:

    my( $name, @first_names, %preferences );
    share( $name, @first_names, %preferences );
    $name = 'Momo Taro';

    Promise::Me->new(sub
    {
        $preferences{name} = $name = 'Mr. ' . $name;
        print( "Hello $name\n" );
        $preferences{location} = 'Okayama';
        $preferences{lang} = 'ja_JP';
        $preferences{locale} = '桃太郎';
        my $rv = $tbl->insert( \%$preferences )->exec || die( My::Exception->new( $tbl->error ) );
        $rv;
    })->then(sub
    {
        my $mail = My::Mailer->new(
            to => $preferences{email},
            name => $preferences{name},
            body => $welcome_ja_file,
        );
        $mail->send || die( $mail->error );
    })->catch(sub
    {
        my $exception = shift( @_ );
        $logger->write( $exception );
    })->finally(sub
    {
        $dbh->disconnect;
    });

If you want to mix this feature and the usage of threads' C<shared> feature, use the keyword C<pshared> instead of C<shared>, such as:

    my $name : pshared;

Otherwise the two keywords would conflict.

=head1 SHARED MEMORY

This module uses shared memory using perl core functions, or shared cache file using L<Module::Generic::File::Cache> if shared memory is not supported, or if the value of the global package variable C<$SHARE_MEDIUM> is set to C<file> instead of C<memory>

Shared memory is used for:

=over 4

=item 1. shared variables

=item 2. storing results returned by asynchronous processes

=back

You can control how much shared memory is allocated for each by:

=over 4

=item 1. setting the global variable C<$SHARED_MEMORY_SIZE>, which default to 64K bytes.

=item 2. setting the option I<result_shared_mem_size> when instantiating a new C<Promise::Me> object. If not set, this will default to L<Module::Generic::SharedMem::SHM_BUFSIZ> constant value which is 64K bytes.

If you use L<shared cache file|Module::Generic::File::Cache>, then not setting a size is ok. It will use the space on the filesystem as needed and obviously return an error if there is no space left.

=back

=head1 CONCURRENCY

Because L<Promise::Me> forks a separate process to run the code provided in the promise, two promises can run simultaneously. Let's take the following example:

    use Time::HiRes;
    my $result : shared = '';
    my $p1 = Promise::Me->new(sub
    {
        sleep(1);
        $result .= "Peter ";
    })->then(sub
    {
        print( "Promise 1: result is now: '$result'\n" );
    });

    my $p2 = Promise::Me->new(sub
    {
        sleep(0.5);
        $result .= "John ";
    })->then(sub
    {
        print( "Promise 2: result is now: '$result'\n" );
    });
    await( $p1, $p2 );
    print( "Result is: '$result'\n" );

This will yield:

    Promise 2: result is now: 'John '
    Promise 1: result is now: 'John Peter '
    Result is: 'John Peter '

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Promise::XS>, L<Promise::E6>, L<Promise::AsyncAwait>, L<AnyEvent::XSPromises>, L<Async>, L<Promises>, L<Mojo::Promise>

L<Mozilla documentation on promises|https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Using_promises>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2021-2022 DEGUEST Pte. Ltd. DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
