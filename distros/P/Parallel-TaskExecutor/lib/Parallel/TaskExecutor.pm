package Parallel::TaskExecutor;

use strict;
use warnings;
use utf8;

use Data::Dumper;
use English;
use Exporter 'import';
use Hash::Util 'lock_keys';
use IO::Pipe;
use Log::Any::Simple ':default';
use Parallel::TaskExecutor::Task;
use Readonly;
use Scalar::Util 'weaken';
use Time::HiRes 'usleep';

our @EXPORT_OK = qw(default_executor);
our %EXPORT_TAGS = (all => \@EXPORT_OK);

our @CARP_NOT = 'Parallel::TaskExecutor::Task';

our $VERSION = '0.05';  # Remember to change it in Task.pm too.

=pod

=encoding utf8

=head1 NAME

Parallel::TaskExecutor

=head1 SYNOPSIS

Cross-platform executor for parallel tasks executed in forked processes.

  my $executor = Parallel::TaskExecutor->new();
  my $task = $executor->run(sub { return 'foo' });
  $task->wait();
  is($task->data(), 'foo');

=head1 DESCRIPTION

This module provides a simple interface to run Perl code in forked processes and
receive the result of their processing. This is quite similar to
L<Parallel::ForkManager> with a different OO approach, more centered on the task
object that can be seen as a very lightweight promise.

Note that this module uses L<Log::Any::Simple> for its logging. So you can use
any L<Log::Any::Adapter> to consume its log. For example, put the following in
your main application file:

  use Log::Any::Adapter ('Stderr');

In addition, when testing a module that uses B<Parallel::TaskExecutor>, if
you’re using L<Test2>, you should add the following line at the beginning of
each of your tests to initialize the multi-process feature of the test
framework:

  use Test2::IPC;

=head1 METHODS

=head2 constructor

  my $executor = Parallel::TaskExecutor->new(%options);

Create a new executor. The main possible option is:

=over 4

=item *

B<max_parallel_tasks> (default = 4): how many different sub-processes
can be created in total by this object instance.

=back

But all the options that can be passed to run() can also be passed to new() and
they will apply to all the calls to this object (unless overridden in a specific
call to run()).

=cut

Readonly::Scalar my $default_max_parallel_tasks => 4;

sub new {
  my ($class, %options) = @_;
  my $this = bless {
    max_parallel_tasks => $options{max_parallel_tasks} // $default_max_parallel_tasks,
    options => \%options,
    current_tasks => 0,
    # Stores a weak reference to all the non-done tasks that have another
    # reference held by the user.
    tasks => {},
    # Stores a non-weak reference to all the non-done tasks that would have went
    # out of scope otherwise.
    zombies => {},
    pid => $PID,
  }, $class;
  lock_keys(%{$this});
  return $this;
}

=pod

=head2 destructor

When a B<Parallel::TaskExecutor> goes out of scope, its destructor will wait
for all the tasks that it started and for which the returned task object is not
live. This is a complement to the destructor of L<Parallel::TaskExecutor::Task>
which waits for a task to be done if its parent executor is no longer live.

=cut

sub DESTROY {
  my ($this) = @_;
  # TODO: consider if this is the correct thing to do or if we should instead
  # wait for the task here.
  return if ${^GLOBAL_PHASE} eq 'DESTRUCT';
  return unless $PID == $this->{pid};
  while (my (undef, $c) = each %{$this->{zombies}}) {
    # TODO: add an option to abandon the children (but they must be awaited by
    # someone).
    $c->wait();
  }
  return;
}

=pod

=head2 default_executor()

  my $executor = default_executor();

Returns a default B<Parallel::TaskExecutor> object with an unspecified
parallelism (guaranteed to be more than 1 parallel tasks).

=cut

my $default_executor = Parallel::TaskExecutor->new(max_parallel_tasks => 10);

sub default_executor {
  return $default_executor;
}

my $task_count = 0;

# This is a very conservative estimates. On modern system the limit is 64kB.
Readonly::Scalar my $default_response_channel_buffer_size => 4096;

