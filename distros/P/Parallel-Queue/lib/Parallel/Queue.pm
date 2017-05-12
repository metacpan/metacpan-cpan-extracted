########################################################################
# housekeeping
########################################################################

package Parallel::Queue;
use v5.12;

use strict;

use Carp            qw( croak                       );
use Scalar::Util    qw( blessed looks_like_number   );
use Symbol          qw( qualify_to_ref              );

########################################################################
# package variables
########################################################################

our $VERSION    = '3.6';
$VERSION = eval $VERSION;

# defaults.

my  $fork       = '';
my  $verbose    = '';
my  $finish     = '';

########################################################################
# execution handlers
########################################################################

sub next_job
{
    state $next = '';
    my $job     = '';

    JOB:
    for(;;)
    {
        if( $next )
        {
            $job    = $next->( $_[0] )
            and last;

            say STDERR "Completed iterator: '$_[0]'"
            if $verbose;

            $next   = '';
            shift;
        }

        @_ or last;

        for my $item ( $_[0] )
        {
            if
            (
                blessed $item
                and
                $next = $item->can( 'next_job' )
            )
            {
                say STDERR "New iterator: '$next' ($_[0])"
                if $verbose;

                next JOB
            }
            elsif( ref $item )
            {
                $job    = shift;
            }
            elsif( $item )
            {
                # these might end up being processing directives
                # later on, for now ignore them.

                say STDERR "Discarding non-queue '$item'";

                shift
            }
            else
            {
                # silently ignore empty filler.

                shift;
            }
        }

        last if $job;
    }

    say STDERR "Next job: '$job'"
    if $verbose;

    $job
    or return
}

sub run_nofork
{
    # discard the count, iterate the queue without forking.

    shift;

    say STDERR "Non-forking queue"
    if $verbose;

    while( my $sub = &next_job )
    {
        # these should all exit zero.

        my $result  = eval { $sub->() };

        say STDERR "Complete: '$result' ($@)"
        if $verbose;

        if( $result )
        {
            say STDERR "Non-zero exit: $result, aborting queue";

            last
        }
        elsif( $@ )
        {
            say STDERR "Error in job: $@";

            last
        }
    }

    return
}

sub fork_job
{
    @_
    or do
    {
        say STDERR "Queue empty."
        if $verbose;

        return
    };

    my $job = &next_job
    or return;

    if( ( my $pid = fork ) > 0 )
    {
        say STDERR "fork: $pid"
        if $verbose;

        # nothing useful to hand back.

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

        say STDERR "\tExecuting: '$job'"
        if $verbose;

        my $exitval = eval { $job->() };

        $@
        ? die $@
        : exit $exitval
    }
    else
    {
        # pass back the fork failure for the caller to deal with.

        die "Phorkafobia: $!";
    }
};

sub fork_queue
{
    # count was validated in runqueue.

    my $count = shift;

    # what's left on the stack are the jobs to run.
    # which may be none.
    # if so, we're done.

    say STDERR "Forking initial $count jobs"
    if $verbose;

    &fork_job for 1 .. $count;

    while( (my $pid = wait) > 0 )
    {
        say STDERR "Complete: $pid ($?)"
        if $verbose;

        # this assumes normal *NIX 16-bit exit values,
        # with a status in the high byte and signum 
        # in the lower. notice that $status is not
        # masked to 8 bits, however. this allows us to
        # deal with non-zero exits on > 16-bit systems.
        #
        # caller can trap the signals.

        if( $? )
        {
            # bad news, boss...

            my $message
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
            };

            $finish
            ? warn $message
            : die  $message
            ;
        }

        # kick off another job if the queue is not empty.

        @_ and &fork_job;
    }

    return
};

# debug or zero count run the jobs without forking,
# simplifies most debugging issues.

sub runqueue
{
    my ( $count ) = @_;

    looks_like_number $count  
    or croak "Bogus runqueue: '$count' non-numeric";

    $count < 0
    and croak "Bogus runqueue: negative count ($count)";

    $fork && $count
    ? eval { &fork_queue }
    : eval { &run_nofork }
    ;

    # return the unused portion.
    # this includes any incomplete iterators.

    @_
}

