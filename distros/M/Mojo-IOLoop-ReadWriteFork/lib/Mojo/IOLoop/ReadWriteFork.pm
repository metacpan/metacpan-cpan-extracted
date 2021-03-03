package Mojo::IOLoop::ReadWriteFork;
use Mojo::Base 'Mojo::EventEmitter';

use Errno qw(EAGAIN ECONNRESET EINTR EPIPE EWOULDBLOCK EIO);
use IO::Pty;
use Mojo::IOLoop;
use Mojo::Promise;
use Mojo::Util;
use POSIX ':sys_wait_h';
use Scalar::Util ();

use constant CHUNK_SIZE        => $ENV{MOJO_CHUNK_SIZE}           || 131072;
use constant DEBUG             => $ENV{MOJO_READWRITE_FORK_DEBUG} || $ENV{MOJO_READWRITEFORK_DEBUG} || 0;
use constant WAIT_PID_INTERVAL => $ENV{WAIT_PID_INTERVAL}         || 0.01;

my %ESC = ("\0" => '\0', "\a" => '\a', "\b" => '\b', "\f" => '\f', "\n" => '\n', "\r" => '\r', "\t" => '\t');

sub ESC {
  local $_ = shift;
  s/([\x00-\x1f\x7f\x80-\x9f])/$ESC{$1} || sprintf "\\x%02x", ord $1/ge;
  $_;
}

our $VERSION = '0.39';

our @SAFE_SIG = grep {
  not /^(
     NUM\d+
    |__[A-Z0-9]+__
    |ALL|CATCHALL|DEFER|HOLD|IGNORE|MAX|PAUSE|RTMAX|RTMIN|SEGV|SETS
    |
  )$/x
} keys %SIG;

has conduit => sub { +{type => 'pipe'} };
sub pid { shift->{pid} || 0; }
has ioloop => sub { Mojo::IOLoop->singleton; };

sub close {
  my $self = shift;
  my $what = $_[0] eq 'stdout' ? 'stdout_read' : 'stdin_write';    # stdout_read is EXPERIMENTAL
  my $fh   = delete $self->{$what} or return $self;
  CORE::close($fh) or $self->emit(error => $!);
  $self;
}

sub run_p {
  my $self = shift;
  my $p    = Mojo::Promise->new;
  my @cb;
  push @cb, $self->once(close => sub { shift->unsubscribe(error => $cb[1]); $p->resolve(@_) });
  push @cb, $self->once(error => sub { shift->unsubscribe(close => $cb[0]); $p->reject(@_) });
  $self->run(@_);
  return $p;
}

sub run {
  my $args = ref $_[-1] eq 'HASH' ? pop : {};
  my ($self, $program, @program_args) = @_;
  return $self->start({%$args, program => $program, program_args => \@program_args});
}

sub start {
  my $self    = shift;
  my $args    = ref $_[0] ? $_[0] : {@_};
  my $conduit = $self->conduit;

  $args->{$_} //= $conduit->{$_} for keys %$conduit;
  $args->{conduit} ||= delete $args->{type};
  $args->{env}     ||= {%ENV};
  $self->{errno} = 0;
  $args->{program} or die 'program is required input';
  $args->{program_args} ||= [];
  ref $args->{program_args} eq 'ARRAY' or die 'program_args need to be an array';
  Scalar::Util::weaken($self);
  $self->{delay} = $self->ioloop->timer(0 => sub { $self->_start($args) });
  return $self;
}

