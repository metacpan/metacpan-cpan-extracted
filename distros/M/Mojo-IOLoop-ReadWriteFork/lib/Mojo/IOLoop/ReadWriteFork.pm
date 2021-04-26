package Mojo::IOLoop::ReadWriteFork;
use Mojo::Base 'Mojo::EventEmitter';

use Errno qw(EAGAIN ECONNRESET EINTR EPIPE EWOULDBLOCK EIO);
use IO::Pty;
use Mojo::Asset::Memory;
use Mojo::IOLoop;
use Mojo::IOLoop::Stream;
use Mojo::IOLoop::ReadWriteFork::SIGCHLD;
use Mojo::Promise;
use Mojo::Util qw(term_escape);
use Scalar::Util qw(blessed);

use constant CHUNK_SIZE => $ENV{MOJO_CHUNK_SIZE} || 131072;
use constant DEBUG      => $ENV{MOJO_READWRITEFORK_DEBUG} && 1;

our $VERSION = '1.02';

our @SAFE_SIG
  = grep { !m!^(NUM\d+|__[A-Z0-9]+__|ALL|CATCHALL|DEFER|HOLD|IGNORE|MAX|PAUSE|RTMAX|RTMIN|SEGV|SETS)$! } keys %SIG;

my $SIGCHLD = Mojo::IOLoop::ReadWriteFork::SIGCHLD->singleton;

has conduit => sub { +{type => 'pipe'} };
sub pid { shift->{pid} || 0; }
has ioloop => sub { Mojo::IOLoop->singleton }, weak => 1;

sub close {
  my $self = shift;
  my $what = $_[0] eq 'stdout' ? 'stdout_read' : 'stdin_write';    # stdout_read is EXPERIMENTAL
  my $fh   = delete $self->{$what} or return $self;
  CORE::close($fh) or $self->emit(error => $!);
  $self;
}

sub run {
  my $args = ref $_[-1] eq 'HASH' ? pop : {};
  my ($self, $program, @program_args) = @_;
  return $self->start({%$args, program => $program, program_args => \@program_args});
}

sub run_and_capture_p {
  my $self    = shift;
  my $asset   = Mojo::Asset::Memory->new(auto_upgrade => 1);
  my $read_cb = $self->on(read => sub { $asset->add_chunk($_[1]) });
  $asset->once(upgrade => sub { $asset = $_[1]; $self->emit(asset => $asset) });
  return $self->emit(asset => $asset)->run_p(@_)->then(sub {$asset})
    ->finally(sub { $self->unsubscribe(read => $read_cb) });
}

sub run_p {
  my $self = shift;
  my $p    = Mojo::Promise->new;
  my @cb;
  push @cb, $self->once(error  => sub { shift->unsubscribe(finish => $cb[1]); $p->reject(@_) });
  push @cb, $self->once(finish => sub { shift->unsubscribe(error  => $cb[0]); $p->resolve(@_) });
  $self->run(@_);
  return $p;
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
  $self->ioloop->next_tick(sub { $self->_start($args) });
  return $self;
}

sub _start {
  my ($self, $args) = @_;
  my ($stdin_read, $stdin_write, $stdout_read, $stdout_write);

  local $!;
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
    warn "[RWF] Invalid conduit ($args->{conduit})\n" if DEBUG;
    return $self->emit(error => "Invalid conduit ($args->{conduit})");
  }

  my $prepare_event = {
    stdin_read   => $stdin_read,
    stdin_write  => $stdin_write,
    stdout_read  => $stdout_read,
    stdout_write => $stdout_write,
  };

  $self->emit(before_fork => $prepare_event);    # LEGACY
  $self->emit(prepare     => $prepare_event);

  return $self->emit(error => "Couldn't fork ($!)") unless defined($self->{pid} = fork);
  return $self->{pid}
    ? $self->_start_parent($args, $stdin_read, $stdin_write, $stdout_read, $stdout_write)
    : $self->_start_child($args, $stdin_read, $stdin_write, $stdout_read, $stdout_write);
}

