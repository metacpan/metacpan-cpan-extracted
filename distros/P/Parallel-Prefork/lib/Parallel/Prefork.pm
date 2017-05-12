package Parallel::Prefork;

use strict;
use warnings;

use 5.008_001;

use base qw/Class::Accessor::Lite/;
use List::Util qw/first max min/;
use Proc::Wait3 ();
use Time::HiRes ();

use Class::Accessor::Lite (
    rw => [ qw/max_workers spawn_interval err_respawn_interval trap_signals signal_received manager_pid on_child_reap before_fork after_fork/ ],
);

our $VERSION = '0.18';

sub new {
    my $klass = shift;
    my $opts = @_ == 1 ? $_[0] : +{ @_ };
    my $self = bless {
        worker_pids          => {},
        max_workers          => 10,
        spawn_interval       => 0,
        err_respawn_interval => 1,
        trap_signals         => {
            TERM => 'TERM',
        },
        signal_received      => '',
        manager_pid          => undef,
        generation           => 0,
        %$opts,
        _no_adjust_until     => 0, # becomes undef in wait_all_children
    }, $klass;
    $SIG{$_} = sub {
        $self->signal_received($_[0]);
    } for keys %{$self->trap_signals};
    $SIG{CHLD} = sub {};
    $self;
}

sub start {
    my ($self, $cb) = @_;
    
    $self->manager_pid($$);
    $self->signal_received('');
    $self->{generation}++;
    
    die 'cannot start another process while you are in child process'
        if $self->{in_child};
    
    # main loop
    while (! $self->signal_received) {
        my $action = $self->{_no_adjust_until} <= Time::HiRes::time()
                && $self->_decide_action;
        if ($action > 0) {
            # start a new worker
            if (my $subref = $self->before_fork) {
                $subref->($self);
            }
            my $pid = fork;
            unless (defined $pid) {
                warn "fork failed:$!";
                $self->_update_spawn_delay($self->err_respawn_interval);
                next;
            }
            unless ($pid) {
                # child process
                $self->{in_child} = 1;
                $SIG{$_} = 'DEFAULT' for keys %{$self->trap_signals};
                $SIG{CHLD} = 'DEFAULT'; # revert to original
                exit 0 if $self->signal_received;
                if ($cb) {
                    $cb->();
                    $self->finish();
                }
                return;
            }
            if (my $subref = $self->after_fork) {
                $subref->($self, $pid);
            }
            $self->{worker_pids}{$pid} = $self->{generation};
            $self->_update_spawn_delay($self->spawn_interval);
        } elsif ($action < 0) {
            # stop an existing worker
            kill(
                $self->_action_for('TERM')->[0],
                (keys %{$self->{worker_pids}})[0],
            );
            $self->_update_spawn_delay($self->spawn_interval);
        }
        $self->{__dbg_callback}->()
            if $self->{__dbg_callback};
        if (my ($exit_pid, $status)
                = $self->_wait(! $self->{__dbg_callback} && $action <= 0)) {
            $self->_on_child_reap($exit_pid, $status);
            if (delete($self->{worker_pids}{$exit_pid}) == $self->{generation}
                && $status != 0) {
                $self->_update_spawn_delay($self->err_respawn_interval);
            }
        }
    }
    # send signals to workers
    if (my $action = $self->_action_for($self->signal_received)) {
        my ($sig, $interval) = @$action;
        if ($interval) {
            # fortunately we are the only one using delayed_task, so implement
            # this setup code idempotent and replace the already-registered
            # callback (if any)
            my @pids = sort keys %{$self->{worker_pids}};
            $self->{delayed_task} = sub {
                my $self = shift;
                my $pid = shift @pids;
                kill $sig, $pid;
                if (@pids == 0) {
                    delete $self->{delayed_task};
                    delete $self->{delayed_task_at};
                } else {
                    $self->{delayed_task_at} = Time::HiRes::time() + $interval;
                }
            };
            $self->{delayed_task_at} = 0;
            $self->{delayed_task}->($self);
        } else {
            $self->signal_all_children($sig);
        }
    }
    
    1; # return from parent process
}

sub finish {
    my ($self, $exit_code) = @_;
    die "\$parallel_prefork->finish() shouln't be called within the manager process\n"
        if $self->manager_pid() == $$;
    exit($exit_code || 0);
}

sub signal_all_children {
    my ($self, $sig) = @_;
    foreach my $pid (sort keys %{$self->{worker_pids}}) {
        kill $sig, $pid;
    }
}

sub num_workers {
    my $self = shift;
    return scalar keys %{$self->{worker_pids}};
}

sub _decide_action {
    my $self = shift;
    return 1 if $self->num_workers < $self->max_workers;
    return 0;
}

sub _on_child_reap {
    my ($self, $exit_pid, $status) = @_;
    my $cb = $self->on_child_reap;
    if ($cb) {
        eval {
            $cb->($self, $exit_pid, $status);
        };
        # XXX - hmph, what to do here?
    }
}

# runs delayed tasks (if any) and returns how many seconds to wait
sub _handle_delayed_task {
    my $self = shift;
    while (1) {
        return undef
            unless $self->{delayed_task};
        my $timeleft = $self->{delayed_task_at} - Time::HiRes::time();
        return $timeleft
            if $timeleft > 0;
        $self->{delayed_task}->($self);
    }
}

