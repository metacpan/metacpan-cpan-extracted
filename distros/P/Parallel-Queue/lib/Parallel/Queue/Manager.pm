########################################################################
# housekeeping
########################################################################

package Parallel::Queue::Manager v4.0.2;
use v5.24;
use mro qw( c3 );

use Parallel::Queue qw( noexport );

use mro::EVERY;

use Carp            qw( croak           );
use Scalar::Util    qw( blessed reftype );

########################################################################
# package variables
########################################################################

our @CARP_NOT   = ( __PACKAGE__, qw( mro mro::EVERY ) );

my $parent_pid  = $$;

########################################################################
# methods
########################################################################

sub handler : lvalue
{
    my $qmgr    = shift;
    @_ or return $qmgr->[0];
    
    my $handler = shift;

    'CODE' eq reftype $handler 
    or croak "handler: '$handler' is not CODE.";

    $qmgr->[0] = $handler
}

sub queue : lvalue
{
    my $qmgr    = shift;
    @_ or return $qmgr->[1] ||= [];

    $qmgr->[1]  = shift
}

sub next
{
    my $qmgr    = shift;
    my $queue   = $qmgr->queue;

    # the caller may want undef as an argument, who knows?
    # only fix is an exception to indicate no further jobs.

    @$queue
    ? shift @$queue
    : die "Empty queue.\n"
}

sub configure
{
    my $handler = Parallel::Queue->can( 'configure' );
    my $qmgr    = shift;

    $handler->( @_, qw( noexport ) );

    $qmgr
}

sub runqueue
{
    state $runq = Parallel::Queue->can( 'runqueue' );

    $parent_pid = $$;

    my $qmgr    = shift;
    my $jobs    = shift;

    # note that the queue may already be loaded
    # from construction or previous assignment. 

    $qmgr->queue    = [ @_ ]
    if @_;

    $runq->( $jobs, $qmgr );
    $qmgr
}

sub next_job
{
    # pull the item off the stack in the
    # parent process, not the child. ignore
    # $@, eval returning undef is sufficient
    # to end queue execution.

    my $qmgr    = shift;

    eval
    {
        my $next    = $qmgr->next;
        sub { $qmgr->handler->( $next ) }
    }
}

########################################################################
# object manglement
########################################################################

sub new
{
    my $qmgr    = &construct;

    $qmgr->EVERY::LAST::initialize( @_ );
    $qmgr
}

sub construct
{
    my $proto   = shift;

    bless [], blessed $proto || $proto;
}

sub initialize
{
    my $qmgr        = shift;

    $qmgr->handler  = shift     if @_;
    $qmgr->queue    = [ @_ ]    if @_;

    return
}

DESTROY
{
    my $qmgr    = shift;

    $qmgr->EVERY::cleanup;

    undef @$qmgr;
    undef  $qmgr;

    return
}

sub cleanup
{
    if( $$ == $parent_pid )
    {
        my $qmgr    = shift;
        my $queue   = $qmgr->queue;

        say STDERR join "\n\t", "($$) Incomplete jobs:", @$queue
        if @$queue;
    }
    else
    {
        # child running individual job has nothing to 
        # clean up.
    }

    return
}

# keep require happy
1
__END__

=head1 NAME

Parallel::Queue::Manager - dispatching object for Parallel::Queue.

=head1 SYNOPSIS

    # Note: examples of the options for passing in a 
    # queue via new, runqueue, and assignment 
    # are shown in t/1?-runqueue*.t.

    # arguments are the same as Parallel::Queue, 
    # other than 'export' is unnecessary as it
    # is a method.

    use Parallel::Queue::Manager;

    # whatever you use for squishification.

    use MyFile::Squash  qw( squish );

    # the input queue is a list of arguments 
    # to the $handler.
    #
    # in this case the queue is a list of >8KB
    # files that need to be squashed.

    my @pathz
    = grep
    {
        -s > 8192
    }
    glob $glob;

    # the handler takes a queue entry as argument
    # and returns a subref. in this case, it gets
    # file path and bundles it into a subref calling
    # squish.

    my $handler
    = sub
    {
        my $path    = shift;

        sub { squish $path }
    };

    # the queue can be passed as an argument to new
    # for one-stop shopping.

    Parallel::Queue::Manager
    ->new( $handler, @pathz )
    ->configure( qw( verbose finish ) )
    ->runqueue( $job_count, @pathz );

    # to simplify re-using the $qmgr object, 
    # jobs can be passed to runqueue also.
    #
    # in this case the job count can depend 
    # on whether the queued jobs are expensive
    # to process or not (e.g., gzip vs. xz -T0).

    my $qmgr 
    = Parallel::Queue::Manager
    ->new( $handler )
    ->configure( qw( finish );

    my @queue
    = map
    {
        my $task = $_;

        my $job
        = is_big_task( $_ )
        ? 1
        : 32
        ;

        [ $job, $task ]
    }
    generate_jobs;

    $qmgr->runqueue( @$_ )
    for @queue;
    
    # the "queue" and "handler" methods provide
    # access to the queue elements as lvalues.

    my $qmgr = Parallel::Queue::Manager->new();

    for( @tasks )
    {
        my( $handler, $queue ) = @$_;

        $qmgr->handler  = $handler; 
        $qmgr->runqueue( $jobs => @$queue );

        my $sanity  = $qmgr->queue;

        say join "\n\t" => 'Unfinished business:', @$sanity
        if @$sanity;
    }





