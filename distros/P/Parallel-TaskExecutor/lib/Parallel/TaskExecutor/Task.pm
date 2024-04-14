package Parallel::TaskExecutor::Task;

use strict;
use warnings;
use utf8;

use English;
use Log::Log4perl;
use POSIX ':sys_wait_h';

our $VERSION = '0.01';

my $log = Log::Log4perl->get_logger();

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
  return bless {%data, log => $log}, $class;
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
      $this->{log}->trace("Deferring reaping of task $this->{task_id}");
      delete $this->{runner}{tasks}{$this};
      push @{$this->{runner}{zombies}}, $this;
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
  $this->{log}->trace("Starting blocking waitpid($this->{pid})");
  local ($ERRNO, $CHILD_ERROR) = (0, 0);
  my $ret = waitpid($this->{pid}, 0);
  $this->{log}->logdie("No children with pid $this->{pid} for task $this->{task_id}") if $ret == -1;
  $this->{log}->logdie(
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
  $this->{log}->logcroak('Trying to read the data of a still running task') unless $this->done();
  die $this->{error} if exists $this->{error};  ## no critic (RequireCarping)
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
documentation of the wait() and data() methods for more details, in particular
regarding scalar and list context data.

=cut

sub get {
  my ($this) = @_;
  $this->wait();
  return $this->data();
}

sub _try_wait {
  my ($this) = @_;
  return if $this->{state} ne 'running';
  $this->{log}->trace("Starting non blocking waitpid($this->{pid})");
  local ($ERRNO, $CHILD_ERROR) = (0, 0);
  if ((my $pid = waitpid($this->{pid}, WNOHANG)) > 0) {
    $this->_process_done();
  }
  return;
}

sub _process_done {
  my ($this) = @_;
  $this->{state} = 'done';
  if ($this->{runner}) {
    $this->{runner}{current_tasks}-- unless $this->{untracked};
    delete $this->{task}{$this};
  }
  if ($CHILD_ERROR) {
    if ($this->{catch_error}) {
      $this->{error} = "Child command failed: ${CHILD_ERROR}";
    } else {
      # Ideally, we should first wait for all child processes of all runners
      # before dying, to print the dying message last.
      $Log::Log4perl::LOGEXIT_CODE = 2;
      $this->{log}->logexit(
        "Child process (pid == $this->{pid}, task_id == $this->{task_id}) failed (${CHILD_ERROR})");
    }
  } elsif ($this->{channel}) {
    local $INPUT_RECORD_SEPARATOR = undef;
    my $fh = $this->{channel};
    my $data = <$fh>;
    close $fh or $this->{log}->logcluck("Cannot close task output channel: ${ERRNO}");
    {
      no strict;  ## no critic (ProhibitNoStrict)
      no warnings;  ## no critic (ProhibitNoWarnings)
      $this->{data} = eval $data;  ## no critic (ProhibitStringyEval)
    }
    $this->{log}->logdie(
      "Cannot parse the output of child task $this->{task_id} (pid == $this->{pid}): ${EVAL_ERROR}")
        if $EVAL_ERROR;
  }
  $this->{log}->trace("Child pid == $this->{pid} returned (task id == $this->{task_id})");
  $this->{log}->trace("  --> current tasks == $this->{runner}{current_tasks}") if $this->{runner};
  return;
}

sub pid {
  my ($this) = @_;
  return $this->{pid};
}

1;
