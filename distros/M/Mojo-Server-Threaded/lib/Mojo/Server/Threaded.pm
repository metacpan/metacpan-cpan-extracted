package Mojo::Server::Threaded;
use Mojo::Base 'Mojo::Server::Daemon';

our $VERSION = 0.11;

use threads('stack_size' => 64*4096);
use Thread::Queue;

use File::Spec::Functions 'tmpdir';
use Mojo::File 'path';
use Mojo::Util 'steady_time';
use Mojo::Log;
use Scalar::Util 'weaken';
use IO::Socket::IP;
use IO::Select;
use Time::HiRes qw(time sleep);

has accepts            => 10000;
has cleanup            => 1;
has graceful_timeout   => 120;
has heartbeat_timeout  => 30;
has heartbeat_interval => 5;
has pid_file           => sub { path(tmpdir, 'threaded.pid')->to_string };
has spare              => 2;
has workers            => 4;
has manage_interval    => 0.1;
has management_port    => 0;

my $trace = $ENV{MOJO_SERVER_THREADED_TRACE};

my %default_commands = (
  WORKER => sub {
    my($self, $cmd, $tid) = @_;
    return unless $cmd =~ /^(?:QUIT|KILL)$/i;
    return unless $self->{pool}{$tid};
    $self->{pool}{$tid}{queue_out}->enqueue($cmd);
  },
  WORKERS => sub {
    my($self, $diff) = @_;
    return unless $diff;
    my $new = $self->workers + $diff;
    $self->workers($new >= 0 ? $new : 0);
    for my $w (values %{$self->{pool}}) {
      next if $w->{graceful};
      last if $diff++ >= 0;
      $w->{graceful} = steady_time;
    }
  },
  QUIT    => sub { $_[0]->_term(1) },
  KILL    => sub { $_[0]->_term },
);

sub DESTROY {
  return unless $_[0]->cleanup;
  unlink $_[0]->pid_file;
}

sub register_command {
  my($self, $command, $sub) = @_;
  $self->{commands}{uc($command)} = $sub;
  return $self;
}

sub daemonize { }

sub _check_pid_file {
  my $file = shift->pid_file;
  return undef unless open my $handle, '<', $file;
  local $/ = undef;
  my($pid, $mport) = split(/\s+/, <$handle>);
  close($handle);

  return($pid, $mport) if $pid && kill 0, $pid;

  unlink $file or warn "unlink failed, $!";
  return;
}

sub check_pid {
  (my $pid) = shift->_check_pid_file;
  return $pid;
}

sub check_mport {
  my($pid, $mport) = shift->_check_pid_file;
  return $mport;
}

