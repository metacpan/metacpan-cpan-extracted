package Parallel::Tiny;
use strict;
use warnings;
use POSIX qw(WNOHANG);
use Sys::Prctl qw(prctl);

our $VERSION = 1.00;

# defaults for prctl()
use constant PR_SET_PDEATHSIG => 1;
use constant SIGHUP           => 1;

# defaults for the new() method
use constant DEFAULT_ERROR_TIMEOUT => 10;
use constant DEFAULT_REAP_TIMEOUT  => .1;
use constant DEFAULT_SUBNAME       => 'run';
use constant DEFAULT_WORKERS       => 1;
use constant DEFAULT_WORKER_TOTAL  => 1;

=head1 NAME

Parallel::Tiny

=head1 DESCRIPTION

Provides a simple, no frills fork manager.

=head1 SYNOPSIS

Given an object that provides a C<run()> method, you can create a C<Parallel::Tiny> fork manager object that will execute that method several times.

    my $obj = My::Handler->new();
    my $forker = Parallel::Tiny->new(
        handler      => $obj,
        workers      => 4,
        worker_total => 32,
    );
    $forker->run();

In the above example we will execute the C<run()> method for a C<My::Handler> object 4 workers at a time, until 32 total workers have completed/died.

=head1 METHODS

=over

=item new()

Returns a new C<Parallel::Tiny> fork manager.

Takes the following arguments as a hash or hashref:

    {
        handler      => $handler,      # provide an object with a run() method, this will be your worker (required)
        reap_timeout => $reap_timeout, # how long to wait in between reaping children                    (default ".1")
        subname      => $subname,      # a method name to execute for the $handler                       (default "run")
        workers      => $workers,      # the number of workers that can run simultaneously               (default 1)
        worker_total => $worker_total, # the total number of times to run before stopping                (default 1)
    }

For instance, you could run 100 workers, 4 workers at a time:

    my $forker = Parallel::Tiny->new(
        handler      => $obj,
        workers      => 4,
        worker_total => 100,
    );

C<infinite> can be provided for the C<$worker_total> but you will need to manage stopping the fork manager elsewhere.

If the parent is sent C<SIGTERM> it will wait to reap all currently executing children before finishing.

If the parent is killed, children will receive C<SIGHUP>, which you will need to deal with in your C<$handler>.

=cut

sub new {
    my $class = shift;
    my $args = ref( $_[0] ) ? $_[0] : {@_};

    # set some defaults
    $args->{reap_timeout} ||= DEFAULT_REAP_TIMEOUT;
    $args->{subname}      ||= DEFAULT_SUBNAME;
    $args->{workers}      ||= DEFAULT_WORKERS;
    $args->{worker_total} ||= DEFAULT_WORKER_TOTAL;

    # special configuration
    undef $args->{worker_total} if $args->{worker_total} eq 'infinite';

    # check args
    die 'no handler provided' unless $args->{handler};
    die "handler doesn't implement $args->{subname}()"
      unless $args->{handler}->can( $args->{subname} );

    return bless(
        {
            _continue     => 1,
            _handler      => $args->{handler},
            _jobs         => {},
            _reap_timeout => $args->{reap_timeout},
            _subname      => $args->{subname},
            _workers      => $args->{workers},
            _worker_total => $args->{worker_total},
        },
        $class
    );
}

=item run()

Start running a number of parallel workers equal to C<$workers>, until a number of workers equal to C<$worker_total> have been completed.

=cut

sub run {
    my $self = shift;

    local $SIG{TERM} = sub { $self->{_continue} = 0 };

    # setup the fork manager
    my $handler = $self->{_handler};
    my $subname = $self->{_subname};

    while ( $self->_waitqueue() ) {

        # parent work
        my $pid = fork();
        if ($pid) {
            $self->{_worker_total}--
              if defined $self->{_worker_total} and $self->{_worker_total} > 0;
            $self->{_jobs}{$pid} = 1;
            next;
        }

        # child work
        prctl( PR_SET_PDEATHSIG, SIGHUP );
        $SIG{$_} = 'DEFAULT' for keys %SIG;
        $0 = $0 . ' - worker';
        $handler->$subname();

        # child cleanup
        exit 0;
    }

    # wait for children
    while ( wait() != -1 ) { }

    return 1;
}

##-----------------------------------------------------------------------------
## Private Methods
##-----------------------------------------------------------------------------

# waits for another job slot to become available short circuits if we've received SIGTERM or reached worker total threshold
sub _waitqueue {
    my $self = shift;

# short circuit if we've already completed all the workers we've been configured to run
    return 0 if defined $self->{_worker_total} and $self->{_worker_total} <= 0;

    # wait to reap at least one child
    while ( keys %{ $self->{_jobs} } >= $self->{_workers} ) {
        return 0 unless $self->{_continue};
        $self->_reapchildren();
        sleep $self->{_reap_timeout};
    }

    return 1;
}

# cleans up children that are no longer running
sub _reapchildren {
    my $self = shift;
    foreach my $pid ( keys %{ $self->{_jobs} } ) {
        my $waitpid = waitpid( $pid, WNOHANG );
        delete $self->{_jobs}{$pid} if $waitpid > 0;
    }
}

=back

=cut

1;

# ABSTRACT: Provides a simple, no frills fork manager.

