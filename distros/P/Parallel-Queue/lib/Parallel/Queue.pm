########################################################################
# housekeeping
########################################################################

package Parallel::Queue v4.0.0;
use v5.24;
use mro qw( c3 );

use mro::EVERY;

use Carp            qw( croak                       );
use Symbol          qw( qualify_to_ref              );

use Scalar::Util
qw
(
    blessed
    reftype
    looks_like_number
);

########################################################################
# package variables
########################################################################

our @CARP_NOT   = ( __PACKAGE__, qw( mro mro::EVERY ) );

# config state

my %defaultz = 
(
    fork    => ! $^P
  , qw
    (
        export  runqueue
        finish  0
        debug   0
        verbose 0
    )
);

my %argz   = %defaultz;

########################################################################
# utility subs
########################################################################

my $format
= sub
{
    state $dumper
    = do
    {
        require Data::Dumper;
        Data::Dumper->can( 'Dumper' )
    };

    local $Data::Dumper::Terse      = 1;
    local $Data::Dumper::Indent     = 1;
    local $Data::Dumper::Sortkeys   = 1;

    local $Data::Dumper::Purity     = 0;
    local $Data::Dumper::Deepcopy   = 0;
    local $Data::Dumper::Quotekeys  = 0;

    say join "\n" =>
    map
    {
        ref $_ 
        ? $_->$dumper
        : $_
    }
    @_;

    return;
};

my $stub    = sub{};
my $debug   = $stub;

########################################################################
# execution handlers
########################################################################

my $next_job
= sub 
{
    state $redo     = __SUB__;
    state $object   = '';

    my $job     = '';

    if( $object )
    {
        # objects may have their own internal stack. 
        # if there aren't any arguments then pass 
        # nothing rather than undef from shift.

        if( my $job = $object->next_job )
        {
            return $job;
        }
        else
        {
            $object  = '';
        }
    }

    @_  or return;
    
    # silently ignore empty slots.

    my $next = shift
    or goto *$redo;

    my $class   = blessed $next;

    if( $class && $class->can( 'next_job' ) )
    {
        $debug->( "New iterator: '$class'" );

        $object = $next;
        goto &$redo
    }
    elsif( 'CODE' eq reftype $next )
    {
        $next
    }
    else
    {
        my $nastygram
        = $format->( 'Bothched queue: un-blessed, non-coderef', $_[0] );

        $argz{ finish }
        or croak $nastygram;

        say STDERR $nastygram;
        goto &$redo
    }
};

my $run_nofork
= sub
{
    # discard the count, iterate the queue without forking.
    shift;

    $debug->( 'Non-forking queue' );

    while( my $sub = &$next_job )
    {
        # these should all exit zero.

        my $exit
        = eval
        {
            $sub->()
            or next
        };

        say STDERR "\nNon-zero exit: $exit, $@\n";

        if( $argz{ finish } ) 
        {
            say 'Non-zero exit: Continuing queue.';
        }
        else
        {
            say 'Non-zero exit: Aborting queue.';
            last;
        }
    }

    return
};

my $fork_job
= sub
{
    # don't check @_: next_job may have an object
    # returning next jobs w/ an empty queue.

    my $job = &$next_job
    or return;

    if( ( my $pid = fork ) > 0 )
    {
        $debug->( "fork: $pid" );
        return
    }
    elsif( defined $pid )
    {
        # child passes the exit status of the perl sub call
        # to the caller as our exit status. the O/S will deal
        # with signal values.
        #
        # aside: failing to exit here will cause runaway
        # phorkatosis.

        $debug->( "\tExecuting: '$job'" );

        my $exitval = eval { $job->() } || 0;

        # either way, this process needs to exit.

        $@
        ? die
        : exit $exitval
    }
    else
    {
        # pass back the fork failure for the caller to deal with.

        die "Phorkafobia: $!";
    }
};

