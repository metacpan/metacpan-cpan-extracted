package Parallel::TaskExecutor::Task;

use strict;
use warnings;
use utf8;

use English;
use Hash::Util 'lock_keys';
use Log::Any::Simple ':default';
use POSIX ':sys_wait_h';
use Scalar::Util 'unweaken';

our $VERSION = '0.05';  # Remember to change it in TaskExecutor.pm too.

=pod

=encoding utf8

=head1 NAME

Parallel::TaskExecutor::Tasks

=head1 SYNOPSIS

A simple task (or promise) class for the  L<Parallel::TaskExecutor> package.

  my $executor = Parallel::TaskExecutor->new();
  my $task = $executor->run(sub { return 'foo' });
  $task->wait();
  is($task->data(), 'foo');

=head1 DESCRIPTION

The tasks that this class exposes are lightweight promises that can be used to
wait for the end of the parallel processing and read the result of that
processing.

=head1 METHODS

=head2 constructor

The constructor of this class is private, it can only be built by
L<Parallel::TaskExecutor> through a call to L<run()|Parallel::TaskExecutor/run>.

=cut

sub new {
  my ($class, %data) = @_;
  # %data can be anything that is needed by Parallel::TaskExecutor. However the
  # following values are used by Parallel::TaskExecutor::Task too:
  # - state: one of new, running, done
  # - pid: the PID of the task
  # - parent: the PID of the parent process. We don’t do anything if we’re
  #   called in a different process.
  # - task_id: arbitrary identifier for the task
  # - runner: Parallel::TaskExecutor runner for this task, kept as a weak
  #   reference
  # - untracked: don’t count this task toward the task limit of its runner
  # - catch_error: if false, a failed task will abort the parent.
  # - channel: may be set to read the data produced by the task
  # - data: will contain the data read from the channel.
  my $this = bless {%data, data => undef, error => undef}, $class;
  lock_keys(%{$this});
  return $this;
}

=pod

=head2 destructor

The destructor of a B<Parallel::TaskExecutor::Task> object will block until the
task is done if you no longer keep a reference to its parent
L<Parallel::TaskExecutor> object. If the parent executor is still live, then
that object will be responsible to wait for the end of the task (either through
an explicit call to L<wait()|Parallel::TaskExecutor/wait> or in its destructor).

=cut

sub DESTROY {
  my ($this) = @_;
  # TODO: consider if this is the correct thing to do or if we should instead
  # wait for the task here.
  return if ${^GLOBAL_PHASE} eq 'DESTRUCT';
  return unless $PID == $this->{parent};
  # TODO: provide a system to not wait here, but defer that to the deletion of
  # the runner.
  if ($this->running()) {
    if ($this->{runner}) {
      trace("Deferring reaping of task $this->{task_id}");
      # We could unweaken the entry in the tasks hash, but it’s cleaner to have
      # only weak objects there, and non-weak objects in zombies (otherwise we
      # would need to rely on isweak in the TaskExecutor DESTROY method).
      $this->{runner}{zombies}{$this} = $this;
      delete $this->{runner}{tasks}{$this};
      # Once we are a zombie, we can be deleted only once done, so this code path
      # will not keep creating reference to the object.
    } else {
      $this->wait();
    }
  }
  return;
}

=pod

=head2 wait

  $task->wait();

Blocks until the task is done. When this function returns, it is guaranteed that
the task is in the I<done> state (that is, that done() will return true).

Returns a true value if the child task succeeded. If the task failed and
B<catch_error> was set in the parent executor when the
task started, then this method will return a false value.


=cut

sub wait {  ## no critic (ProhibitBuiltinHomonyms)
  my ($this) = @_;
  return if $this->{state} eq 'done';
  trace("Starting blocking waitpid($this->{pid})");
  local ($ERRNO, $CHILD_ERROR) = (0, 0);
  my $ret = waitpid($this->{pid}, 0);
  fatal("No children with pid $this->{pid} for task $this->{task_id}") if $ret == -1;
  fatal(
    "Incoherent PID returned by waitpid: actual $ret; expected $this->{pid} for task $this->{task_id}"
  ) if $ret != $this->{pid};
  $this->_process_done();
  return $this->{error} ? 0 : 1;
}

=pod

=head2 data

  my @data = $task->data();
  my $data = $task->data();

Returns the result value of a finished task (produced by the code-reference that
was passed to the run() call of the executor). If called in list context,
returns all the produced value. If called in scalar context, returns only the
first value. Note that the code-reference itself in the task has been called in
a list context by default, unless the B<scalar> option was passed to its
executor.

It is an error to call this method on a task that is still running. So you must
be sure that the task is done before you call it (either through a call to
wait() or to done() for example). See also the get() method which combines a
call to wait() and to data().

If the task failed and B<catch_error> was set in the parent executor when the
task started, then this method will die() with the child task error.

