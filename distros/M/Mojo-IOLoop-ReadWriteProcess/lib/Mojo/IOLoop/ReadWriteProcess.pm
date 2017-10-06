package Mojo::IOLoop::ReadWriteProcess;

our $VERSION = '0.08';

use Mojo::Base 'Mojo::EventEmitter';
use Mojo::File 'path';
use Mojo::IOLoop::ReadWriteProcess::Exception;
use Mojo::IOLoop::ReadWriteProcess::Pool;
use Mojo::IOLoop::ReadWriteProcess::Queue;

our @EXPORT_OK = qw(parallel batch process pool queue);
use Exporter 'import';
use B::Deparse;
use Carp 'confess';
use IO::Handle;
use IO::Pipe;
use IO::Select;
use IPC::Open3;
use POSIX ":sys_wait_h";
use Symbol 'gensym';

use constant DEBUG => $ENV{MOJO_PROCESS_DEBUG};

has [
  qw(execute code process_id pidfile return_status),
  qw(channel_in channel_out write_stream read_stream error_stream),
  qw(_internal_err _internal_return _status)
];
has blocking_stop         => 0;
has max_kill_attempts     => 5;
has kill_sleeptime        => 1;
has sleeptime_during_kill => 1;
has args                  => sub { [] };
has separate_err          => 1;
has autoflush             => 1;
has error                 => sub { Mojo::Collection->new };
has set_pipes             => 1;
has verbose               => 1;
has internal_pipes        => 1;
has _deparse              => sub { B::Deparse->new }
  if DEBUG;

has _default_kill_signal => POSIX::SIGTERM;

# Override new() just to support sugar syntax
# so it is possible to do : process->new(sub{ print "Hello World\n" })->start->stop; and so on.
sub new {
  push(@_, code => splice @_, 1, 1) if ref $_[1] eq "CODE";
  return shift->SUPER::new(@_);
}

sub process { Mojo::IOLoop::ReadWriteProcess->new(@_) }
sub batch   { Mojo::IOLoop::ReadWriteProcess::Pool->new(@_) }
sub queue   { Mojo::IOLoop::ReadWriteProcess::Queue->new(@_) }

sub parallel {
  my $c = batch();
  $c->add(@_) for 1 .. +pop();
  return $c;
}

sub _diag {
  my ($self, @messages) = @_;
  my $caller = (caller(1))[3];
  print STDERR ">> ${caller}(): @messages\n" if ($self->verbose || DEBUG);
}

sub _open_collect_status {
  my $self = shift;
  return unless $self;
  $self->_status($?);
  $self->_clean_pidfile;
}

# Use open3 to launch external program.
sub _open {
  my ($self, @args) = @_;
  $self->_diag('Execute: ' . (join ', ', map { "'$_'" } @args)) if DEBUG;
  $SIG{CHLD} = sub {
    local ($!, $?);
    $self->emit('collect_status') while ((my $pid = waitpid(-1, WNOHANG)) > 0);
  };

  my ($wtr, $rdr, $err);
  $err = gensym;
  my $pid = open3($wtr, $rdr, ($self->separate_err) ? $err : undef, @args);

  die "Cannot create pipe: $!" unless defined $pid;
  $self->process_id($pid);

  # Defered collect of return status and removal of pidfile
  $self->once(collect_status => \&_open_collect_status);

  return $self unless $self->set_pipes();

  $self->read_stream(IO::Handle->new_from_fd($rdr, "r"));
  $self->write_stream(IO::Handle->new_from_fd($wtr, "w"));
  $self->error_stream(($self->separate_err) ?
      IO::Handle->new_from_fd($err, "r")
    : $self->write_stream);

  return $self;
}

sub _clean_pidfile { unlink(shift->pidfile) if $_[0]->pidfile }

