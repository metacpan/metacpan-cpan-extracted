package Mojo::Server::DaemonControl;
use Mojo::Base 'Mojo::EventEmitter', -signatures;

use File::Basename qw(basename);
use File::Spec::Functions qw(tmpdir);
use IO::Select;
use IO::Socket::UNIX;
use Mojo::File qw(curfile path);
use Mojo::Log;
use Mojo::URL;
use Mojo::Util qw(steady_time);
use POSIX qw(WNOHANG);
use Scalar::Util qw(weaken);

our $VERSION = '0.01';

# This should be considered internal for now
our $MOJODCTL = do {
  my $x = $0 =~ m!\bmojodctl$! && -x $0 ? $0 : $ENV{MOJODCTL_BINARY};
  $x ||= curfile->dirname->dirname->dirname->dirname->child(qw(script mojodctl));
  -x $x ? $x : 'mojodctl';
};

has graceful_timeout   => 120;
has heartbeat_interval => 5;
has heartbeat_timeout  => 50;
has listen             => sub ($self) { [Mojo::URL->new('http://*:8080')] };
has log                => sub ($self) { $self->_build_log };
has pid_file           => sub ($self) { path tmpdir, basename($0) . '.pid' };
has workers            => 4;
has worker_pipe        => sub ($self) { $self->_build_worker_pipe };

sub check_pid ($self) {
  return 0 unless my $pid = -r $self->pid_file && $self->pid_file->slurp;
  chomp $pid;
  return $pid if $pid && kill 0, $pid;
  $self->pid_file->remove;
  return 0;
}

sub ensure_pid_file ($self) {
  my $pid = $self->{pid} ||= $$;
  return $self if -s (my $file = $self->pid_file);
  $self->log->debug("Writing pid $pid to @{[$self->pid_file]}");
  return $file->spurt("$pid\n")->chmod(0644) && $self;
}

sub run ($self, $app) {
  if (my $pid = $self->check_pid) {
    $self->log->info("Starting hot deployment of $pid.");
    return kill(USR2 => $pid) ? 0 : 1;
  }

  weaken $self;
  local $SIG{CHLD} = sub { $self->_waitpid };
  local $SIG{INT}  = sub { $self->stop('INT') };
  local $SIG{QUIT} = sub { $self->stop('QUIT') };
  local $SIG{TERM} = sub { $self->stop('TERM') };
  local $SIG{TTIN} = sub { $self->_inc_workers(1) };
  local $SIG{TTOU} = sub { $self->_inc_workers(-1) };
  local $SIG{USR2} = sub { $self->_hot_deploy };

  $self->{pool} ||= {};
  @$self{qw(pid running)} = ($$, 1);
  $self->worker_pipe;    # Make sure we have a working pipe
  $self->emit('start');
  $self->log->info("Manager for $app started");
  $self->_manage($app) while $self->{running};
  $self->log->info("Manager for $app stopped");
}

sub stop ($self, $signal = 'TERM') {
  $self->{stop_signal} = $signal;
  $self->log->info("Manager will stop workers with signal $signal");
  return $self->emit(stop => $signal);
}

sub _build_log ($self) {
  $ENV{MOJO_LOG_LEVEL}
    ||= $ENV{HARNESS_IS_VERBOSE} ? 'debug' : $ENV{HARNESS_ACTIVE} ? 'error' : 'info';
  return Mojo::Log->new(level => $ENV{MOJO_LOG_LEVEL});
}

sub _build_worker_pipe ($self) {
  my $path = $self->pid_file->to_string =~ s!\.pid$!.sock!r;
  die qq(PID file "@{[$self->pid_file]}" must end with ".pid") unless $path =~ m!\.sock$!;
  path($path)->remove if -S $path;
  return IO::Socket::UNIX->new(Listen => 1, Local => $path, Type => SOCK_DGRAM)
    || die "Can't create a worker pipe: $@";
}

sub _hot_deploy ($self) {
  $self->log->info('Starting hot deployment.');
  my $time = steady_time;
  $_->{graceful} = $time for values %{$self->{pool}};
}

sub _inc_workers ($self, $by) {
  my $workers = $self->workers + $by;
  $workers = 1 if $workers < 1;
  $self->workers($workers);

  my $time = steady_time;
  my @stop = grep { !$_->{graceful} } values %{$self->{pool}};
  splice @stop, 0, $workers;
  $_->{graceful} = $time for @stop;
}

sub _kill ($self, $signal, $w, $reason = "with $signal") {
  return if $w->{$signal};
  $w->{$signal} = kill($signal => $w->{pid}) // 0;
  $self->log->info("Stopping worker $w->{pid} $reason == $w->{$signal}");
}