sub _start_child {
  my ($self, $args, $stdin_read, $stdin_write, $stdout_read, $stdout_write) = @_;

  if (blessed $stdin_write and $stdin_write->isa('IO::Pty')) {
    $stdin_write->make_slave_controlling_terminal;
    $stdin_read = $stdout_write = $stdin_write->slave;
    $stdin_read->set_raw                                         if $args->{raw};
    $stdin_read->clone_winsize_from($args->{clone_winsize_from}) if $args->{clone_winsize_from};
  }

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

  my $errno;
  if (ref $args->{program} eq 'CODE') {
    $! = 0;
    @SIG{@SAFE_SIG} = ('DEFAULT') x @SAFE_SIG;
    eval { $args->{program}->(@{$args->{program_args} || []}); };
    $errno = $@ ? 255 : $!;
    print STDERR $@ if length $@;
  }
  else {
    exec $args->{program}, @{$args->{program_args} || []};
  }

  eval { POSIX::_exit($errno // $!); };
  exit($errno // $!);
}

sub _start_parent {
  my ($self, $args, $stdin_read, $stdin_write, $stdout_read, $stdout_write) = @_;

  $self->_d("Forked $args->{program} @{$args->{program_args} || []}") if DEBUG;
  @$self{qw(stdin_write stdout_read)} = ($stdin_write, $stdout_read);
  @$self{qw(wait_eof wait_sigchld)}   = (1, 1);
  $stdout_read->close_slave if blessed $stdout_read and $stdout_read->isa('IO::Pty');

  my $stream = Mojo::IOLoop::Stream->new($stdout_read)->timeout(0);
  $stream->on(error => sub { $! != EIO && $self->emit(error => "Read error: $_[1]") });
  $stream->on(close => sub { $self->_maybe_terminate('wait_eof') });
  $stream->on(
    read => sub {
      $self->_d(sprintf ">>> RWF\n%s", term_escape $_[1]) if DEBUG;
      $self->emit(read => $_[1]);
    }
  );

  $SIGCHLD->waitpid($self->{pid} => sub { $self->_sigchld(@_) });
  $self->{stream_id} = $self->ioloop->stream($stream);
  $self->emit('fork');    # LEGACY
  $self->emit('spawn');
  $self->_write;
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
  return undef unless my $pid = $self->{pid};
  $self->_d("kill $signal $pid") if DEBUG;
  return kill $signal, $pid;
}

sub _error {
  return if $! == EAGAIN || $! == EINTR || $! == EWOULDBLOCK;
  return $_[0]->kill if $! == ECONNRESET || $! == EPIPE;
  return $_[0]->emit(error => $!)->kill;
}

sub _d { warn "-- [$_[0]->{pid}] $_[1]\n" }

sub _maybe_terminate {
  my ($self, $pending_event) = @_;
  delete $self->{$pending_event};
  return if $self->{wait_eof} or $self->{wait_sigchld};

  delete $self->{stdin_write};
  delete $self->{stdout_read};

  my @errors;
  for my $cb (@{$self->subscribers('close')}, @{$self->subscribers('finish')}) {
    push @errors, $@ unless eval { $self->$cb(@$self{qw(exit_value signal)}); 1 };
  }

  $self->emit(error => $_) for @errors;
}

sub _sigchld {
  my ($self, $status, $pid) = @_;
  my ($exit_value, $signal) = ($status >> 8, $status & 127);
  $self->_d("Exit exit_value=$exit_value, signal=$signal") if DEBUG;
  @$self{qw(exit_value signal)} = ($exit_value, $signal);
  $self->_maybe_terminate('wait_sigchld');
}

sub _write {
  my $self = shift;

  return unless length $self->{stdin_buffer};
  my $stdin_write = $self->{stdin_write};
  my $written     = $stdin_write->syswrite($self->{stdin_buffer});
  return $self->_error unless defined $written;
  my $chunk = substr $self->{stdin_buffer}, 0, $written, '';
  $self->_d(sprintf "<<< RWF\n%s", term_escape $chunk) if DEBUG;

  if (length $self->{stdin_buffer}) {

    # This is one ugly hack because it does not seem like IO::Pty play
    # nice with Mojo::Reactor(::EV) ->io(...) and ->watch(...)
    $self->ioloop->timer(0.01 => sub { $self and $self->_write });
  }
  else {
    $self->emit('drain');
  }
}

1;

=encoding utf8

=head1 NAME

Mojo::IOLoop::ReadWriteFork - Fork a process and read/write from it

=head1 VERSION

1.02

=head1 SYNOPSIS

  my $fork = Mojo::IOLoop::ReadWriteFork->new;

  # Emitted if something terrible happens
  $fork->on(error => sub { my ($fork, $error) = @_; warn $error; });

  # Emitted when the child completes
  $fork->on(finish => sub { my ($fork, $exit_value, $signal) = @_; Mojo::IOLoop->stop; });

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
  $fork->on(read => sub { ... });
  $fork->run_p("bash", -c => q(echo $YIKES foo bar baz))->wait;

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

=head2 asset

  $fork->on(asset => sub { my ($fork, $asset) = @_; });

Emitted at least once when calling L</run_and_capture_p>. C<$asset> can be
either a L<Mojo::Asset::Memory> or L<Mojo::Asset::File> object.

  $fork->on(asset => sub {
    my ($fork, $asset) = @_;
    # $asset->auto_upgrade(1) is set by default
    $asset->max_memory_size(1) if $asset->can('max_memory_size');
  });

=head2 error

  $fork->on(error => sub { my ($fork, $str) = @_; });

Emitted when when the there is an issue with creating, writing or reading
from the child process.

=head2 drain

  $fork->on(drain => sub { my ($fork) = @_; });

Emitted when the buffer has been written to the sub process.

=head2 finish

  $fork->on(finish => sub { my ($fork, $exit_value, $signal) = @_; });

Emitted when the child process exit.

=head2 read

  $fork->on(read => sub { my ($fork, $buf) = @_; });

Emitted when the child has written a chunk of data to STDOUT or STDERR.

=head2 spawn

  $fork->on(spawn => sub { my ($fork) = @_; });

Emitted after C<fork()> has been called. Note that the child process might not yet have
been started. The order of things is impossible to say, but it's something like this:

            .------.
            | fork |
            '------'
               |
           ___/ \_______________
          |                     |
          | (parent)            | (child)
    .--------------.            |
    | emit "spawn" |   .--------------------.
    '--------------'   | set up filehandles |
                       '--------------------'
                                |
                         .---------------.
                         | exec $program |
                         '---------------'

See also L</pid> for example usage of this event.

=head2 start

  $fork->on(start => sub { my ($fork, $pipes) = @_; });

Emitted right before the child process is forked. Example C<$pipes>

  $pipes = {
    # for both conduit "pipe" and "pty"
    stdin_write => $pipe_fh_1_or_pty_object,
    stdout_read => $pipe_fh_2_or_pty_object,

    # only for conduit "pipe"
    stdin_read => $pipe_fh_3,
    stdout_write => $pipe_fh_4,
  }

=head1 ATTRIBUTES

=head2 conduit

  $hash = $fork->conduit;
  $fork = $fork->conduit({type => "pipe"});

Used to set the conduit and conduit options. Example:

  $fork->conduit({raw => 1, type => "pty"});

=head2 ioloop

  $ioloop = $fork->ioloop;
  $fork = $fork->ioloop(Mojo::IOLoop->singleton);

Holds a L<Mojo::IOLoop> object.

=head2 pid

  $int = $fork->pid;

Holds the child process ID. Note that L</start> will start the process after
the IO loop is started. This means that the code below will not work:

  $fork->run("bash", -c => q(echo $YIKES foo bar baz));
  warn $fork->pid; # pid() is not yet set

This will work though:

  $fork->on(fork => sub { my $fork = shift; warn $fork->pid });
  $fork->run("bash", -c => q(echo $YIKES foo bar baz));

=head1 METHODS

=head2 close

  $fork = $fork->close("stdin");

Close STDIN stream to the child process immediately.

=head2 run

  $fork = $fork->run($program, @program_args);
  $fork = $fork->run(\&Some::Perl::function, @function_args);

Simpler version of L</start>. Can either start an application or run a perl
function.

=head2 run_and_capture_p

  $p = $fork->run_and_capture_p(...)->then(sub { my $asset = shift });

L</run_and_capture_p> takes the same arguments as L</run_p>, but the
fullfillment callback will receive a L<Mojo::Asset> object that holds the
output from the command.

See also the L</asset> event.

=head2 run_p

  $p = $fork->run_p($program, @program_args);
  $p = $fork->run_p(\&Some::Perl::function, @function_args);

Promise based version of L</run>. The L<Mojo::Promise> will be resolved on
L</finish> and rejected on L</error>.

=head2 start

  $fork = $fork->start(\%args);

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

  $fork = $fork->write($chunk);
  $fork = $fork->write($chunk, $cb);

Used to write data to the child process STDIN. An optional callback will be
called once STDIN is drained.

Example:

  $fork->write("some data\n", sub { shift->close });

=head2 kill

  $bool = $fork->kill;
  $bool = $fork->kill(15); # default

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