sub _start {
  local ($?, $!);
  my ($self,        $args) = @_;
  my ($stdout_read, $stdout_write);
  my ($stdin_read,  $stdin_write);
  my ($errno,       $pid);

  if ($args->{conduit} eq 'pipe') {
    pipe $stdout_read, $stdout_write or return $self->emit(error => "pipe: $!");
    pipe $stdin_read,  $stdin_write  or return $self->emit(error => "pipe: $!");
    select +(select($stdout_write), $| = 1)[0];
    select +(select($stdin_write),  $| = 1)[0];
  }
  elsif ($args->{conduit} eq 'pty') {
    $stdin_write = $stdout_read = IO::Pty->new;
  }
  else {
    warn "Invalid conduit ($args->{conduit})\n" if DEBUG;
    return $self->emit(error => "Invalid conduit ($args->{conduit})");
  }

  $self->emit(
    before_fork => {
      stdin_read   => $stdin_read,
      stdin_write  => $stdin_write,
      stdout_read  => $stdout_read,
      stdout_write => $stdout_write,
    }
  );

  $pid = fork;

  if (!defined $pid) {
    warn "Could not fork $!\n" if DEBUG;
    $self->emit(error => "Couldn't fork ($!)");
  }
  elsif ($pid) {    # parent ===================================================
    warn "[$pid] Child starting ($args->{program} @{$args->{program_args}})\n" if DEBUG;
    $self->{pid}         = $pid;
    $self->{stdout_read} = $stdout_read;
    $self->{stdin_write} = $stdin_write;
    $stdout_read->close_slave if defined $stdout_read and UNIVERSAL::isa($stdout_read, 'IO::Pty');

    Scalar::Util::weaken($self);
    $self->ioloop->reactor->io(
      $stdout_read => sub {
        local ($?, $!);
        $self->_read;
        return unless $self->{errno};
        warn "[$pid] Child $self->{errno}\n" if DEBUG;
        $self->emit(error => "Read error: $self->{errno}");
      }
    );

    @$self{qw(wait_eof wait_sigchld)} = (1, 1);
    $self->ioloop->reactor->watch($stdout_read, 1, 0);
    $self->_watch_pid($pid);
    $self->_write;
    $self->emit('fork');
  }
  else {    # child ===========================================================
    if ($args->{conduit} eq 'pty') {
      $stdin_write->make_slave_controlling_terminal;
      $stdin_read = $stdout_write = $stdin_write->slave;
      $stdin_read->set_raw                                         if $args->{raw};
      $stdin_read->clone_winsize_from($args->{clone_winsize_from}) if $args->{clone_winsize_from};
    }

    warn "[$$] Starting $args->{program} @{ $args->{program_args} }\n" if DEBUG;
    CORE::close($stdin_write);
    CORE::close($stdout_read);
    open STDIN,  '<&' . fileno $stdin_read   or exit $!;
    open STDOUT, '>&' . fileno $stdout_write or exit $!;
    open STDERR, '>&' . fileno $stdout_write or exit $!;
    select STDERR;
    $| = 1;
    select STDOUT;
    $| = 1;

    %ENV = %{$args->{env}};

    if (ref $args->{program} eq 'CODE') {
      $! = 0;
      @SIG{@SAFE_SIG} = ('DEFAULT') x @SAFE_SIG;
      eval { $args->{program}->(@{$args->{program_args}}); };
      $errno = $@ ? 255 : $!;
      print STDERR $@ if length $@;
    }
    else {
      exec $args->{program}, @{$args->{program_args}};
    }

    eval { POSIX::_exit($errno // $!); };
    exit($errno // $!);
  }
}

sub write {
  my ($self, $chunk, $cb) = @_;

  $self->once(drain => $cb) if $cb;
  $self->{stdin_buffer} .= $chunk;
  $self->_write if $self->{stdin_write};
  $self;
}

sub kill {
  my $self   = shift;
  my $signal = shift // 15;
  my $pid    = $self->{pid} or return;

  warn "[$pid] Kill $signal\n" if DEBUG;
  kill $signal, $pid;
}

sub _error {
  return if $! == EAGAIN || $! == EINTR || $! == EWOULDBLOCK;
  return $_[0]->kill if $! == ECONNRESET || $! == EPIPE;
  return $_[0]->emit(error => $!)->kill;
}

sub _cleanup {
  my $self    = shift;
  my $reactor = $self->{ioloop}{reactor} or return;

  delete $self->{stdin_write};
  $reactor->remove(delete $self->{stdin_write}) if $self->{stdin_write};
  $reactor->remove(delete $self->{stdout_read}) if $self->{stdout_read};
  $reactor->remove(delete $self->{delay})       if $self->{delay};
}

sub _maybe_terminate {
  my ($self, $pending_event) = @_;
  delete $self->{$pending_event};
  $self->emit(close => $self->{exit_value}, $self->{signal})->_cleanup
    unless $self->{wait_eof} or $self->{wait_sigchld};
}

sub _read {
  my $self        = shift;
  my $stdout_read = $self->{stdout_read} or return;
  my $read        = $stdout_read->sysread(my $buffer, CHUNK_SIZE, 0);

  # EOF on PTY raises EIO when slave devices has closed all file descriptors
  return $self->_maybe_terminate('wait_eof') if (!defined $read and $! == EIO) or $read == 0;
  return $self->{errno} = $! // 0 unless defined $read;
  warn "[$self->{pid}] >>> @{[ESC($buffer)]}\n" if DEBUG;
  $self->emit(read => $buffer);
}

sub _sigchld {
  my $self = shift;
  my ($exit_value, $signal) = ($_[1] >> 8, $_[1] & 127);
  warn "[$_[0]] Child is dead ($?/$!) $exit_value/$signal\n" if DEBUG;
  @$self{qw(exit_value signal)} = ($exit_value, $signal);
  $self->_maybe_terminate('wait_sigchld');
}

sub _watch_pid {
  my ($self, $pid) = @_;
  my $reactor = $self->ioloop->reactor;

  # The CHLD test is for code, such as Minion::Command::minion::worker
  # where SIGCHLD is set up for manual waitpid() checks.
  # See https://github.com/kraih/minion/issues/15 and
  # https://github.com/jhthorsen/mojo-ioloop-readwritefork/issues/9
  # for details.
  if ($SIG{CHLD} or !$reactor->isa('Mojo::Reactor::EV')) {
    $reactor->{fork_watcher} ||= $reactor->recurring(WAIT_PID_INTERVAL, \&_watch_forks);
    Scalar::Util::weaken($reactor->{forks}{$pid} = $self);
  }
  else {
    $self->{ev_child} = EV::child($pid, 0, sub { _sigchld($self, $pid, $_[0]->rstatus); });
  }
}

sub _watch_forks {
  my $reactor = shift;
  my @pids    = keys %{$reactor->{forks}};

  $reactor->remove(delete $reactor->{fork_watcher}) unless @pids;

  for my $pid (@pids) {
    local ($?, $!);
    my $kid = waitpid $pid, WNOHANG or next;
    warn "waitpid $pid, WNOHANG failed: $! ($kid, $?)" unless $kid == $pid;
    _sigchld(delete $reactor->{forks}{$pid}, $pid, $?);
  }
}

sub _write {
  my $self = shift;

  return unless length $self->{stdin_buffer};
  my $stdin_write = $self->{stdin_write};
  my $written     = $stdin_write->syswrite($self->{stdin_buffer});
  return $self->_error unless defined $written;
  my $chunk = substr $self->{stdin_buffer}, 0, $written, '';
  warn "[${ \$self->pid }] <<< @{[ESC($chunk)]}\n" if DEBUG;

  if (length $self->{stdin_buffer}) {

    # This is one ugly hack because it does not seem like IO::Pty play
    # nice with Mojo::Reactor(::EV) ->io(...) and ->watch(...)
    $self->ioloop->timer(0.01 => sub { $self and $self->_write });
  }
  else {
    $self->emit('drain');
  }
}

sub DESTROY { shift->_cleanup }

1;

=encoding utf8

=head1 NAME

Mojo::IOLoop::ReadWriteFork - Fork a process and read/write from it

=head1 VERSION

0.39

=head1 SYNOPSIS

  my $fork = Mojo::IOLoop::ReadWriteFork->new;

  # Emitted if something terrible happens
  $fork->on(error => sub { my ($fork, $error) = @_; warn $error; });

  # Emitted when the child completes
  $fork->on(close => sub { my ($fork, $exit_value, $signal) = @_; Mojo::IOLoop->stop; });

  # Emitted when the child prints to STDOUT or STDERR
  $fork->on(read => sub {
    my ($fork, $buf) = @_;
    print qq(Child process sent us "$buf");
  });

  # Need to set "conduit" for bash, ssh, and other programs that require a pty
  $fork->conduit({type => "pty"});

  # Start the application
  $fork->run("bash", -c => q(echo $YIKES foo bar baz));

  # Using promises
  $fork->on(read => sub { ... })->run_p("bash", -c => q(echo $YIKES foo bar baz))->wait;

See also
L<https://github.com/jhthorsen/mojo-ioloop-readwritefork/tree/master/example/tail.pl>
for an example usage from a L<Mojo::Controller>.

=head1 DESCRIPTION

This class enable you to fork a child process and L</read> and L</write> data
to. You can also L<send signals|/kill> to the child and see when the process
ends. The child process can be an external program (bash, telnet, ffmpeg, ...)
or a CODE block running perl.

L<Patches|https://github.com/jhthorsen/mojo-ioloop-readwritefork/pulls> that
enable the L</read> event to see the difference between STDERR and STDOUT are
more than welcome.

=head1 EVENTS

=head2 before_fork

  $self->on(before_fork => sub { my ($self, $pipes) = @_; });

Emitted right before the child process is forked. Example C<$pipes>

  $pipes = {
    # for both conduit "pipe" and "pty"
    stdin_write => $pipe_fh_1_or_pty_object,
    stdout_read => $pipe_fh_2_or_pty_object,

    # only for conduit "pipe"
    stdin_read => $pipe_fh_3,
    stdout_write => $pipe_fh_4,
  }

=head2 close

  $self->on(close => sub { my ($self, $exit_value, $signal) = @_; });

Emitted when the child process exit.

=head2 error

  $self->on(error => sub { my ($self, $str) = @_; });

Emitted when when the there is an issue with creating, writing or reading
from the child process.

=head2 fork

  $self->on(fork => sub { my ($self) = @_; });

Emitted after C<fork()> has been called. Note that the child process might not yet have
been started. The order of things is impossible to say, but it's something like this:

            .------.
            | fork |
            '------'
               |
           ___/ \_________________
          |                       |
          | (parent)              | (child)
      .-------------.             |
      | emit "fork" |    .--------------------.
      '-------------'    | set up filehandles |
                         '--------------------'
                                  |
                          .---------------.
                          | exec $program |
                          '---------------'

See also L</pid> for example usage of this event.

=head2 read

  $self->on(read => sub { my ($self, $buf) = @_; });

Emitted when the child has written a chunk of data to STDOUT or STDERR.

=head1 ATTRIBUTES

=head2 conduit

  $hash = $self->conduit;
  $self = $self->conduit({type => "pipe"});

Used to set the conduit and conduit options. Example:

  $self->conduit({raw => 1, type => "pty"});

=head2 ioloop

  $ioloop = $self->ioloop;
  $self = $self->ioloop(Mojo::IOLoop->singleton);

Holds a L<Mojo::IOLoop> object.

=head2 pid

  $int = $self->pid;

Holds the child process ID. Note that L</start> will start the process after
the IO loop is started. This means that the code below will not work:

  $fork->run("bash", -c => q(echo $YIKES foo bar baz));
  warn $fork->pid; # pid() is not yet set

This will work though:

  $fork->on(fork => sub { my $self = shift; warn $self->pid });
  $fork->run("bash", -c => q(echo $YIKES foo bar baz));

=head1 METHODS

=head2 close

  $self = $self->close("stdin");

Close STDIN stream to the child process immediately.

=head2 run

  $self = $self->run($program, @program_args);
  $self = $self->run(\&Some::Perl::function, @function_args);

Simpler version of L</start>. Can either start an application or run a perl
function.

=head2 run_p

  $p = $self->run_p($program, @program_args);
  $p = $self->run_p(\&Some::Perl::function, @function_args);

Promise based version of L</run>. The L<Mojo::Promise> will be resolved on
L</close> and rejected on L</error>.

=head2 start

  $self = $self->start(\%args);

Used to fork and exec a child process. C<%args> can have:

=over 2

=item * program

Either an application or a CODE ref.

=item * program_args

A list of options passed on to L</program> or as input to the CODE ref.

Note that this module will start L</program> with this code:

  exec $program, @$program_args;

This means that the code is subject for
L<shell injection|https://en.wikipedia.org/wiki/Code_injection#Shell_injection>
unless invoked with more than one argument. This is considered a feature, but
something you should be avare of. See also L<perlfunc/exec> for more details.

=item * env

Passing in C<env> will override the default set of environment variables,
stored in C<%ENV>.

=item * conduit

Either "pipe" (default) or "pty". "pty" will use L<IO::Pty> to simulate a
"pty", while "pipe" will just use L<perlfunc/pipe>. This can also be specified
by using the L</conduit> attribute.

=item * clone_winsize_from

See L<IO::Pty/clone_winsize_from>. This only makes sense if L</conduit> is set
to "pty". This can also be specified by using the L</conduit> attribute.

=item * raw

See L<IO::Pty/set_raw>. This only makes sense if L</conduit> is set to "pty".
This can also be specified by using the L</conduit> attribute.

=back

=head2 write

  $self = $self->write($chunk);
  $self = $self->write($chunk, $cb);

Used to write data to the child process STDIN. An optional callback will be
called once STDIN is drained.

Example:

  $self->write("some data\n", sub {
    my ($self) = @_;
    $self->close;
  });

=head2 kill

  $bool = $self->kill;
  $bool = $self->kill(15); # default

Used to signal the child.

=head1 SEE ALSO

L<Mojo::IOLoop::ForkCall>.

L<https://github.com/jhthorsen/mojo-ioloop-readwritefork/tree/master/example/tail.pl>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013-2016, Jan Henning Thorsen

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=head1 AUTHOR

Jan Henning Thorsen - C<jhthorsen@cpan.org>

=cut