my $fork_queue
= sub
{
    # count was validated in runqueue.

    my $count   = shift;

    # what's on the stack?
    # the jobs to run!
    # which may be none.
    # if so, we're done.

    $debug->( "Forking initial $count jobs." );

    &$fork_job for 1 .. $count;

    $debug->( "Processing remainder of queue." );

    my $reap_only   = '';

    while( ( my $pid = wait ) > 0 )
    {
        $debug->( "Complete: $pid ($?)" );

        if( $? )
        {
            # this assumes normal *NIX 16-bit exit values,
            # with a status in the high byte and signum 
            # in the lower. notice that $status is not
            # masked to 8 bits, however. this allows us to
            # deal with non-zero exits on > 16-bit systems.
            #
            # caller can trap the signals.

            my $failure
            = do
            {
                if( my $exit = $? >> 8 )
                {
                    "exit( $exit ) by $pid"
                }
                elsif( my $signal = $? & 0xFF )
                {
                    "kill SIG-$signal on $pid"
                }
                else
                {
                    "coredump by $pid"
                }
            };

            my $result
            = ( $reap_only = ! $argz{ finish } )
            ? "Non-zero exit: Reaping only to complete queue."
            : "Non-zero exit: Continuing queue."
            ;

            say STDERR "\n$failure\n$result\n";
        }

        $reap_only 
        or &$fork_job
    }

    return
};

# debug or zero count run the jobs without forking,
# simplifies most debugging issues.

sub runqueue
{
    my $count   = $_[0];

    looks_like_number $count  
    or croak "Bogus runqueue: '$count' non-numeric";

    $count < 0
    and croak "Bogus runqueue: negative count ($count)";

    $argz{ fork } && $count
    ? &$fork_queue
    : &$run_nofork
    ;

    # return the unused portion.
    # this includes any incomplete iterators.

    @_
}

sub configure
{
    # discard the current patckage
    shift if $_[0] eq __PACKAGE__;

    %argz
    = map
    {
        my ( $arg, $val ) = split /=/, $_, 2;

        $val    //= 1;

        $val    = !$val
        if $arg =~ s{^ no}{}x;

        ( $arg => $val )
    }
    @_;

    @argz{ qw( fork verbose ) } = ( '', 1 )
    if delete $argz{ debug };

    for( $argz{ export } )
    {
        # numeric for true gets default name.
        # name for true gets whatever's there.

        $_  or next;

        # default does the right thing.

        looks_like_number $_
        and delete $argz{ export };

        m{ \W }x
        and croak "Botched export: '$_' contains non-word chars.";
    }

    while( my($k,$v) = each %defaultz )
    {
        $argz{ $k } //= $v;
    }

    $debug
    = $argz{ verbose }
    ? $format
    : $stub
    ;

    $debug->( 'Configuration:', \%argz );

    if( $argz{ fork } && $^P )
    {
        say STDERR
        'Debugger forking. Check TERM=xterm or $DB::debug_TTY.';
    }

    return
}

sub import
{
    &configure;

    if( my $export = $argz{ export } )
    {
        my $caller  = caller;
        my $ref     = qualify_to_ref $export => $caller;

        undef &{ *$ref };

        $debug->( "Installing $export -> $caller" );

        *$ref       = \&runqueue
    }
}

# keep require happy

1

__END__

=head1 NAME

Parallel::Queue - OO and imperitive interface for forking queues.