# returns [sig_to_send, interval_bet_procs] or undef for given recved signal
sub _action_for {
    my ($self, $sig) = @_;
    my $t = $self->{trap_signals}{$sig}
        or return undef;
    $t = [$t, 0] unless ref $t;
    return $t;
}

sub wait_all_children {
    my ($self, $timeout) = @_;
    $self->{_no_adjust_until} = undef;

    my $call_wait = sub {
        my $blocking = shift;
        if (my ($pid) = $self->_wait($blocking)) {
            if (delete $self->{worker_pids}{$pid}) {
                $self->_on_child_reap($pid, $?);
            }
            return $pid;
        }
        return;
    };

    if ($timeout) {
        # the strategy is to use waitpid + sleep that gets interrupted by SIGCHLD
        # but since there is a race condition bet. waitpid and sleep, the argument
        # to sleep should be set to a small number (and we use 1 second).
        my $start_at = [Time::HiRes::gettimeofday];
        while ($self->num_workers != 0 && Time::HiRes::tv_interval($start_at) < $timeout) {
            unless ($call_wait->(0)) {
                sleep 1;
            }
        }
    } else {
        while ($self->num_workers != 0) {
            $call_wait->(1);
        }
    }
    return $self->num_workers;
}

sub _update_spawn_delay {
    my ($self, $secs) = @_;
    $self->{_no_adjust_until} = $secs ? Time::HiRes::time() + $secs : 0;
}

# wrapper function of Proc::Wait3::wait3 that executes delayed task if any.  assumes wantarray == 1
sub _wait {
    my ($self, $blocking) = @_;
    if (! $blocking) {
        $self->_handle_delayed_task();
        return Proc::Wait3::wait3(0);
    } else {
        my $delayed_task_sleep = $self->_handle_delayed_task();
        my $delayed_fork_sleep =
            $self->_decide_action() > 0 && defined $self->{_no_adjust_until}
                ? max($self->{_no_adjust_until} - Time::HiRes::time(), 0)
                    : undef;
        my $sleep_secs = min grep { defined $_ } (
            $delayed_task_sleep,
            $delayed_fork_sleep,
            $self->_max_wait(),
        );
        if (defined $sleep_secs) {
            # wait max sleep_secs or until signalled
            select(undef, undef, undef, $sleep_secs);
            if (my @r = Proc::Wait3::wait3(0)) {
                return @r;
            }
        } else {
            if (my @r = Proc::Wait3::wait3(1)) {
                return @r;
            }
        }
        return +();
    }
}

sub _max_wait {
    return undef;
}

1;

__END__

=head1 NAME

Parallel::Prefork - A simple prefork server framework

=head1 SYNOPSIS

  use Parallel::Prefork;
  
  my $pm = Parallel::Prefork->new({
    max_workers  => 10,
    trap_signals => {
      TERM => 'TERM',
      HUP  => 'TERM',
      USR1 => undef,
    }
  });
  
  while ($pm->signal_received ne 'TERM') {
    load_config();
    $pm->start(sub {
        ... do some work within the child process ...
    });
  }
  
  $pm->wait_all_children();

=head1 DESCRIPTION

C<Parallel::Prefork> is much like C<Parallel::ForkManager>, but supports graceful shutdown and run-time reconfiguration.

=head1 METHODS

=head2 new

instantiation.  Takes a hashref as an argument.  Recognized attributes are as follows.

=head3 max_workers

number of worker processes (default: 10)

=head3 spawn_interval

interval in seconds between spawning child processes unless a child process exits abnormally (default: 0)

=head3 err_respawn_interval

number of seconds to deter spawning of child processes after a worker exits abnormally (default: 1)

=head3 trap_signals

hashref of signals to be trapped.  Manager process will trap the signals listed in the keys of the hash, and send the signal specified in the associated value (if any) to all worker processes.  If the associated value is a scalar then it is treated as the name of the signal to be sent immediately to all the worker processes.  If the value is an arrayref the first value is treated the name of the signal and the second value is treated as the interval (in seconds) between sending the signal to each worker process.

=head3 on_child_reap

coderef that is called when a child is reaped. Receives the instance to
the current Parallel::Prefork, the child's pid, and its exit status.

=head3 before_fork

=head3 after_fork

coderefs that are called in the manager process before and after fork, if being set

=head2 start

The main routine.  There are two ways to use the function.

If given a subref as an argument, forks child processes and executes that subref within the child processes.  The processes will exit with 0 status when the subref returns.

The other way is to not give any arguments to the function.  The function returns undef in child processes.  Caller should execute the application logic and then call C<finish> to terminate the process.

The C<start> function returns true within manager process upon receiving a signal specified in the C<trap_signals> hashref.

=head2 finish

Child processes (when executed by a zero-argument call to C<start>) should call this function for termination.  Takes exit code as an optional argument.  Only usable from child processes.

=head2 signal_all_children

Sends signal to all worker processes.  Only usable from manager process.

=head2 wait_all_children()

=head2 wait_all_children($timeout)

Waits until all worker processes exit or timeout (given as an optional argument in seconds) exceeds.
The method returns the number of the worker processes still running.

=head1 AUTHOR

Kazuho Oku

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