sub _fork_collect_status {
  my $self = shift;
  return unless $self;
  my $return_reader;
  my $internal_err_reader;
  my @result_return;
  my @result_error;

  $self->_status($?);

  if ($self->_internal_return) {
    $return_reader
      = $self->_internal_return->isa("IO::Pipe::End") ?
      $self->_internal_return
      : $self->_internal_return->reader();
    $self->_new_err('Cannot read from return code pipe') && return
      unless IO::Select->new($return_reader)->can_read(10);
    @result_return = $return_reader->getlines();
    $self->return_status(@result_return) if @result_return;

    $self->_diag("Forked code Process Returns: " . join("\n", @result_return))
      if DEBUG;
  }
  if ($self->_internal_err) {
    $internal_err_reader
      = $self->_internal_err->isa("IO::Pipe::End") ?
      $self->_internal_err
      : $self->_internal_err->reader();
    $self->_new_err('Cannot read from errors code pipe') && return
      unless IO::Select->new($internal_err_reader)->can_read(10);
    @result_error = $internal_err_reader->getlines();
    push(
      @{$self->error},
      map { Mojo::IOLoop::ReadWriteProcess::Exception->new($_) } @result_error
    ) if @result_error;
    $self->_diag("Forked code Process Errors: " . join("\n", @result_error))
      if DEBUG;
  }

  $self->_clean_pidfile;
}