sub _fork_and_run {
  my ($this, $sub, %options) = @_;
  my $miso = IO::Pipe->new();  # From the child to the parent.
  my $task_id = $task_count++;
  trace("Will fork for task ${task_id}");
  my $pid = fork();
  fatal('Cannot fork a sub-process') unless defined $pid;
  $this->{current_tasks}++ unless $options{untracked};

  if ($pid == 0) {
    # In the child task
    # TODO: the code here should be moved to the Task class. It would be clearer
    # and probably allow a better separation of the properties of the Task class
    # between those used by the executor or those used by the task.
    $miso->writer();
    trace("Starting child task (id == ${task_id}) in process ${PID}");

    if (exists $options{SIG}) {
      while (my ($k, $v) = each %{$options{SIG}}) {
        $SIG{$k} = $v;  ## no critic (RequireLocalizedPunctuationVars)
      }
    }

    print $miso "ready\n";
    $miso->flush();

    my @out;
    trace("Starting user code in child task (id == ${task_id}) in process ${PID}");
    if ($options{scalar}) {
      @out = scalar($sub->());
    } else {
      @out = $sub->();
    }
    trace("Serializing task result in child task (id == ${task_id}) in process ${PID}");
    my $serialized_out;
    {
      local $Data::Dumper::Indent = 0;
      local $Data::Dumper::Purity = 1;
      local $Data::Dumper::Sparseseen = 1;
      local $Data::Dumper::Varname = 'TASKEXECUTORVAR';
      $serialized_out = Dumper(\@out);
    }
    trace("Emitting task result in child task (id == ${task_id}) in process ${PID}");
    my $size = length($serialized_out);
    my $max_size = $default_response_channel_buffer_size;
    warning("Data returned by process ${PID} for task ${task_id} is too large (%dB)", $size)
        if $size > $max_size;
    # Nothing will be read before the process terminate, so the data
    print $miso scalar($serialized_out);
    trace("Done sending result in child task (id == ${task_id}) in process ${PID}");
    close $miso or warning("Can’t close writer side of child task miso channel: ${ERRNO}");
    trace("Exiting child task (id == ${task_id}) in process ${PID}");
    exit 0;
  }

  # Still in the parent task
  trace("Started child task (id == ${task_id}) with pid == ${pid}");
  $miso->reader();
  my $task = Parallel::TaskExecutor::Task->new(
    untracked => $options{untracked},
    task_id => $task_id,
    runner => $this,
    state => 'running',
    channel => $miso,
    pid => $pid,
    parent => $PID,
    catch_error => $options{catch_error},);
  weaken($task->{runner});
  $this->{tasks}{$task} = $task;
  weaken($this->{tasks}{$task});

  my $ready = <$miso>;
  fatal(
    "Got unexpected data during ready check of child task (id == ${task_id}) with pid == ${pid}: $ready"
  ) unless $ready eq "ready\n";

  if ($options{wait}) {
    trace("Waiting for child $pid to exit (task id == ${task_id})");
    $task->wait();
    trace("OK, child $pid exited (task id == ${task_id})");
  }
  return $task;
}

=pod

=head2 run()

  my $task = $executor->run($sub, %options);

Fork a new child process and use it to execute the given I<$sub>. The execution
can be tracked using the returned I<$task> object of type
L<Parallel::TaskExecutor::Task>.

If there are already B<max_parallel_tasks> tasks running, then the call will
block until the count of running tasks goes below that limit.

The possible options are the following:

=over 4

=item *

B<SIG> (hash-reference): if provided, this specifies a set of signal
handlers to be set in the child process. These signal handler are installed
before the provided I<$sub> is called and before the call to run() returns.

=item *

B<wait>: if set to a true value, the call to run will wait for the task
to be complete before returning (this means that C<$task->done()> will always be
true when you get the task).

=item *

B<catch_error>: by default, a failure of a child task will abort the parent
process. If this option is set to true, the failure will be reported by the task
instead.

=item *

B<scalar>: when set to true, the I<$sub> is called in scalar context. Otherwise
it is called in list context.

=item *

B<forced>: if set to true, the task will be run immediately, even if this means
exceeding the value for the B<max_parallel_tasks> passed to the constructor.
Note however that the task will still increase by one the number of running
tasks tracked by the executor (unless B<untracked> is also set to true).

=item *

B<untracked>: if set to true, the task will not increase the number of running
task counted by the executor. However, the call to run() might still be blocked
if the number of outstanding tasks exceeds B<max_parallel_tasks> (unless
B<forced> is set to true too).

=back

=cut

Readonly::Scalar my $busy_loop_wait_time_us => 1000;

sub run {
  my ($this, $sub, %options) = @_;
  %options = (%{$this->{options}}, %options);
  # TODO: add an option to always call _remove_done_tasks here, to cleanup.
  while (!$options{forced} && $this->{current_tasks} >= $this->{max_parallel_tasks}) {
    $this->_remove_done_tasks();
    usleep($busy_loop_wait_time_us);
  }
  return $this->_fork_and_run($sub, %options);
}