=head1 SYNOPSIS

    ############################################################
    # simple queue is an array of subrefs that get dispatched
    # N-way parallel (or single-file if forking is turned off).
    #
    # subs returning non-zero will abort the queue, returning
    # the unused portion for your money back.

    use Parallel::Queue;

    my @queue 
    = map
    {
        -s > 8192 
        ? sub{ squish $_ }
        :
        ()
    }
    glob $glob;

    my @remaining = runqueue 4, @queue;

    die "Incomplete jobs" if @remaining;

    # for testing forking can be explicitly turned off.
    # 'configure' procsses the same arguments as import.
    #
    # these have the same results:

    use Parallel::Queue qw( nofork );

    Parallel::Queue->configure(  qw( nofork ) );

    # debugging turns on verbose, off fork.
    # these are indentical.

    use Parallel::Queue qw( debug );
    use Parallel::Queue qw( nofork debug );


    ############################################################
    # if an object is found on the queue that can 'next_job' 
    # then it the result of its next_job() should be a subref.
    # the object should contain its own queue and return false
    # when the queue is completed.
    #
    # nice thing about this approach is saving time and memory
    # not having to create a thousand closures and being able
    # to easily read the unfinished queue.

    my @queue   = map { ... } glob $glob;

    my $squash_me
    = do
    {
        package Squash;

        my $squish  = Some::Package->can( 'squish' );

        sub next_job
        {
            my $que     = shift;
            my $path    = shift @$que
            or return;

            sub{ $path->$squish }
        }

        bless [ @queue ], __PACKAGE__
    };


    runqueue 4 => $squash_me;

    log_error "Unfinished business\n", @$squash_me
    if @$squash_me;

    ############################################################
    # subrefs and objects can be mixed on the stack.
    # 
    # any objects that can( 'next_job' ) get called until they
    # return false, at which point the stack is advance and the
    # next item can be a subref or object.
    #
    # when all of the objects have finished returning new
    # jobs then any subrefs left on the stack are executed
    #
    # 'finish' reports non-zero exits from forked jobs but 
    # does not stop the queue. without it the first non-zero
    # exit aborts the queue.

    use Parallel::Queue qw( finish );

    my @daily_cleanups = 
    (
        Cleanup->new( $path_to_logs => 'rm', '14'   ) 
      , Cleanup->new( $path_to_logs => 'gzip', 1    ) 
      , Cleanup->can( 'sync_data_access'            )
      , Cleanup->new( $path_to_data => 'gzip' 2     )
      , Cleanup->can( 'unlock_data_access'          )
    );

    runqueue 8, @daily_cleanups;

    ############################################################
    # verbose turns on lightweight progress reports. 
    # nofork runs the queue within the current process.
    # export=<name> allows using a different name for 'runqueue'
    # or not exporting it at all.
    # debug turns on nofork + verbose.  
    #
    # all of the terms can be prefixed with 'no' to invert them.


    use Parallel::Queue qw( nofork );           # mainly for testing
    use Parallel::Queue qw( verbose);           # progress messages
    
    use Parallel::Queue qw( debug );            # verbose + nofork

    use Parallel::Queue qw( finish  );          # don't stop

    use Parallel::Queue qw( export=run_this );  # install "run_this"
    use Parallel::Queue qw( noexport );

    # options other than 'export' can be set at runtime 
    # via confgure.

    Parallel::Queue->configure( qw( debug finish ) )
    if $^P;


=head1 DESCRIPTION

This module is mostly boilerplate around fork, reporting the 
outcome of forked jobs. Jobs arrive either as coderefs or
objects that can "next_job" (blessed coderefs which cannot
"next_job" are treated as ordinary coderefs). Jobs can be 
dispatched with or without forking.

Queues are executed by passing them runqueue with a non-
negative integer job count. If the count is zero then jobs
are not forked; otherwise the count (up to the queue size)
of jobs is initially forked and a wait-loop forks additional
as each job exits until the queue is consumed. 

If any jobs return a non-zero exit code then the default 
behavior is to abort the queue, reap any existing forks,
and return the remaining jobs. If the "finish" option is
selected then jobs will continue to be forked until the 
queue is finished, regardless of errors. 

=head2 Arguments to use (or configure).

With the exeptions of "export" and "debug", arguments
are passed as named flags, with a "no" prefix turning
off the feature. 

=over 4

=item export=<name> 

This is only dealt with as an argument to "use" (i.e.,
in import). This allows renaming the exported sub from
"runqueue" to any other valid Perl subname or turning 
off the export with "noexport".

Examples are:

    qw( export=run_this )   # alternate subname.
    qw( export          )   # default, gets "runqueue".
    qw( noexport        )   # no sub is exported.

=item debug 

This has no corresponding "nodebug", it is equivalent 
to using qw( verbose nofork ).  

=item finish (default nofinish)

This causes the queue to finsih even if there are
non-zero exits on the way. Exits will be logged 
but will not stop the queue. 

=item verbose (default noverbose)

This adds some progress messages (e.g., pid's forked,
reaped, class of an object used for dispatch). 

=back

=head1 KNOWN ISSUES

=over 4

=item Non-numeric count arguments.

The runqueue sub uses Scalar::Util::looks_like_number 
validate the count. This may cause problems for objects
which don't look like numbers.

=back

=head1 SEE ALSO

=over 4

=item Parallel::Queue::Manager

OO Interface to runqueue with re-usable queue manager. 

=item Debugging forks.

<http://perlmonks.org/index.pl?node_id=128283>

=back

=head1 COPYRIGHT

This code is released under the same terms as Perl-5.24
or any later version of Perl.

=head1 AUTHOR

Steven Lembark <lembark@wrkhors.com>
