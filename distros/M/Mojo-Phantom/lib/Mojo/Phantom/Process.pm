package Mojo::Phantom::Process;

use Mojo::Base 'Mojo::EventEmitter';

use constant DEBUG => $ENV{MOJO_PHANTOM_DEBUG};

use Mojo::IOLoop;
use Mojo::IOLoop::Stream;

has [qw/error exit_status pid stream/];
has arguments => sub { [] };

has exe => 'phantomjs';

sub kill {
  my ($self) = @_;
  return unless my $pid = $self->pid;
  warn "Killing $pid\n" if DEBUG;
  kill KILL => $pid;
  waitpid $pid, 0;
  $self->exit_status($?);
  $self->stream->close;
};

sub start {
  my ($self, $file) = @_;

  my @command = ($self->exe, @{ $self->arguments }, "$file");
  warn 'Spawning: ' . (join ', ', map { "'$_'" } @command) . "\n" if DEBUG;
  my $pid = open my $pipe, '-|', @command;
  die 'Could not spawn' unless defined $pid;
  $self->pid($pid);
  $self->emit(spawn => $pid);

  my $stream = Mojo::IOLoop::Stream->new($pipe);
  my $id = Mojo::IOLoop->stream($stream);
  $self->stream($stream);
  $stream->on(error => sub { $self->error($_[1])->kill });
  $stream->on(read  => sub { $self->emit(read => $_[1]) });
  $stream->on(close => sub {
    my $pid = delete $self->{pid};
    warn "Stream for $pid closed\n" if DEBUG;
    $self->{exit_status} ||= $?;
    $self->emit('close');
  });

  return $self;
}

1;

=head1 NAME

Mojo::Phantom::Process - Represents the running phantom process and its stream

=head1 SYNOPSIS

  my $proc = Mojo::Phantom::Process->new;
  $proc->start($file);

=head1 DESCRIPTION

A very utilitarian class representing a single execution of the PhantomJS executable.
It forks the new process and attaches a stream watcher to its STDOUT and attaches to various stream events.
This class is just process management and transport.
All real behavior is defined by the executed javascript file and the listeners to the events defined by this class.

=head1 EVENTS

L<Mojo::Phantom::Process> inherits all the events from L<Mojo::EventEmitter> and emits the following new ones

=head2 close

  $proc->on(close => sub { ($proc) = @_; ... });

Emitted when the process has exitted (possibly with errors) and the stream has closed.
The user will want to check L</error> and L</exit_status>.

=head2 read

  $proc->on(read => sub { ($proc, $bytes) = @_; ... });

Re-emitted after bytes have been read from the L</stream>.

=head2 spawn

  $proc->on(spawn => sub { my ($proc, $pid) = @_; ... });

Emitted just after the child process is spawned.
Passed the new child pid.

=head1 ATTRIBUTES

=head2 arguments

Holds an array reference of arguments passed directly to the PhantomJS executable when it is run.

  my @phantom_args = ('--proxy=127.0.0.1:8080', '--proxy-type='socks5');
  my $proc = Mojo::Phantom::Process->new(arguments => \@phantom_args);

=head2 error

Holds errors caught from the L</stream>'s error event.
Note that when such an error event is caught, the process is then killed by the L</kill> method immediately afterwards.

=head2 exit_status

The exit status C<$?> from the closed pid.

=head2 pid

The pid of the spawned process.
The stream's close event will clear this value once the process has ended.

=head2 stream

The instance of L<Mojo::IOLoop::Stream> used to monitor the STDOUT of the external process.
It is created automatically attacted to the L<Mojo::IOLoop/singleton> by running L</start>.

=head2 exe

The executable name or path to call PhantomJS.  You may substitute a compatible platform, for example using C<casperjs> to use
CasperJS.

=head1 METHODS

=head2 kill

  $proc->kill

Kills the child process (KILL) and closes the stream.
Note that since the process might exit before the kill signal is sent, it is not guaranteed that the L</exit_status> will reflect the signal.

=head2 start

  $proc->start($file);

Starts a PhantomJS in a child process running a given file, creates a stream listener and attaches to its events.
Returns itself.

