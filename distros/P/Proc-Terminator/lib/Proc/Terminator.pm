package Proc::Terminator::Ctx;
use strict;
use warnings;
use POSIX qw(errno_h);
my $DEBUG = $ENV{PROC_TERMINATOR_DEBUG};

use Moo;
has pid => (
    is =>'ro',
    required => 1,
    isa => sub {
        ($_[0] && $_[0] > 0) or die "PID must be a positive number!"
    },
);

has siglist => (
    is => 'rw',
    required => 0,
    isa => sub { ref $_[0] eq 'ARRAY' or die "Siglist must be an array reference" },
    default => sub  { [] }
);

has last_sent => (
    is => 'rw',
    default => sub { 0 }
);

has error => (
    is => 'rw',
    default => sub { "" }
);

sub try_kill {
    my ($self,$do_kill) = @_;
    
    if (kill(0, $self->pid) == 0) {
        my $errno_save = $!;
        $DEBUG and warn "Kill with signal=0 returned 0 (dead!)";
        if ($errno_save != ESRCH) {
            $self->error($errno_save);
            warn $errno_save;
            return -1;
        }
        # else, == ESRCH
        return 1;
    }
    
    if (!$do_kill) {
        $DEBUG and warn "We were not requested to proceed with signal. Returning";
        return 0;
    }
    my $sig = shift @{$self->siglist};

    if (!defined $sig) {
        $DEBUG and warn "Cannot kill ${\$self->pid} because no signals remain";
        return -1;
    }
    $DEBUG and warn "Using signal $sig for ${\$self->pid}";
    
    if (kill($sig, $self->pid) == 1) {
        return 0;
    }
    
    if ($! == ESRCH) {
        return 1;
    } else {
        warn $!;
        return -1;
    }
}

# This class represents a single 'batch' of PIDs each withe 
package Proc::Terminator::Batch;
use strict;
use warnings;
use POSIX qw(:errno_h);
use Time::HiRes qw(sleep time);
use Moo;

has procs => (
    is => 'rw',
    isa => sub { ref $_[0] eq 'HASH' or die "Expected hash reference!" },
    default => sub { { } },
);

has grace_period => ( is => 'rw', default => sub { 0.75 });
has max_wait => ( is => 'rw', default => sub  { 10 });
has interval => (is => 'rw', default => sub { 0.25 });
has badprocs => (is => 'rw',
                 isa => sub { ref $_[0] eq 'ARRAY' or die "Expected arrayref!" },
                 default => sub {  [ ] } );
has begin_time => (is => 'rw', default => sub { 0 });

sub with_pids {
    my ($cls,$pids,%options) = @_;
    $pids = ref $pids ? $pids : [ $pids ];
    
    my $siglist = delete $options{siglist} ||
        [ @Proc::Terminator::DefaultSignalOrder ];
    
    my %procs;
    foreach my $pid (@$pids) {
        $procs{$pid} = Proc::Terminator::Ctx->new(
            pid => $pid,
            siglist => [ @$siglist ],
            last_sent => 0);
    }
    
    my $self = $cls->new(
        procs => \%procs,
        max_wait => delete $options{max_wait} || 10,
        interval => delete $options{interval} || 0.25,
        grace_period => delete $options{grace_period} || 0.75,
    );
    return $self;
}

sub _check_one_proc {
    my ($self,$ctx,$now) = @_;
    
    my $do_send_kill = $now - $ctx->last_sent > $self->grace_period;
    
    if ($do_send_kill) {
        $ctx->last_sent($now);
        $DEBUG and warn("Will send signal to ${\$ctx->pid}");
    }
    
    my $ret = $ctx->try_kill($do_send_kill);
    
    if ($ret) {
        delete $self->procs->{$ctx->pid};
        if ($ret == -1) {
            push @{ $self->badprocs }, $ctx;
        }
    }
    
    return $ret;
}

# The point of abstracting this is so that this module may be integrated
# within event loops, where this method is called by a timer, or something.
sub loop_once {
    my $self = shift;
    my @ctxs = values %{ $self->procs };
    
    if (!scalar @ctxs) {
        $DEBUG and warn "Nothing left to check..";
        if (@{$self->badprocs}) {
            return undef;
        }
        return 0; #nothing left to do
    }
    
    my $now = time();
    
    if ($self->max_wait &&
        ($now - $self->begin_time > $self->max_wait)) {
        # do one last sweep?
        while (my ($pid,$ctx) = each %{$self->procs}) {
            if (kill(0, $pid) == 0 && $! == ESRCH) {
                delete $self->procs->{$pid};
            } else {
                push @{$self->badprocs}, $ctx;
            }
        }
        if (@{$self->badprocs}) {
            return undef;
        }
        return 0;
    }
    $self->_check_one_proc($_, $now) foreach (@ctxs);
    if (keys %{$self->procs}) {
        return scalar keys %{$self->procs};
    } else {
        if (@{$self->badprocs}) {
            return undef;
        }
        return 0;
    }
}



package Proc::Terminator;
use warnings;
use strict;
use Time::HiRes qw(time sleep);
use POSIX qw(:signal_h :sys_wait_h :errno_h);
use base qw(Exporter);

our $VERSION = 0.05;

our @DefaultSignalOrder = (
    SIGINT,
    SIGQUIT,
    SIGTERM,
    SIGKILL
);

