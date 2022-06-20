package Mojo::Run3;
use Mojo::Base 'Mojo::EventEmitter';

use Errno qw(EAGAIN ECONNRESET EINTR EPIPE EWOULDBLOCK EIO);
use IO::Handle;
use IO::Pty;
use Mojo::IOLoop::ReadWriteFork::SIGCHLD;
use Mojo::IOLoop;
use Mojo::Util qw(term_escape);
use Mojo::Promise;
use Scalar::Util qw(blessed weaken);

use constant DEBUG => $ENV{MOJO_RUN3_DEBUG} && 1;

our $VERSION = '0.05';

our @SAFE_SIG = grep {
  !m!^(NUM\d+|__[A-Z0-9]+__|ALL|CATCHALL|DEFER|HOLD|IGNORE|MAX|PAUSE|RTMAX|RTMIN|SEGV|SETS)$!
} keys %SIG;

has driver => 'pipe';
has ioloop => sub { Mojo::IOLoop->singleton }, weak => 1;

sub close {
  my ($self, $name) = @_;
  my $fh      = $self->{fh};
  my $reactor = $self->ioloop->reactor;

  $self->_d('close %s (%s)', $name, $fh->{$name} // 'undef') if DEBUG;
  my $h = $fh->{$name} or return $self;

  for my $sibling (keys %$fh) {
    next if $fh->{$sibling} ne $h;
    $self->{finish}{$name}++;
    $reactor->remove($fh->{$sibling});
    delete $fh->{$sibling};
  }

  $h->close;
  return $self;
}

sub exit_status { shift->status >> 8 }
sub handle      { $_[0]->{fh}{$_[1]} }

sub kill {
  my ($self, $signal) = (@_, 15);
  $self->_d('kill %s %s', $signal, $self->{pid} // 0) if DEBUG;
  return $self->{pid} ? kill $signal, $self->{pid} : -1;
}

sub run_p {
  my ($self, $cb) = @_;
  my $p = Mojo::Promise->new;
  $self->once(finish => sub { $p->resolve($_[0]) });
  $self->start($cb);
  return $p;
}

sub pid    { shift->{pid}    // 0 }
sub status { shift->{status} // -1 }

sub start {
  my ($self, $cb) = @_;

  $self->ioloop->next_tick(sub {
    $! = 0;
    return $self->_fail("Can't pipe: $@", $!) unless my $fh = eval { $self->_prepare_filehandles };
    return $self->_fail("Can't fork: $!", $!) unless defined($self->{pid} = fork);
    return $self->{pid} ? $self->_start_parent($fh) : $self->_start_child($fh, $cb);
  });

  return $self;
}

sub write {
  my ($self, $chunk, $cb) = @_;
  $self->once(drain => $cb) if $cb;
  $self->{buffer}{stdin} .= $chunk;
  $self->_write;
  return $self;
}

sub _cleanup {
  my ($self) = @_;
  $self->close($_) for qw(pty stdin stderr stdout);
}

sub _d {
  my ($self, $format, @val) = @_;
  warn sprintf "[run3:%s:%s] $format\n", $self->driver, $self->{pid} // 0, @val;
}

sub _fail {
  my ($self, $err, $errno) = @_;
  $self->_d('finish %s (%s)', $err, $errno) if DEBUG;
  $self->{status} = $errno;
  $self->emit(error => $err)->emit('finish');
  $self->_cleanup;
}

sub _make_pipe {
  my ($self) = @_;
  pipe my $read, my $write or die $!;
  $write->autoflush(1);
  return $read, $write;
}

sub _maybe_finish {
  my ($self, $event) = @_;
  my $finish = $self->{finish} ||= {};
  $finish->{$event}++;
  $self->_d('finished %s', join ', ', sort keys %$finish) if DEBUG;
  return 0 unless $finish->{child} and $finish->{stdout} and $finish->{stderr};

  $self->_cleanup;
  for my $cb (@{$self->subscribers('finish')}) {
    $self->emit(error => $@) unless eval { $self->$cb; 1 };
  }

  return 1;
}

sub _prepare_filehandles {
  my ($self) = @_;
  my %fh;
  ($fh{parent}{stdout}, $fh{child}{stdout}) = $self->_make_pipe;
  ($fh{parent}{stderr}, $fh{child}{stderr}) = $self->_make_pipe;

  if ($self->driver eq 'pty') {
    $fh{parent}{pty} = $fh{child}{pty} = IO::Pty->new;
  }
  else {
    ($fh{child}{stdin}, $fh{parent}{stdin}) = $self->_make_pipe;
  }

  return \%fh;
}

sub _read {
  my ($self, $name, $handle) = @_;

  my $n_bytes = $handle->sysread(my $buf, 131072, 0);
  if ($n_bytes) {
    $self->_d('%s >>> %s (%i)', $name, term_escape($buf) =~ s!\n!\\n!gr, $n_bytes) if DEBUG;
    return $self->emit($name => $buf);
  }
  elsif (defined $n_bytes) {
    return $self->close($name)->_maybe_finish($name);    # EOF
  }
  else {
    $self->_d('%s !!! %s (%i)', $name, $!, $!) if DEBUG;
    return undef                       if $! == EAGAIN || $! == EINTR || $! == EWOULDBLOCK;  # Retry
    return $self->kill                 if $! == ECONNRESET || $! == EPIPE;                   # Error
    return $self->_maybe_finish($name) if $! == EIO;    # EOF on PTY raises EIO
    return $self->emit(error => $!);
  }
}

sub _start_child {
  my ($self, $fh, $code) = @_;

  if (my $pty = $fh->{parent}{pty}) {
    $pty->make_slave_controlling_terminal;
    $fh->{child}{stdin} = $pty->slave;
  }

  $fh->{parent}{$_}->close for keys %{$fh->{parent}};
  $fh = $self->{fh} = $fh->{child};

  open STDIN,  '<&=', fileno($fh->{stdin})  or die "Couldn't dup stdin: $!";
  open STDOUT, '>&=', fileno($fh->{stdout}) or die "Couldn't dup stdout: $!";
  open STDERR, '>&=', fileno($fh->{stderr}) or die "Couldn't dup stderr: $!";
  STDOUT->autoflush(1);
  STDERR->autoflush(1);

  @SIG{@SAFE_SIG} = ('DEFAULT') x @SAFE_SIG;
  ($@, $!) = ('', 0);
  $self->{pid} = $$;

  eval { $self->$code };
  my ($err, $errno) = ($@, $@ ? 255 : $! || 0);
  print STDERR $err if length $err;
  POSIX::_exit($errno) || exit $errno;
}

sub _start_parent {
  my ($self, $fh) = @_;

  $fh->{parent}{stdin} = delete $fh->{child}{pty} if $fh->{child}{pty};
  $fh->{child}{$_}->close for keys %{$fh->{child}};
  $fh = $self->{fh} = $fh->{parent};

  weaken $self;
  my $reactor = $self->ioloop->reactor;
  for my $name (qw(pty stderr stdout)) {
    my $h = $fh->{$name} or next;
    $h->close_slave if $name eq 'pty';    # TODO: This is EXPERIMENTAL
    $reactor->io($h, sub { $self ? $self->_read($name => $h) : $_[0]->remove($h) })
      ->watch($h, 1, 0);
  }

  Mojo::IOLoop::ReadWriteFork::SIGCHLD->singleton->waitpid(
    $self->{pid} => sub {
      return unless $self;
      $self->{status} = $_[0];
      $self->_maybe_finish('child');
    }
  );

  $self->{fh} = $fh;
  $self->_d('waitpid %s', $self->{pid}) if DEBUG;
  $self->emit('spawn');
  $self->_write;
}

sub _write {
  my $self = shift;
  return unless length $self->{buffer}{stdin};
  return unless my $stdin = $self->{fh}{stdin};

  my $n_bytes = $stdin->syswrite($self->{buffer}{stdin});
  if (defined $n_bytes) {
    my $buf = substr $self->{buffer}{stdin}, 0, $n_bytes, '';
    $self->_d('stdin <<< %s (%i)', term_escape($buf) =~ s!\n!\\n!gr, length $buf) if DEBUG;
    return $self->emit('drain') unless length $self->{buffer}{stdin};
    return $self->ioloop->next_tick(sub { $self->_write });
  }
  else {
    $self->_d('stdin !!! %s (%i)', $!, $!) if DEBUG;
    return                                 if $! == EAGAIN     || $! == EINTR || $! == EWOULDBLOCK;
    return $self->kill(9)                  if $! == ECONNRESET || $! == EPIPE;
    return $self->emit(error => $!);
  }
}

sub DESTROY { shift->_cleanup unless ${^GLOBAL_PHASE} eq 'DESTRUCT' }

1;

=encoding utf8

=head1 NAME

Mojo::Run3 - Run a subprocess and read/write to it

=head1 SYNOPSIS

  use Mojo::Base -strict, -signatures;
  use Mojo::Run3;
  use IO::Handle;

  my $run3 = Mojo::Run3->new;
  $run3->on(stdout => sub ($run3, $bytes) {
    STDOUT->syswrite($bytes);
  });

  $run3->run_p(sub { exec qw(/usr/bin/ls -l /tmp) })->wait;

=head1 DESCRIPTION

L<Mojo::Run3> allows you to fork a subprocess which you can write STDIN to, and
read STDERR and STDOUT without blocking the the event loop.

This module also supports L<IO::Pty> which allows you to create a
pseudoterminal for the child process. This is especially useful for application
such as C<bash> and L<ssh>.

This module is currently EXPERIMENTAL, but unlikely to change much.

=head1 EVENTS

=head2 drain

  $run3->on(drain => sub ($run3) { });

Emitted after L</write> has written the whole buffer to the subprocess.

=head2 error

  $run3->on(error => sub ($run3, $str) { });

Emitted when something goes wrong.

=head2 finish

  $run3->on(finish => sub ($run3, @) { });

Emitted when the subprocess has ended. L</error> might be emitted before
L</finish>, but L</finish> will always be emitted at some point after L</start>
as long as the subprocess actually stops. L</status> will contain C<$!> if the
subprocess could not be started or the exit code from the subprocess.

=head2 pty

  $run3->on(pty => sub ($run3, $bytes) { });

Emitted when the subprocess write bytes to L<IO::Pty>. See L</driver> for more
details.

=head2 stderr

  $run3->on(stderr => sub ($run3, $bytes) { });

Emitted when the subprocess write bytes to STDERR.

=head2 stdout

  $run3->on(stdout => sub ($run3, $bytes) { });

Emitted when the subprocess write bytes to STDOUT.

=head2 spawn

  $run3->on(spawn => sub ($run3, @) { });

Emitted in the parent process after the subprocess has been forked.

=head1 ATTRIBUTES

=head2 driver

  $str  = $run3->driver;
  $run3 = $run3->driver('pipe');

Can be set to "pipe" (default) or "pty" to run the child process inside a
pseudoterminal, using L<IO::Pty>.

The "pty" will be the L<controlling terminal|IO::Pty/make_slave_controlling_terminal>
of the child process and the slave will be closed in the parent process.
If further setup of the pty should be done, it must be done in the child
process. Example:

  $run3->start(sub ($pty3) {
    my $pty = $pty3->handle('stdin'); # stdin is a IO::Tty object
    $pty->set_winsize($row, $col, $xpixel, $ypixel);
    $pty->set_raw;
    exec qw(ssh -t server.example.com);
  });

=head2 ioloop

  $ioloop = $run3->ioloop;
  $run3   = $run3->ioloop(Mojo::IOLoop->singleton);

Holds a L<Mojo::IOLoop> object.

=head1 METHODS

=head2 close

  $run3 = $run3->close('stdin');

Can be used to close C<STDIN>. This is useful after piping data into a process
like C<cat>.

=head2 exit_status

  $int = $run3->exit_status;

Returns the exit status part of L</status>, which will should be a number from
0 to 255.

=head2 handle

  $fh = $run3->handle($name);

Returns a file handle or undef for C<$name>, which can be "stdin", "stdout",
"stderr" or "pty". This method returns the write or read "end" of the file
handle depending if it is called from the parent or child process.

=head2 kill

  $int = $run3->kill($signal);

Used to send a C<$signal> to the subprocess. Returns C<-1> if no process
exists, C<0> if the process could not be signalled and C<1> if the signal was
successfully sent.

=head2 pid

  $int = $run3->pid;

Process ID of the subprocess after L</start> has successfully started.

=head2 run_p

  $p = $run3->run_p(sub ($run3) { ... })->then(sub ($run3) { ... });

Will L</start> the subprocess and the promise will be fulfilled when L</finish>
is emitted.

=head2 start

  $run3 = $run3->start(sub ($run3, @) { ... });

Will start the subprocess. The code block passed in will be run in the child
process. C<exec()> can be used if you want to run another program. Example:

  $run3 = $run3->start(sub { exec @my_other_program_with_args });
  $run3 = $run3->start(sub { exec qw(/usr/bin/ls -l /tmp) });

=head2 status

  $int = $run3->status;

Holds the exit status of the program or C<$!> if the program failed to start.
The value includes signals and coredump flags. L</exit_status> can be used
instead to get the exit value from 0 to 255.

=head2 write

  $run3 = $run3->write($bytes);
  $run3 = $run3->write($bytes, sub ($run3) { ... });

Used to write C<$bytes> to the subprocess. The optional callback will be called
on the next L</drain> event.

=head1 AUTHOR

Jan Henning Thorsen

=head1 COPYRIGHT AND LICENSE

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=head1 SEE ALSO

L<Mojo::IOLoop::ReadWriteFork>, L<IPC::Run3>.

=cut