sub _manage ($self, $app) {
  $self->_read_heartbeat;

  # Stop workers and eventually manager
  my $pool = $self->{pool};
  if (my $signal = $self->{stop_signal}) {
    return delete @$self{qw(running stop_signal)} unless keys %$pool;    # Fully stopped
    return map { $_->{$signal} || $self->_kill($signal => $_) } values %{$self->{pool}};
  }

  # Make sure we have enough workers and a pid file
  my $need = $self->workers - int grep { !$_->{graceful} } values %$pool;
  $self->log->debug("Manager starting $need workers") if $need > 0;
  $self->_spawn($app) while !$self->{stop_signal} && $need-- > 0;
  $self->ensure_pid_file;

  # Keep track of worker health
  my $gt   = $self->graceful_timeout;
  my $ht   = $self->heartbeat_timeout;
  my $time = steady_time;
  for my $pid (keys %$pool) {
    next unless my $w = $pool->{$pid};

    if (!$w->{graceful} and $w->{time} + $ht <= $time) {
      $w->{graceful} = $time;
      $self->log->error("Worker $pid has no heartbeat");
    }

    if ($gt and $w->{graceful} and $w->{graceful} + $gt < $time) {
      $self->_kill(KILL => $w, 'with no heartbeat');
    }
    elsif ($w->{graceful}) {
      $self->_kill(QUIT => $w, 'gracefully');
    }
  }
}

sub _read_heartbeat ($self) {
  my $select = $self->{select} ||= IO::Select->new($self->worker_pipe);
  return unless $select->can_read(0.1);
  return unless $self->worker_pipe->sysread(my $chunk, 4194304);

  my $time = steady_time;
  while ($chunk =~ /(\d+):(\w)\n/g) {
    next unless my $w = $self->{pool}{$1};
    $w->{graceful} ||= $time if $2 eq 'g';
    $w->{time} = $time;
    $self->emit(heartbeat => $w);
  }
}

sub _spawn ($self, $app) {
  my @args;
  push @args, map {
    my $url = $_->clone;
    $url->query->param(reuse => 1);
    (-l => $url->to_string);
  } @{$self->listen};

  # Parent
  die "Can't fork: $!" unless defined(my $pid = fork);
  return $self->emit(spawn => $self->{pool}{$pid} = {pid => $pid, time => steady_time}) if $pid;

  # Child
  $ENV{MOJO_SERVER_DAEMON_HEARTBEAT_INTERVAL} = $self->heartbeat_interval;
  $ENV{MOJO_SERVER_DAEMON_CONTROL_CLASS}      = 'Mojo::Server::DaemonControl::Worker';
  $ENV{MOJO_SERVER_DAEMON_CONTROL_SOCK}       = $self->worker_pipe->hostpath;
  $self->log->debug("Exec $^X $MOJODCTL $app daemon @args");
  exec $^X, $MOJODCTL => $app => daemon => @args;
  die "Could not exec $app: $!";
}

sub _waitpid ($self) {
  while ((my $pid = waitpid -1, WNOHANG) > 0) {
    next unless my $w = delete $self->{pool}{$pid};
    $self->log->debug("Worker $pid stopped");
    $self->emit(reap => $w);
  }
}

sub DESTROY ($self) {
  return if $self->{pid} and $self->{pid} != $$;    # Fork safety
  my $path = $self->pid_file;
  $path->remove if $path and -e $path;

  my $worker_pipe = $self->{worker_pipe};
  path($worker_pipe->hostpath)->remove if $worker_pipe and -S $worker_pipe->hostpath;
}

1;

=encoding utf8

=head1 NAME

Mojo::Server::DaemonControl - A Mojolicious daemon manager

=head1 SYNOPSIS

=head2 Commmand line

  # Start a server
  $ mojodctl -l 'http://*:8080' -P /tmp/myapp.pid -w 4 /path/to/myapp.pl;

  # Running mojodctl with the same PID file will hot reload a running server
  # or start a new if it is not running
  $ mojodctl -l 'http://*:8080' -P /tmp/myapp.pid -w 4 /path/to/myapp.pl;

  # For more options
  $ mojodctl --help

=head2 Perl API

  use Mojo::Server::DaemonControl;
  my $listen = Mojo::URL->new('http://*:8080');
  my $dctl   = Mojo::Server::DaemonControl->new(listen => [$listen], workers => 4);

  $dctl->run('/path/to/my-mojo-app.pl');

=head2 Mojolicious application

It is possible to use the L<Mojolicious/before_server_start> hook to change
server settings. The C<$app> is also available, meaning the values can be read
from a config file. See L<Mojo::Server::DaemonControl::Worker> and
L<Mojo::Server::Daemon> for more information about what to tweak.

  use Mojolicious::Lite -signatures;

  app->hook(before_server_start => sub ($server, $app) {
    if ($sever->isa('Mojo::Server::DaemonControl::Worker')) {
      $server->inactivity_timeout(60);
      $server->max_clients(100);
      $server->max_requests(10);
    }
  });

=head1 DESCRIPTION