our @EXPORT = qw(proc_terminate);
use Data::Dumper;
# Kill a bunch of processes
sub proc_terminate {
    my ($pids, %options) = @_;
    
    my $batch = Proc::Terminator::Batch->with_pids($pids, %options);
        
    $batch->begin_time(time());
    #print Dumper($batch);
    while ($batch->loop_once) {
        $DEBUG and warn "Sleeping for ${\$batch->interval} seconds";
        sleep($batch->interval);
    }
    
    my @badprocs = map { $_->pid } @{$batch->badprocs};
        
    if (wantarray) {
        return @badprocs;
    } else {
        return !@badprocs;
    }
}

__END__

=head1 NAME

Proc::Terminator - Conveniently terminate processes

=head1 SYNOPSIS

    use Proc::Terminator;
    
    # Try and kill $pid using various methods, waiting
    # up to 20 seconds
    
    proc_terminate($pid, max_wait => 20);

=head1 DESCRIPTION

C<Proc::Terminator> provides a convenient way to kill a process, often useful in
utility and startup functions which need to ensure the death of an external
process.

This module provides a simple, blocking, and procedural interface to kill
a process or multiple processes (not tested), and not return until they are
all dead.

C<Proc::Terminator> can know if you do not have permissions to kill a process,
if the process is dead, and other interesting tidbits.

It also provides for flexible options in the type of death a process will
experience. Whether it be slow or immediate.

This module exports a single function, C<proc_terminate>

=head2 C<proc_terminate($pids, %options)>

Will try to terminate C<$pid>, waiting until the process is no longer alive, or
until a fatal error happens (such as a permissions issue).

C<$pid> can either be a single PID (a scalar), or a reference to an array of
I<multiple> PIDs, in which case they are all attempted to be killed, and the
function only returning once all of them are dead (or when no possible kill
alternatives remain).

The C<%options> is a hash of options which control the behavior for trying to
terminate the pid(s).

=over

=item C<max_wait>

Specify the time (in seconds) that the function should try to spend killing the
provided PIDs. The function is guaranteed to not wait longer than C<max_wait>.

This parameter can also be a fractional value (and is passed to L<Time::HiRes>).

I<DEFAULT>: 10 Seconds.

=item C<siglist>

An array of signal constants (use L<POSIX>'s C<:signal_h> to get them).

The signals are tried in order, until there are no more signals remaining.

Sometimes applications do proper cleanup on exit with a 'proper' signal such as
C<SIGINT>.

The default value for this parameter

The default signal list can be found in C<@Proc::Terminator::DefaultSignalOrder>

I<DEFAULT>: C<[SIGINT, SIGQUIT, SIGTERM, SIGKILL]>

=item C<grace_period>

This specifies a time, in seconds, between the shifting of each signal in the
C<siglist> parameter above.

In other words, C<proc_terminate> will wait C<$grace_period> seconds after sending
each signal in C<siglist>. Thereafter the signal is removed, and the next signal
is attempted.

Currently, if you wish to have controlled signal wait times, you can simply
insert a signal more than once into C<siglist>

I<DEFAULT>: 0.75

=item C<interval>

This is the loop interval. The loop will sleep for ever C<interval> seconds.
You probably shouldn't need to modify this

I<DEFAULT>: 0.25

=back

When called in a scalar context, returns true on sucess, and false otherwise.

When called in list context, returns a list of the PIDS B<NOT> killed.

=head2 OO Interface

This exists mainly to provide compatibility for event loops. While C<proc_terminate>
loops internally, event loops will generally have timer functions which will
call within a given interval.

In the OO interface, one instantiates a C<Proc::Terminator::Batch> object which
contains information about the PIDs the user wishes to kill, as well as the signal
list (in fact, C<proc_terminate> is a wrapper around this interface)

=head3 Proc::Terminator::Batch methods

=head4 Proc::Terminator::Batch->with_pids($pids,$options)

Creates a new C<Proc::Terminator::Batch>. The arguments are exactly the same as
that for L</proc_terminate>.

Since this module does not actually loop or sleep on anything, it is important
to ensure that the C<grace_period> and C<max_wait> options are set appropriately.

In a traditional scenario, a timer would be associated with this object which would
fire every C<grace_period> seconds.

=head4 $batch->loop_once()

Iterates once over all remaining processes which have not yet been killed, and try
to kill them.

Returns a true value if processes still remain which may be killed, and a false
value if there is nothing else to do for this batch.

More specifically, if all processes have been killed successfully, this function
returns C<0>. If there are still processes which are alive (but cannot be killed
due to the signal stack being empty, or another error), then C<undef> is returned.

=head4 $batch->badprocs

Returns a reference to an array of C<Proc::Terminator::Ctx> objects which were
not successfully terminated. The Ctx object is a simple container. Its API fields
are as follows:

=over

=item pid

The numeric PID of the process

=item siglist

A reference to an array of remaining signals which would have been sent to this
process

=item error

This is the captured value of C<$!> at the time the error occured (if any). If this
is empty, then most likely the process did not respond to any signals in the
signal list.

=head1 SEE ALSO

L<signal(7)>

L<kill(2)>

L<Perl's kill | kill>

=head1 AUTHOR & COPYRIGHT

Copyright (C) 2012 M. Nunberg

You may use and distribute this software under the same terms and conditions
as Perl itself.