# Handle forking of code
sub _fork {
  my ($self, $code, @args) = @_;
  die "Can't spawn child without code" unless ref($code) eq "CODE";

  # STDIN/STDOUT/STDERR redirect.
  my ($input_pipe, $output_pipe, $output_err_pipe);

  # Separated handles that could be used for internal comunication.
  my ($channel_in, $channel_out);

  if ($self->set_pipes) {
    $input_pipe = IO::Pipe->new()
      or $self->_new_err('Failed creating input pipe');
    $output_pipe = IO::Pipe->new()
      or $self->_new_err('Failed creating output pipe');
    $output_err_pipe = IO::Pipe->new()
      or $self->_new_err('Failed creating output error pipe');
    $channel_in = IO::Pipe->new()
      or $self->_new_err('Failed creating Channel input pipe');
    $channel_out = IO::Pipe->new()
      or $self->_new_err('Failed creating Channel output pipe');
  }
  if ($self->internal_pipes) {
    my $internal_err = IO::Pipe->new()
      or $self->_new_err('Failed creating internal error pipe');
    my $internal_return = IO::Pipe->new()
      or $self->_new_err('Failed creating internal return pipe');

    # Internal pipes to retrieve error/return
    $self->_internal_err($internal_err);
    $self->_internal_return($internal_return);
  }

  # Defered collect of return status
  $self->once(collect_status => \&_fork_collect_status);

  if (DEBUG) {
    my $code_str = $self->_deparse->coderef2text($code);
    $self->_diag("Fork: $code_str");
  }

  my $pid = fork;
  die "Cannot fork: $!" unless defined $pid;

  if ($pid == 0) {
    local $SIG{CHLD};
    local $SIG{TERM} = sub { $self->_exit(1) };

    my $return;
    my $internal_err;

    if ($self->_internal_err) {
      $internal_err
        = $self->_internal_err->isa("IO::Pipe::End") ?
        $self->_internal_err
        : $self->_internal_err->writer();
      $internal_err->autoflush(1);
    }

    if ($self->_internal_return) {
      $return
        = $self->_internal_return->isa("IO::Pipe::End")
        ?
        $self->_internal_return
        : $self->_internal_return->writer();
      $return->autoflush(1);
    }
    else {
      eval { $internal_err->write("Can't setup return status pipe") };
    }

    # Set pipes to redirect STDIN/STDOUT/STDERR + channels if desired
    if ($self->set_pipes()) {
      my $stdout;
      my $stderr;
      my $stdin;

      $stdout = $output_pipe->writer() if $output_pipe;
      $stderr
        = (!$self->separate_err) ? $stdout
        : $output_err_pipe ? $output_err_pipe->writer()
        :                    undef;
      $stdin = $input_pipe->reader() if $input_pipe;
      open STDERR, ">&", $stderr
        or !!$internal_err->write($!)
        or $self->_diag($!);
      open STDOUT, ">&", $stdout
        or !!$internal_err->write($!)
        or $self->_diag($!);
      open STDIN, ">&", $stdin
        or !!$internal_err->write($!)
        or $self->_diag($!);

      $self->read_stream($stdin);
      $self->error_stream($stderr);
      $self->write_stream($stdout);

      $self->channel_in($channel_in->reader)   if $channel_in;
      $self->channel_out($channel_out->writer) if $channel_out;
      eval { $self->$_->autoflush($self->autoflush) }
        for qw(read_stream error_stream write_stream channel_in channel_out);
    }
    $! = 0;
    my $rt;
    eval { $rt = $code->($self, @args); };
    if ($internal_err) {
      $internal_err->write($@) if $@;
      $internal_err->write($!) if !$@ && $!;
    }
    $return->write($rt) if $return;
    $self->_exit($@ // $!);
  }
  $self->process_id($pid);

  $SIG{CHLD} = sub {
    local ($!, $?);
    $self->emit('collect_status') while ((my $pid = waitpid(-1, WNOHANG)) > 0);
  };

  return $self unless $self->set_pipes();

  $self->read_stream($output_pipe->reader) if $output_pipe;
  $self->error_stream((!$self->separate_err) ? $self->read_stream()
    : $output_err_pipe ? $output_err_pipe->reader()
    :                    undef);
  $self->write_stream($input_pipe->writer) if $input_pipe;
  $self->channel_in($channel_in->writer)   if $channel_in;
  $self->channel_out($channel_out->reader) if $channel_out;
  eval { $self->$_->autoflush($self->autoflush) }
    for qw(read_stream error_stream write_stream channel_in channel_out);

  return $self;
}

sub _new_err {
  my $self = shift;
  my $err  = Mojo::IOLoop::ReadWriteProcess::Exception->new(@_);
  push(@{$self->error}, $err);

  # XXX: Need to switch, we should emit one error at the time, and _shutdown
  # should emit just the ones wasn't emitted
  $self->emit(process_error => [$err]);
  return $self;
}

sub _exit {
  my $code = shift // 0;
  eval { POSIX::_exit($code); };
  exit($code);
}

sub wait {
  my $self = shift;
  sleep $self->sleeptime_during_kill while ($self->is_running);
  return $self;
}

sub wait_stop   { shift->wait->stop }
sub errored     { !!@{shift->error} ? 1 : 0 }
sub exit_status { defined $_[0]->_status ? shift->_status >> 8 : undef }
sub restart     { $_[0]->is_running ? $_[0]->stop->start : $_[0]->start; }
sub is_running  { $_[0]->process_id ? kill 0 => $_[0]->process_id : 0; }

sub write_pidfile {
  my ($self, $pidfile) = @_;
  $self->pidfile($pidfile) if $pidfile;
  return unless $self->pid;
  return unless $self->pidfile;

  path($self->pidfile)->spurt($self->pid);
  return $self;
}

# Convenience functions
sub _syswrite {
  my $stream = shift;
  return unless $stream;
  $stream->syswrite($_ . "\n") for @_;
}

sub _getline {
  return unless IO::Select->new($_[0])->can_read(10);
  shift->getline;
}

sub _getlines {
  return unless IO::Select->new($_[0])->can_read(10);
  wantarray ? shift->getlines : join '\n', @{[shift->getlines]};
}

# Write to the controlled-process STDIN
sub write_stdin {
  my ($self, @data) = @_;
  _syswrite($self->write_stream, @data);
  return $self;
}

sub write_channel {
  my ($self, @data) = @_;
  _syswrite($self->channel_in, @data);
  return $self;
}

# Get all lines from the current process output stream
sub read_all_stdout { _getlines(shift->read_stream) }

# Get all lines from the process channel
sub read_all_channel { _getlines(shift->channel_out); }
sub read_stdout      { _getline(shift->read_stream) }
sub read_channel     { _getline(shift->channel_out) }

sub read_all_stderr {
  return $_[0]->getline unless $_[0]->separate_err;
  _getlines(shift->error_stream);
}

# Get a line from the current process output stream
sub read_stderr {
  return $_[0]->getline unless $_[0]->separate_err;
  _getline(shift->error_stream);
}

sub start {
  my $self = shift;
  return $self if $self->is_running;
  die "Nothing to do" unless !!$self->execute || !!$self->code;

  my @args
    = $self->args ?
    ref($self->args) eq "ARRAY"
      ? @{$self->args}
      : $self->args
    : ();

  if ($self->code) {
    $self->_fork($self->code, @args);
  }
  elsif ($self->execute) {
    $self->_open($self->execute, @args);
  }

  $self->write_pidfile;
  $self->emit('start');

  return $self;
}

sub signal {
  my $self = shift;
  my $signal = shift // $self->_default_kill_signal;
  return unless $self->is_running;
  $self->_diag("Sending signal '$signal' to " . $self->process_id) if DEBUG;
  kill $signal => $self->process_id;
  return $self;
}

sub stop {
  my $self = shift;
  return $self->_shutdown unless $self->is_running;

  my $ret;
  my $attempt = 1;
  until ((defined $ret && $ret == $self->process_id)
      || !$self->is_running
      || $attempt > $self->max_kill_attempts)
  {
    $self->_diag("attempt ($attempt/"
        . $self->max_kill_attempts
        . ") to kill process: "
        . $self->pid)
      if DEBUG;
    sleep $self->sleeptime_during_kill if $self->sleeptime_during_kill;
    $self->signal();
    $ret = waitpid($self->process_id, WNOHANG);
    $self->_status($?);
    $attempt++;
  }

  sleep $self->kill_sleeptime if $self->kill_sleeptime;

  if ($self->blocking_stop && $self->is_running) {
    $self->_diag(
      "Could not kill process id: " . $self->process_id . " going for SIGKILL")
      if DEBUG;
    $self->signal(POSIX::SIGKILL);
    waitpid($self->process_id, 0);
    $self->_status($?);
  }
  elsif ($self->is_running) {
    $self->_diag("Could not kill process id: " . $self->process_id) if DEBUG;
    $self->_new_err('Could not kill process');
  }

  return $self->_shutdown;
}

sub _shutdown {
  my $self = shift;
  $self->emit('collect_status') if !defined $self->_status;
  $self->_clean_pidfile;
  $self->emit('process_error', $self->error)
    if $self->error && $self->error->size > 0;
  $self->emit('stop');
  return $self;
}

sub DESTROY { +shift()->_shutdown; }

# General alias
*pid  = \&process_id;
*died = \&_errored;
*diag = \&_diag;
*pool = \&batch;

# Aliases - write
*write         = \&write_stdin;
*stdin         = \&write_stdin;
*channel_write = \&write_channel;

# Aliases - read
*read             = \&read_stdout;
*stdout           = \&read_stdout;
*getline          = \&read_stdout;
*stderr           = \&read_stderr;
*err_getline      = \&read_stderr;
*channel_read     = \&read_channel;
*read_all         = \&read_all_stdout;
*getlines         = \&read_all_stdout;
*stderr_all       = \&read_all_stderr;
*err_getlines     = \&read_all_stderr;
*channel_read_all = \&read_all_channel;

# Aliases - IO::Handle
*stdin_handle        = \&write_stream;
*stdout_handle       = \&read_stream;
*stderr_handle       = \&error_stream;
*channe_write_handle = \&channel_in;
*channel_read_handle = \&channel_out;

1;


=encoding utf-8

=head1 NAME

Mojo::IOLoop::ReadWriteProcess - Execute external programs or internal code blocks as separate process.

=head1 SYNOPSIS

    use Mojo::IOLoop::ReadWriteProcess;

    # Code fork
    my $process = Mojo::IOLoop::ReadWriteProcess->new(sub { print "Hello\n" });
    $process->start();
    print "Running\n" if $process->is_running();
    $process->getline(); # Will return "Hello\n"
    $process->pid(); # Process id
    $process->stop();
    $process->wait_stop(); # if you intend to wait its lifespan

    # Methods can be chained, thus this is valid:
    use Mojo::IOLoop::ReadWriteProcess qw(process);
    my $output = process( sub { print "Hello\n" } )->start()->wait_stop->getline;

    # Handles seamelessy also external processes:
    my $process = process(execute=> '/path/to/bin' )->args(qw(foo bar baz));
    $process->start();
    my $line_output = $process->getline();
    my $pid = $process->pid();
    $process->stop();
    my @errors = $process->error;

    # Get process return value
    $process = process( sub { return "256"; } )->start()->wait_stop;
    # We need to stop it to retrieve the exit status
    my $return = $process->return_status;

    # We can access directly to handlers from the object:
    my $stdout = $process->read_stream;
    my $stdin = $process->write_stream;
    my $stderr = $process->error_stream;

    # So this works:
    print $stdin "foo bar\n";
    my @lines = <$stdout>;

    # There is also an alternative channel of communication (just for forked processes):
    my $channel_in = $process->channel_in; # write to the child process
    my $channel_out = $process->channel_out; # read from the child process
    $process->channel_write("PING"); # convenience function

=head1 DESCRIPTION

Mojo::IOLoop::ReadWriteProcess is yet another process manager.

=head1 EVENTS

L<Mojo::IOLoop::ReadWriteProcess> inherits all events from L<Mojo::EventEmitter> and can emit
the following new ones.

=head2 process_error

 $process->on(process_error => sub {
   my ($e) = @_;
   my @errors = @{$e};
 });

Emitted when the process produce errors.


=head2 start

 $process->on(start => sub {
   my ($process) = @_;
   $process->is_running();
 });

Emitted when the process starts.

=head2 stop

 $process->on(stop => sub {
   my ($process) = @_;
   $process->restart();
 });

Emitted when the process stops.

=head1 ATTRIBUTES

L<Mojo::IOLoop::ReadWriteProcess> inherits all attributes from L<Mojo::EventEmitter> and implements
the following new ones.

=head2 execute

    use Mojo::IOLoop::ReadWriteProcess;
    my $process = Mojo::IOLoop::ReadWriteProcess->new(execute => "/usr/bin/perl");
    $process->start();
    $process->on( stop => sub { print "Process: ".(+shift()->pid)." finished"; } );
    $process->stop();

C<execute> should contain the external program that you wish to run.

=head2 code

    use Mojo::IOLoop::ReadWriteProcess;
    my $process = Mojo::IOLoop::ReadWriteProcess->new(code => sub { print "Hello" } );
    $process->start();
    $process->on( stop => sub { print "Process: ".(+shift()->pid)." finished"; } );
    $process->stop();

It represent the code you want to run in background.

You do not need to specify C<code>, it is implied if no arguments is given.

    my $process = Mojo::IOLoop::ReadWriteProcess->new(sub { print "Hello" });
    $process->start();
    $process->on( stop => sub { print "Process: ".(+shift()->pid)." finished"; } );
    $process->stop();

=head2 args

    use Mojo::IOLoop::ReadWriteProcess;
    my $process = Mojo::IOLoop::ReadWriteProcess->new(code => sub { print "Hello ".shift() }, args => "User" );
    $process->start();
    $process->on( stop => sub { print "Process: ".(+shift()->pid)." finished"; } );
    $process->stop();

    # The process will print "Hello User"

Array or arrayref of options to pass by to the external binary or the code block.

=head2 blocking_stop

    use Mojo::IOLoop::ReadWriteProcess;
    my $process = Mojo::IOLoop::ReadWriteProcess->new(code => sub { print "Hello" }, blocking_stop => 1 );
    $process->start();
    $process->on( stop => sub { print "Process: ".(+shift()->pid)." finished"; } );
    $process->stop(); # Will wait indefinitely until the process is stopped

Set it to 1 if you want to do blocking stop of the process.

=head2 max_kill_attempts

    use Mojo::IOLoop::ReadWriteProcess;
    my $process = Mojo::IOLoop::ReadWriteProcess->new(code => sub { print "Hello" }, max_kill_attempts => 50 );
    $process->start();
    $process->on( stop => sub { print "Process: ".(+shift()->pid)." finished"; } );
    $process->stop(); # It will attempt to send SIGTERM 50 times.

Defaults to C<5>, is the number of attempts before bailing out.

It can be used with blocking_stop, so if the number of attempts are exhausted,
a SIGKILL and waitpid will be tried at the end.

=head2 kill_sleeptime

Defaults to C<1>, it's the seconds to wait before attempting SIGKILL when blocking_stop is setted to 1.

=head2 separate_err

Defaults to C<1>, it will create a separate channel to intercept process STDERR,
otherwise it will be redirected to STDOUT.

=head2 verbose

Defaults to C<1>, it indicates message verbosity.

=head2 set_pipes

Defaults to C<1>, If enabled, additional pipes for process communication are automatically set up.


=head2 internal_pipes

Defaults to C<1>, If enabled, additional pipes for retreiving process return and errors are set up.
Note: If you disable that, the only information provided by the process will be the exit_status.

=head2 autoflush

Defaults to C<1>, If enabled autoflush of handlers is enabled automatically.

=head2 error

Returns a L<Mojo::Collection> of errors.
Note: errors that can be captured only at the end of the process

=head1 METHODS

L<Mojo::IOLoop::ReadWriteProcess> inherits all methods from L<Mojo::EventEmitter> and implements
the following new ones.

=head2 start()

    use Mojo::IOLoop::ReadWriteProcess qw(process);
    my $p = process(sub {
                          print STDERR "Boo\n"
                      } )->start;

Starts the process

=head2 stop()

    use Mojo::IOLoop::ReadWriteProcess qw(process);
    my $p = process( execute => "/path/to/bin" )->start->stop;

Stop the process. Unless you use C<wait_stop()>, it will attempt to kill the process
without waiting the process to finish. By defaults it send C<SIGTERM> to the child.
You can change that by defining the internal attribute C<_default_kill_signal>.
Note, if you want to be *sure* that the process gets killed, you can enable the
C<blocking_stop> attribute, that will attempt to send C<SIGKILL> after C<max_kill_attempts>
is reached.

=head2 restart()

    use Mojo::IOLoop::ReadWriteProcess qw(process);
    my $p = process( execute => "/path/to/bin" )->restart;

It restarts the process if stopped, or if already running, it stops it first.

=head2 is_running()

    use Mojo::IOLoop::ReadWriteProcess qw(process);
    my $p = process( execute => "/path/to/bin" )->start;
    $p->is_running;

Boolean, it inspect if the process is currently running or not.

=head2 exit_status()

    use Mojo::IOLoop::ReadWriteProcess qw(process);
    my $p = process( execute => "/path/to/bin" )->start;

    $p->wait_stop->exit_status;

Inspect the process exit status, it does the shifting magic, to access to the real value
call C<_status()>.

=head2 return_status()

    use Mojo::IOLoop::ReadWriteProcess qw(process);
    my $p = process( sub { return 42 } )->start;

    my $s = $p->wait_stop->return_status; # 42

Inspect the codeblock return.

=head2 diag()

    use Mojo::IOLoop::ReadWriteProcess qw(process);
    my $p = process(sub { print "Hello\n" });
    $p->on( stop => sub { shift->diag("Done!") } );
    $p->start->wait_stop;

Internal function to print information to STDERR if verbose attribute is set or either DEBUG mode enabled.
You can use it if you wish to display information on the process status.

=head2 wait()

    use Mojo::IOLoop::ReadWriteProcess qw(process);
    my $p = process(sub { print "Hello\n" })->wait;
    # ... here now you can mangle $p handlers and such

Waits until the process finishes, but does not performs cleanup operations (until stop is called).

=head2 wait_stop()

    use Mojo::IOLoop::ReadWriteProcess qw(process);
    my $p = process(sub { print "Hello\n" })->start->wait_stop;
    # $p is not running anymore, and all possible events have been granted to be emitted.

Waits until the process finishes, and perform cleanup operations.

=head2 errored()

    use Mojo::IOLoop::ReadWriteProcess qw(process);
    my $p = process(sub { die "Nooo" })->start->wait_stop;
    $p->errored; # will return "1"

Returns a boolean indicating if the process had errors or not.

=head2 write_pidfile()

    use Mojo::IOLoop::ReadWriteProcess qw(process);
    my $p = process(sub { die "Nooo" } );
    $p->pidfile("foobar");
    $p->start();
    $p->write_pidfile();

Forces writing PID of process to specified pidfile in the attributes of the object.
Useful only if the process have been already started, otherwise if a pidfile it's supplied
as attribute, it will be done automatically.

=head2 write_stdin()

    use Mojo::IOLoop::ReadWriteProcess qw(process);
    my $p = process(sub { my $a = <STDIN>; print STDERR "Hello my name is $a\n"; } )->start;
    $p->write_stdin("Larry");
    $p->read_stderr; # process STDERR will contain: "Hello my name is Larry\n"

Write data to process STDIN.

=head2 write_channel()

    use Mojo::IOLoop::ReadWriteProcess qw(process);
    my $p = process(sub {
                          my $self = shift;
                          my $parent_output = $self->channel_out;
                          my $parent_input  = $self->channel_in;

                          while(defined(my $line = <$parent_input>)) {
                            print $parent_output "PONG\n" if $line =~ /PING/i;
                          }
                      } )->start;
    $p->write_channel("PING");
    my $out = $p->read_channel;
    # $out is PONG
    my $child_output = $p->channel_out;
    while(defined(my $line = <$child_output>)) {
        print "Process is replying back with $line!\n";
        $p->write_channel("PING");
    }

Write data to process channel. Note, it's not STDIN, neither STDOUT, it's a complete separate channel
dedicated to parent-child communication.
In the parent process, you can access to the same pipes (but from the opposite direction):

    my $child_output = $self->channel_out;
    my $child_input  = $self->channel_in;

=head2 read_stdout()

    use Mojo::IOLoop::ReadWriteProcess qw(process);
    my $p = process(sub {
                          print "Boo\n"
                      } )->start;
    $p->read_stdout;

Gets a single line from process STDOUT.

=head2 read_channel()

    use Mojo::IOLoop::ReadWriteProcess qw(process);
    my $p = process(sub {
                          my $self = shift;
                          my $parent_output = $self->channel_out;
                          my $parent_input  = $self->channel_in;

                          print $parent_output "PONG\n";
                      } )->start;
    $p->read_channel;

Gets a single line from process channel.

=head2 read_stderr()

    use Mojo::IOLoop::ReadWriteProcess qw(process);
    my $p = process(sub {
                          print STDERR "Boo\n"
                      } )->start;
    $p->read_stderr;

Gets a single line from process STDERR.

=head2 read_all_stdout()

    use Mojo::IOLoop::ReadWriteProcess qw(process);
    my $p = process(sub {
                          print "Boo\n"
                      } )->start;
    $p->read_all_stdout;

Gets all the STDOUT output of the process.

=head2 read_all_channel()

    use Mojo::IOLoop::ReadWriteProcess qw(process);
    my $p = process(sub {
                          shift->channel_out->write("Ping")
                      } )->start;
    $p->read_all_channel;

Gets all the channel output of the process.

=head2 read_all_stderr()

    use Mojo::IOLoop::ReadWriteProcess qw(process);
    my $p = process(sub {
                          print STDERR "Boo\n"
                      } )->start;
    $p->read_all_stderr;

Gets all the STDERR output of the process.

=head2 signal()

    use Mojo::IOLoop::ReadWriteProcess qw(process);
    use POSIX;
    my $p = process( execute => "/path/to/bin" )->start;

    $p->signal(POSIX::SIGKILL);

Send a signal to the process

=head1 EXPORTS

=head2 parallel()

    use Mojo::IOLoop::ReadWriteProcess qw(parallel);
    my $pool = parallel sub { print "Hello\n" } => 5;
    $pool->start();
    $pool->on( stop => sub { print "Process: ".(+shift()->pid)." finished"; } );
    $pool->stop();

Returns a L<Mojo::IOLoop::ReadWriteProcess::Pool> object that represent a group of processes.

It accepts the same arguments as L<Mojo::IOLoop::ReadWriteProcess>, and the last one represent the number of processes to generate.

=head2 batch()

    use Mojo::IOLoop::ReadWriteProcess qw(batch);
    my $pool = batch;
    $pool->add(sub { print "Hello\n" });
    $pool->on(stop => sub { shift->_diag("Done!") })->start->wait_stop;

Returns a L<Mojo::IOLoop::ReadWriteProcess::Pool> object generated from supplied arguments.
It accepts as input the same parameter of L<Mojo::IOLoop::ReadWriteProcess::Pool> constructor ( see parallel() ).

=head2 process()

    use Mojo::IOLoop::ReadWriteProcess qw(process);
    my $p = process sub { print "Hello\n" };
    $p->start()->wait_stop;

or even:

    process(sub { print "Hello\n" })->start->wait_stop;

Returns a L<Mojo::IOLoop::ReadWriteProcess> object that represent a process.

It accepts the same arguments as L<Mojo::IOLoop::ReadWriteProcess>.

=head2 queue()

    use Mojo::IOLoop::ReadWriteProcess qw(queue);
    my $q = queue;
    $q->add(sub { return 42 } );
    $q->consume;

Returns a L<Mojo::IOLoop::ReadWriteProcess::Queue> object that represent a queue.

=head1 DEBUGGING

You can set the MOJO_EVENTEMITTER_DEBUG environment variable to get some advanced diagnostics information printed to STDERR.

    MOJO_EVENTEMITTER_DEBUG=1

Also, you can set MOJO_PROCESS_DEBUG environment variable to get diagnostics about the process execution.

    MOJO_PROCESS_DEBUG=1

=head1 LICENSE

Copyright (C) Ettore Di Giacinto.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Ettore Di Giacinto E<lt>edigiacinto@suse.comE<gt>

=cut