=cut

sub data {
  my ($this) = @_;
  fatal('Trying to read the data of a still running task') unless $this->done();
  die $this->{error} if defined $this->{error};  ## no critic (RequireCarping)
                                                 # TODO: we should have a variant for undef wantarray that does not setup
                                                 # the whole pipe to get the return data.
                                                 # Note: wantarray here is not necessarily the same as when the task was set
                                                 # up, it is the responsibility of the caller to set the 'scalar' option
                                                 # correctly.
  return wantarray ? @{$this->{data}} : $this->{data}[0];
}

=pod

=head2 running

  print "Still running\n" if $task->running();

Returns whether the task is still running.

=cut

sub running {
  my ($this) = @_;
  $this->_try_wait() if $this->{state} eq 'running';
  return $this->{state} eq 'running';
}

=pod

=head2 done

  print "Done\n" if $task->done();

Returns whether the task is done. This is guaranteed to always be the opposite
of done().

=cut

# This method is the opposite of running() because the task can only be in the
# state running or done once it has been returned to the caller.

sub done {
  my ($this) = @_;
  $this->_try_wait() if $this->{state} eq 'running';
  return $this->{state} eq 'done';
}

=pod

=head2 get

  my $data = $task->get();

Waits until the task is done and returns the result of the task. See the
documentation of the L<wait()|/wait> and L<data()|/data> methods for more
details, in particular regarding scalar and list context data.

=cut

sub get {
  my ($this) = @_;
  $this->wait();
  return $this->data();
}

sub _try_wait {
  my ($this) = @_;
  return if $this->{state} ne 'running';
  trace("Starting non blocking waitpid($this->{pid})");
  local ($ERRNO, $CHILD_ERROR) = (0, 0);
  my $pid = waitpid($this->{pid}, WNOHANG);
  if ($pid > 0 || $pid < -1) {  # Perl fake processes on Windows use negative PIDs.
                                # TODO: do the same validation on $pid than in the wait() method.
    $this->_process_done();
    return 1;
  }
  return;
}

sub _process_done {
  my ($this) = @_;
  $this->{state} = 'done';
  if ($this->{runner}) {
    $this->{runner}{current_tasks}-- unless $this->{untracked};
    delete $this->{runner}{tasks}{$this};  # might not exist if we are a zombie, this is fine.
  }
  if ($CHILD_ERROR) {
    if ($this->{catch_error}) {
      $this->{error} = "Child command failed: ${CHILD_ERROR}";
    } else {
      # Ideally, we should first wait for all child processes of all runners
      # before dying, to print the dying message last.
      error(
        "Child process (pid == $this->{pid}, task_id == $this->{task_id}) failed (${CHILD_ERROR})");
      exit 2;
    }
  } elsif ($this->{channel}) {
    local $INPUT_RECORD_SEPARATOR = undef;
    my $fh = $this->{channel};
    my $data = <$fh>;
    close $fh or warning("Cannot close task output channel: ${ERRNO}");
    {
      no strict;  ## no critic (ProhibitNoStrict)
      no warnings;  ## no critic (ProhibitNoWarnings)
      $this->{data} = eval $data;  ## no critic (ProhibitStringyEval)
    }
    fatal(
      "Cannot parse the output of child task $this->{task_id} (pid == $this->{pid}): ${EVAL_ERROR}")
        if $EVAL_ERROR;
  }
  trace("Child pid == $this->{pid} returned (task id == $this->{task_id})");
  trace("  --> current tasks == $this->{runner}{current_tasks}") if $this->{runner};
  return;
}

# Undocumented because there is too much risk that the behavior of the library
# would be broken if the user started doing weird thing with that.
sub pid {
  my ($this) = @_;
  return $this->{pid};
}

=pod

=head2 signal

  $task->signal('HUP');

Sends the given signal to the task. Signal can be anything accepted by the
L<kill()|/kill SIGNAL> method, so either a signal name or a signal number. See
L<kill()|/kill SIGNAL> for how to get the list of supported signals.

Note that even if the signal kills the task you should still in general wait()
for it at some point. Also, unless the task gracefully handles the signal, you
will probably need to pass the C<catch_error> option to the run() call when the
task is started, otherwise your whole program will be aborted.

=cut

sub signal {
  my ($this, $signal) = @_;
  return if $this->{state} ne 'running';
  trace("Sending signal ${signal} to process $this->{pid}");
  kill $signal, $this->{pid};
  return;
}

=pod

=head2 kill

  $task->kill();

This is a synonym of L<signal()>|/signal> but where the default argument is
C<SIGKILL>. You can still pass a different signal name if you want.

=cut

sub kill {  ## no critic (Subroutines::ProhibitBuiltinHomonyms)
  my ($this, $signal) = (@_, 'KILL');
  return $this->signal($signal);
}

1;