L<Mojo::Server::DaemonControl> is not a web server. Instead it manages one or
more L<Mojo::Server::Daemon> processes that can handle web requests. Each of
these servers are started with L<SO_REUSEPORT|Mojo::Server::Daemon/reuse>
enabled.

This means it is only supported on systems that support
L<SO_REUSEPORT|https://lwn.net/Articles/542629/>. It also does not support fork
emulation. It should work on most modern Linux based systems though.

This server is an alternative to L<Mojo::Server::Hypnotoad> where each of the
workers handle long running (WebSocket) requests. The main difference is that a
hot deploy will simply start new workers, instead of restarting the manager.
This is useful if you need/want to deploy a new version of your server during
the L</graceful_timeout>. Normally this is not something you would need, but in
some cases where the graceful timeout and long running requests last for
several hours or even days, then it might come in handy to let the old
code run, while new processes are deployed.

Note that L<Mojo::Server::DaemonControl> is currently EXPERIMENTAL and it has
not been tested in production yet. Feedback is more than welcome.

=head1 SIGNALS

=head2 INT, TERM

Shut down server immediately.

=head2 QUIT

Shut down server gracefully.

=head2 TTIN

Increase worker pool by one.

=head2 TTOU

Decrease worker pool by one.

=head2 USR2

Will prevent existing workers from accepting new connections and eventually
stop them, and start new workers in a fresh environment that handles the new
connections. The manager process will remain the same.

  $ mojodctl
    |- myapp.pl-1647405707
    |- myapp.pl-1647405707
    |- myapp.pl-1647405707
    |- myapp.pl
    |- myapp.pl
    '- myapp.pl

EXPERIMENTAL: The workers that waits to be stopped will have a timestamp
appended to C<$0> to illustrate which is new and which is old.

=head1 ATTRIBUTES

L<Mojo::Server::DaemonControl> inherits all attributes from
L<Mojo::EventEmitter> and implements the following ones.

=head2 graceful_timeout

  $timeout = $dctl->graceful_timeout;
  $dctl    = $dctl->graceful_timeout(120);

A worker will be forced stopped if it could not be gracefully stopped after
this amount of time.

=head2 heartbeat_interval

  $num  = $dctl->heartbeat_interval;
  $dctl = $dctl->heartbeat_interval(5);

Heartbeat interval in seconds. This value is passed on to
L<Mojo::Server::DaemonControl::Worker/heartbeat_interval>.

=head2 heartbeat_timeout

  $num  = $dctl->heartbeat_timeout;
  $dctl = $dctl->heartbeat_timeout(120);

A worker will be stopped gracefully if a heartbeat has not been seen within
this amount of time.

=head2 listen

  $array_ref = $dctl->listen;
  $dctl      = $dctl->listen([Mojo::URL->new]);

An array-ref of L<Mojo::URL> objects for what to listen to. See
L<Mojo::Server::Daemon/listen> for supported values.

The C<reuse=1> query parameter will be added automatically before starting the
L<Mojo::Server::Daemon> sub process.

=head2 log

  $log  = $dctl->log;
  $dctl = $dctl->log(Mojo::Log->new);

A L<Mojo::Log> object used for logging.

=head2 pid_file

  $file = $dctl->pid_file;
  $dctl = $dctl->pid_file(Mojo::File->new);

A L<Mojo::File> object with the path to the pid file.

Note that the PID file must end with ".pid"! Default path is "mojodctl.pid" in
L<File::Spec/tmpdir>.

=head2 workers

  $int  = $dctl->workers;
  $dctl = $dctl->workers(4);

Number of worker processes, defaults to 4. See L<Mojo::Server::Prefork/workers>
for more details.

=head2 worker_pipe

  $socket = $dctl->worker_pipe;

Holds a L<IO::Socket::UNIX> object used to communicate with workers.

=head1 METHODS

L<Mojo::Server::DaemonControl> inherits all methods from
L<Mojo::EventEmitter> and implements the following ones.

=head2 check_pid

  $int = $dctl->check_pid;

Returns the PID of the running process documented in L</pid_file> or zero (0)
if it is not running.

=head2 ensure_pid_file

  $dctl->ensure_pid_file;

Makes sure L</pid_file> exists and contains the current PID.

=head2 run

  $dctl->run($app);

Run the menager and wait for L</SIGNALS>. Note that C<$app> is not loaded in
the manager process, which means that each worker does not share any code or
memory.

=head2 stop

  $dctl->stop($signal);

Used to stop the running manager and any L</workers> with the C<$signal> INT,
QUIT or TERM (default).

=head1 AUTHOR

Jan Henning Thorsen

=head1 COPYRIGHT AND LICENSE

Copyright (C) Jan Henning Thorsen

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=head1 SEE ALSO

L<Mojo::Server::Daemon>, L<Mojo::Server::Hypnotoad>,
L<Mojo::Server::DaemonControl::Worker>.

=cut