=pod

=head2 run_now()

  my $data = $executor->run_now($sub, %options);

Runs the given I<$sub> in a forked process and waits for its result. This never
blocks (the I<$sub> is run even if the executor max parallelism is already
reached) and this does not increase the counted parallelism of the executor
either (in effect the B<untracked>, B<forced>, and B<wait> options are set to
true).

In addition, the B<scalar> option is set to true if this method is called in
scalar context, unless that option was explicitly passed to the run_now() call.

=cut

sub run_now {
  my ($this, $sub, %options) = @_;
  $options{scalar} = 1 unless exists $options{scalar} || wantarray;
  my $task = $this->_fork_and_run($sub, %options, untracked => 1, wait => 1);
  $task->wait();
  return $task->data();
}

=pod

=head2 wait()

  $executor->wait();

Waits for all the outstanding tasks to terminate. This waits for all the tasks
independently of whether their L<Parallel::TaskExecutor::Task> object is still
live.

=cut

sub wait {  ## no critic (ProhibitBuiltinHomonyms)
  my ($this) = @_;
  my $nb_children = $this->{current_tasks};
  return unless $nb_children;
  debug("Waiting for ${nb_children} running tasks...");
  while (my (undef, $c) = each %{$this->{zombies}}) {
    # $c is never weak here and wait() will also not delete from this hash
    # itself
    $c->wait();
    delete $this->{zombies}{$c};  # $c is both the key and the value.
  }
  while (my (undef, $c) = each %{$this->{tasks}}) {
    # $c can be a weak reference, but it should never be undef because the task
    # will remove itself from this hash when it’s done (and the reference is
    # unweakened when it’s the last reference to the task).
    # $c->wait() will delete this entry from the hash, but this is legal when
    # looping with each.
    $c->wait();
  }
  return;
}

=pod

=head2 set_max_parallel_tasks()

  $executor->set_max_parallel_tasks(N)

Sets the B<max_parallel_tasks> option of the executor.

=cut

sub set_max_parallel_tasks {
  my ($this, $max_parallel_tasks) = @_;
  $this->{max_parallel_tasks} = $max_parallel_tasks;
  return;
}

sub _remove_done_tasks {
  my ($this) = @_;
  my $done = 0;
  while (my (undef, $c) = each %{$this->{zombies}}) {
    if ($c->_try_wait()) {
      delete $this->{zombies}{$c};
      $done += 1;
    }
  }
  while (my (undef, $c) = each %{$this->{tasks}}) {
    # See the comment in wait()
    $done += $c->_try_wait() ? 1 : 0;
  }
  debug("Removed ${done} done tasks") if $done;
  return;
}

=pod

=head2 signal_all()

  $executor->signal_all('HUP');

Sends the given signal all the tasks. See L<Parallel::TaskExecutor::Task/signal>
for more details.

=cut

sub signal_all {
  my ($this, $signal) = @_;
  # See the comment in wait() for why $c can never be undef although it is a weak
  # reference.
  kill $signal, map { $_->pid() } values %{$this->{tasks}}, values %{$this->{zombies}};
  return;
}

=pod

=head2 kill_all()

  $executor->kill_all();

Same as L<signal_all()|/signal_all> but sends the C<SIGKILL> signal by default.
You can still pass a specific signal if you want.

=cut

sub kill_all {
  my ($this, $signal) = (@_, 'KILL');
  return $this->signal_all($signal);
}

1;

=pod

=head1 CAVEATS AND TODOS

=over 4

=item *

The data returned by a child task can only have a limited size (4kB as of
writing this). In a future release, we may switch to using temporary files to
pass the result when this limit is reached.

=item *

There is currently no support to setup uni or bi-directional communication
channel with the child task. This must be done manually by the user.

=back

=head1 AUTHOR

This program has been written by L<Mathias Kende|mailto:mathias@cpan.org>.

=head1 LICENSE

Copyright 2024 Mathias Kende

This program is distributed under the MIT (X11) License:
L<http://www.opensource.org/licenses/mit-license.php>

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without
restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following
conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.

=head1 SEE ALSO

=over 4

=item L<AnyEvent>

=item L<IPC::Run>

=item L<Parallel::ForkManager>

=item L<Promise::XS>

=back

=cut