sub ensure_pid_file {
  my ($self, $pid) = @_;

  # Check if PID file already exists
  return if -e (my $file = $self->pid_file);

  # Create PID file
  $self->app->log->error(qq{Can't create process id file "$file": $!})
    and die qq{Can't create process id file "$file": $!}
    unless open my $handle, '>', $file;
  $self->app->log->info(qq{Creating process id file "$file"});
  print $handle join("\n", $pid, $self->management_port), "\n";
  close($handle);
}

sub healthy {
  scalar grep { $_->{healthy} } values %{shift->{pool}};
}

sub run {
  my $self = shift;

  # Clean manager environment
  local $SIG{INT} = local $SIG{TERM} = sub { $self->_term };
  local $SIG{QUIT} = sub { $self->_term(1) };

  # Setup Manager TCP listener
  $self->register_command($_, $default_commands{$_})
    for keys %default_commands;
  $self->_setup_manage_listener();

  # Preload application before starting workers
  $self->start->app->log->info("Manager $$ started");
  $self->ioloop->max_accepts($self->accepts);

  $self->{running} = 1;
  while ( $self->{running} ) {
    $self->_manage;
    sleep 0.01;
  }
  $self->app->log->info("Manager $$ stopped");
}

sub send_command {
  my($self, $cmd) = @_;

  return unless $cmd;

  my $port = $self->check_mport();

  $self->app->log->info("sending '$cmd' to port $port");

  my $con = IO::Socket::IP->new(
    PeerAddr => '127.0.0.1',
    PeerPort => $port,
  ) or $self->app->log->error("could not connect to manager port $port");
  return unless $con;
  $con->send($cmd);
  $con->close();
  return $self;
}

sub _heartbeat {
  my $self = shift;

  my $log = $self->app->log;
  my $tid = threads->tid();

  my $hbmsg = join(':', $tid, @_);
  $trace && $self->app->log->debug("Worker $tid: sending '$hbmsg'");
  $self->{queue_out}->enqueue($hbmsg);
}

sub _manage {
  my $self = shift;

  my $log = $self->app->log;

  # Spawn more workers if necessary and check PID file
  if (!$self->{finished}) {
    my $graceful = grep { $_->{graceful} } values %{$self->{pool}};
    my $spare = $self->spare;
    $spare = $graceful ? $graceful > $spare ? $spare : $graceful : 0;
    my $need = ($self->workers - keys %{$self->{pool}}) + $spare;
    while ($need-- > 0) {
        $trace && $self->app->log->debug("spawning new worker");
        $self->_spawn
    }
    $self->ensure_pid_file($$);
  }

  # Shutdown
  elsif (!keys %{$self->{pool}}) {
    return delete $self->{running};
  }

  # Wait for heartbeats or messages
  $self->_wait;

  my $interval = $self->heartbeat_interval;
  my $ht       = $self->heartbeat_timeout;
  my $gt       = $self->graceful_timeout;
  my $time     = steady_time;

  for my $tid (keys %{$self->{pool}}) {
    next unless my $w = $self->{pool}{$tid};

    unless ( $w->{thread}->is_running() ) {
        $self->emit(reap => $tid)->_stopped($tid);
        next;
    }

    # No heartbeat (graceful stop)
    $log->error("Worker $tid has no heartbeat, restarting")
      and $w->{graceful} = $time
      if !$w->{graceful} && ($w->{time} + $interval + $ht <= $time);

    # Graceful stop with timeout
    my $graceful = $w->{graceful} ||= $self->{graceful} ? $time : undef;
    $log->info("Stopping worker $tid gracefully ($gt seconds)")
      and $w->{queue_out}->enqueue('QUIT')
      if $graceful && !$w->{quit}++;
    $w->{force} = 1 if $graceful && $graceful + $gt <= $time;

    # send KILL and abandon threads
    if ( $w->{force} || ($self->{finished} && !$graceful) ) {
        $log->warn("Abandon worker $tid immediately");
        $w->{queue_out}->enqueue('KILL');
        $self->emit(reap => $tid)->_stopped($tid);
    }
  }
}

sub _spawn {
  my $self = shift;

  my $log = $self->app->log;

  $trace && $log->debug("creating new worker");

  my $queue_in  = Thread::Queue->new();
  my $queue_out = Thread::Queue->new();

  my $thr = threads->create('_worker', $self, $queue_in, $queue_out);
  my $tid = $thr->tid();

  $trace && $log->debug("created worker $tid");

  $thr->detach();
  $trace && $log->debug("detached worker $tid");

  return $self->emit(spawn => $tid)->{pool}{$tid} = {
    time      => steady_time,
    queue_in  => $queue_in,
    queue_out => $queue_out,
    thread    => $thr,
  };
}

sub _worker {
  my($self, $queue_out, $queue_in) = @_;

  my $tid = threads->tid();

  # reopen log in new thread
  my $log = $self->app->log;

  if ( $log->handle->fileno > 2 ) {
    my $new = IO::File->new();
    $new->open($log->path, '>>');
    $log->handle($new);
  }

  $self->{queue_in}  = $queue_in;
  $self->{queue_out} = $queue_out;

  $trace && $log->debug("Worker $tid: new worker started");

  # Heartbeat messages
  my $loop     = $self->cleanup(0)->ioloop;
  my $finished = 0;

  $SIG{$_} = 'DEFAULT' for qw(INT TERM);

  $trace && $self->on(
    'request' => sub { $log->debug("Worker $tid: handling request"); },
  );

  #weaken $self;

  my $cb = sub {
    $trace && $log->debug("Worker $tid: sending finished to manager") if $finished;
    $self->_heartbeat($finished);
  };

  $loop->next_tick($cb);

  $trace && $log->debug("Worker $tid: setting up heartbeat timer");
  $loop->recurring($self->heartbeat_interval => $cb);

  $loop->recurring(0.01 => sub {
    while ( my $msg = $self->{queue_in}->dequeue_nb() ) {
      $trace && $log->debug("Worker: got message '$msg' from manager");
      $self->{$msg} = 1;
    }
    if ( $self->{QUIT} ) {
      delete $self->{QUIT};
      $trace && $log->debug("Worker $tid: got QUIT");
      $self->max_requests(1);
      $loop->stop_gracefully;
      $finished = 1;
      $trace && $log->debug("Worker $tid: loop should end");
    } elsif ( $self->{KILL} ) {
      delete $self->{KILL};
      $loop->stop if $loop;
      threads->exit();
    }
    threads->yield();
  });

  srand;

  $log->info("Worker $tid started");
  $loop->start;
  $trace && $log->debug("Worker $tid stopped processing");
}

sub _stopped {
  my ($self, $tid) = @_;

  return unless my $w = delete $self->{pool}{$tid};

  my $log = $self->app->log;
  $log->info("Worker $tid stopped");
  $log->error("Worker $tid stopped too early, shutting down") and $self->_term
    unless $w->{healthy};
}

sub _term {
  my ($self, $graceful) = @_;
  my $mode = $graceful ? 'gracefully' : 'immediately';
  $trace && $self->app->log->debug("terminating server $mode");
  @{$self->emit(finish => $graceful)}{qw(finished graceful)} = (1, $graceful);
}

sub _setup_manage_listener {
  my $self = shift;
  $self->{msocket} = IO::Socket::IP->new(Listen => 5, LocalAddr => '127.0.0.1');
  $self->management_port(my $mport = $self->{msocket}->sockport);
  $self->{msocket}->blocking(0);
  $self->{mselect} = IO::Select->new($self->{msocket});
  $self->app->log->info("created management listener on port $mport");
}

sub _check_manage_listener {
  my $self = shift;

  my $log = $self->app->log;

  $trace && $log->debug("checking management socket");

  my %cmd;
  foreach my $con ( $self->{mselect}->can_read(0.1) ) {
    if ( $con == $self->{msocket} ) {
      my $client = $con->accept;
      my $peer = $client->peerhost();
      $log->debug("management connection from $peer");
      # TODO make this configurable
      $peer eq '127.0.0.1'
        ? $self->{mselect}->add($client)
        : $client->close();
    } else {
      $trace && $log->debug("reading from management socket");
      $con->recv(my $buf, 4096);
      if ($buf =~ /\w+/) {
        chomp($buf);
        $trace && $log->debug("got $buf on management socket");
        my($k, @v) = split(/\s+/, $buf);
        $k = uc($k);
        next unless my $func = $self->{commands}{$k};
        $trace && $log->debug("running command function for '$k'");
        $self->emit(command => $k, @v);
        $func->($self, @v);
      }
      $self->{mselect}->remove($con);
      $con->close;
    }
  }
}


sub _wait {
  my $self = shift;

  my $log = $self->app->log;

  $self->emit('wait');
  for my $tid (keys %{$self->{pool}}) {
    next unless my $w = $self->{pool}{$tid};
    my $time = steady_time;
    while ( my $msg = $w->{queue_in}->dequeue_nb() ) {
      $trace && $log->debug("Manager: got heartbeat '$msg'");
      my($id, $finished) = split(/:/, $msg);
      next unless $id == $tid;
      @$w{qw(healthy time)} = (1, $time) and $self->emit(heartbeat => $id);
      $w->{graceful} ||= $time if $finished;
    }
  }

  my $lt  = $self->{last_check_manage_listener} || 0;
  my $now = steady_time;
  if ( $now - $lt > $self->manage_interval ) {
    $self->_check_manage_listener();
    $self->{last_check_manage_listener} = $now;
  }

}

1;

=encoding utf8

=head1 NAME

Mojo::Server::Threaded - Multithreaded non-blocking I/O HTTP and WebSocket server

=head1 SYNOPSIS

  use Mojo::Server::Threaded;

  my $threaded = Mojo::Server::Threaded->new(listen => ['http://*:8080']);
  $threaded->unsubscribe('request')->on(request => sub {
    my ($threaded, $tx) = @_;

    # Request
    my $method = $tx->req->method;
    my $path   = $tx->req->url->path;

    # Response
    $tx->res->code(200);
    $tx->res->headers->content_type('text/plain');
    $tx->res->body("$method request for $path!");

    # Resume transaction
    $tx->resume;
  });
  $threaded->run;

=head1 DESCRIPTION

L<Mojo::Server::Threaded> is a multithreaded alternative for
L<Mojo::Server::Prefork> which is not available under Win32.
It takes the same parameters and works analoguous by just using
threads instead of forked processes.

The main difference besides using threads is that signals are only used
for the termination of the server. Starting, stopping and de- or increasing
the amount of workers is done via L</"send_command">.

=head1 MANAGER SIGNALS

Signals under Windows are not really useful for communicating with running
background processes. L<Mojo::Server::Threaded> can be controlled using
a TCP management socket. See L</"MANAGER COMMANDS">.

The L<Mojo::Server::Threaded> manager process can be controlled at runtime
with the following signals.

=head2 INT, TERM

Shut down server immediately.

=head2 QUIT

Shut down server gracefully.

=head1 EVENTS

L<Mojo::Server::Threaded> emits the same events as L<Mojo::Server::Prefork>
and implements the following new ones.

=head2 command

  $threaded->on(command => sub {
    my($threaded, $command, @params) = @_;
    say "got command $command on mamagement port";
    ...
  });

Emitted when a command is received on the manager listening port.

=head1 ATTRIBUTES

L<Mojo::Server::Threaded> recognizes the same attributes as
L<Mojo::Server::Prefork> and implements the following new ones.

=head2 manage_interval

  my $interval = $threaded->manage_interval;
  $threaded    = $threaded->manage_interval(0.5);

Check interval for the management port in seconds, defaults to C<0.1>.

=head1 METHODS

L<Mojo::Server::Threaded> inherits all methods from L<Mojo::Server::Daemon>,
implements the same ones as L<Mojo::Server::Prefork> and the following new
ones.

=head2 check_mport

  my $port = $threaded->check_mport;

Get the TCP port for the management socket from
L<Mojo::Server::Prefork/"pid_file">.

=head2 register_command

  $threaded->register_command( HELLO => sub {
      my($self, $cmd, @params) = @_;
      warn "handling $cmd on management port\n";
  });

Register a management command and handler subroutine. The command will be
upcased.

=head2 send_command

  $threaded->send_command("hello DO SOMETHING");

Send a command to the management socket. The string will be split on
whitespace and the first element will be upcased on the receiver's side.

=head1 MANAGER COMMANDS

L<Mojo::Server::Threaded> can be controlled by the following commands:

=head2 KILL

Shut down server immediately.

=head2 QUIT

Shut down server gracefully.

=head2 WORKER S<< <QUIT|KILL> <ID> >>

Send QUIT or KILL to an existing worker thread

=head2 WORKERS S<< <NUMBER> >>

Increase or decrease (negative values) the number of workers by NUMBER.

=head1 CAVEATS

Since Perl ithreads are relatively heavy in comparison the spawning of
threads is much slower than forking on UNIX. The hot deploy also will be
much slower, as a new interpreter is started.

Once running this should not affect performance too much.

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicious.org>.

=cut