sub import
{
    # discard the current package name and deal 
    # with the args. empty arg for 'export' 
    # indicates that runqueue needs to be exported.

    my $caller = caller;

    shift;

    @_ or unshift @_,  qw( export );

    my $export  = 1;
    my $subname = 'runqueue';

    $fork       = ! $^P;
    $verbose    = '';
    $finish     = '';

    for my $arg ( @_ )
    {
        my( $name, $value ) = split /=/, $arg;

        $value  //= 1;

        $value = ! $value
        if $name =~ s/^no//;

        if( 'fork' eq $name )
        {
            $fork       = $value;
        }
        elsif( 'verbose' eq $name )
        {
            $verbose    = $value;
        }
        elsif( 'finish' eq $name )
        {
            $finish     = $value;
        }
        elsif( 'debug' eq $name )
        {
            if( $value )
            {
                $fork       = '';
                $verbose    = 1;
            }
        }
        elsif( 'export' eq $name )
        {
            $export = !! $value;

            looks_like_number $value 
            or $subname = $value;
        }
        else
        {
            warn "Unknown argument: '$arg' ignored";
        }
    }

    if( $fork && $^P && ! $DB::fork_TTY )
    {
        say STDERR
        'Debugger forking without $DB::fork_TTY; expect problems';
    }

    if( $export )
    {
        my $ref = qualify_to_ref $subname, $caller;

        undef &{ *$ref };

        *$ref   = \&runqueue
    }

    return
}

sub configure
{
    @_ and import @_, qw( noexport );
}

# keep require happy

1

__END__

=head1 NAME

Parallel::Queue - fork subref's N-way parallel as static list or as 
generated by an object.

=head1 SYNOPSIS

    # example queue:
    # only squish files larger than 8KB in size.  figure
    # that the system can handle four copies of squish
    # running at the same time without them interfering
    # with one another.

    my @queue = map { -s > 8192 ? sub{ squish $_ } : () } @filz;

    # simplest case: use the module and pass in 
    # the count and list of coderefs.

    use Parallel::Queue;

    my @remaining = runqueue 4, @queue;

    die "Incomplete jobs" if @remaining;

    # an object with method "next_job" will be called
    # as $iterator->next_job until it returns false. the
    # return values are dispatched via $sub->(); 
    # $iter can be an object or class, including 
    # __PACKAGE__ if the package sets itself up to 
    # handle the paralell jobs.

    my $iter   = Foo->new( @job_parmz );
    runqueue 4 => $iter;

    $pkg->configure( @job_parmz );
    runqueue 8 => $pkg;

    # export allows changing the exported sub name.
    # "export=" allows not exporting it (which then
    # requires calling Parallel::Queue::runqueue ...

    use Parallel::Queue qw( export=handle_queue );

    my @remaining = handle_queue 4, @queue;

    # "fork" is the normal state.
    # "nofork" or a zero count avoid forking.
    # detecting the perl debugger (via $^P) will
    # defaults "fork" to false ("nofork" mode).
    # forking in the debugger can be turned on
    # with an explicit fork (which includs a 
    # warning for lack of $DB::DEBUG_TTY).

    #!/usr/bin/perl -d

    use Parallel::Queue;                # defaults to nofork mode.
    use Parallel::Queue qw( nofork );   # ditto

    use Parallel::Queue qw( fork   );   # forks, even in the debugger.


    # "debug" turns on nofork and verbose.
    # these produce identical results.

    use Parallel::Queue qw( debug );        
    use Parallel::Queue qw( nofork verbose );

    # finish forces execution to continue even if 
    # there is an error in one job. this will finish
    # the cleanups even if one of them fails.

    use Parallel::Queue qw( finish );

    my @cleanupz    = ... ;

    runqueue $nway, @cleanupz;

    # "configure" is a more descriptive alias for the
    # import sub.

    Parallel::Queue->configure( debug=0 finish=1 );


=head1 DESCRIPTION

=head2 Arguments to use (or configure).

The finish, debug, and verbose arguments default
to true. This means that turning them on does 
not require an equals sign and value. Turning
them off requries an equal sign and zero.

The export option defaults to false: using it
without a value avoids exporting the runqueue
subroune into the caller.

=over 4

=item finish (default finish=0)

This causes the queue to finsih even if there are
non-zero exits on the way. Exits will be logged 
but will not stop the queue. 

=item export=my_name (default export=runqueue)

By default Parallel::Queue exports "runqueue", this can
be changed with the "export" arguments. In this case
call it "my_name" and use it to run the queue with two
parallel processes:

    use Parallel::Queue qw( export=run_these );

    my @queue       = ...;

    my @un_executed = run_these 2, @queue;

The name can be any valid Perl sub name.

Using an empty name avoids exporting anything 
and requires using the fully qualified subname
(Parallel::Query::runqueu) to run the queue.

=item verbose

This outputs a line with the process id each
time a job is dispatched or reaped.

=item debug

Turned on by default if the perl debugger is 
in use (via $^P), this avoids forking and 
simply dispatches the jobs one by one. This 
helps debug dispatched jobs where handling 
forks in the Perl debugger can be problematic.

Debug can be turned off via debug=0 with the
use or confgure. If this is turned off with
the debugger running then be prepared to supply
the tty's (see also Debugging forks below).

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

=item Debugging forks.

<http://perlmonks.org/index.pl?node_id=128283>

=back

=head1 COPYRIGHT

This code is released under the same terms as Perl-5.20
or any later version of Perl.

=head1 AUTHOR

Steven Lembark <lembark@wrkhors.com>
