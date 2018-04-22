package MooX::Async::Console::TCP;

=head1 NAME

MooX::Async::Console::TCP - A TCP framing module for MooX::Async::Console

=head1 SYNOPSIS

See L<MooX::Async::Console>

=head1 DESCRIPTION

A L<IO::Async::Listener> subclass which listens on a TCP port. Each
connection is created as a L<MooX::Async::Console::TCPClient> module
which interpets the byte stream and invokes L</on_command> when a
command is ready to be executed.

=head1 BUGS

Certainly.

=cut

use Modern::Perl '2017';
use strictures 2;

use Moo;
use Future;
use MooX::Async;
use MooX::Async::Console::TCPClient;
use Scalar::Util  qw(blessed);
use namespace::clean;

extends MooXAsync('Listener');

with 'MooX::Role::Logger';

=head1 PUBLIC INTERFACE

=head2 ATTRIBUTES

=over

=item address (default: C<127.0.0.1>)

The IP address to listen for connections on.

=item port (default: C<$ENV{MXACPORT} // 0>)

The TCP port to listen for connections on. The default is 0 which lets
the kernel select a port. The value in this attribute is updated when
the socket is bound.

=back

=cut

has address => is => ro  => default => '127.0.0.1';
has port    => is => rwp => default => ($ENV{MXACPORT} // 0);

=head2 EVENTS

=over

=item on_command

Must be included in the constuctor. Invoked by this module to execute
a command. This interface is described in
L<MooX::Async::Console/on_command>.

Arguments:

=over

=item command

Name of the command to execute.

=item inform

Coderef with which the command can send messages over the connection.

=item args

Arrayref of arguments to execute the command with.

=item then

L<Future> to complete or fail when the command is finished.

=back

=item on_terminate

Invoked by this module when the connection has terminated.

Arguments: none.

=item on_success

Invoked by this module when a command has completed successfully.

Arguments: The result the command's L<Future> was completed with.

If the implementation of this event returns a L<Future> then that is
used to provide the result sent to the client.

=item on_failure

Invoked by this module when a command has failed.

Arguments: The L<Future>'s failure.

=back

=cut

event 'on_command';
event $_, sub {} for qw(on_terminate on_success on_failure);

=head1 PRIVATE INTERFACE

=head2 CONSTRUCTION

Begins listening on the port when it's added to the loop.

=cut

after _add_to_loop => sub {
  my $self = shift;
  $self->listen(
    host     => $self->address,
    service  => $self->port,
    socktype => 'stream',
  )->then(sub {
    $self->_set_port($self->read_handle->sockport);
    $self->_logger->noticef('TCP Console listening on %s:%s', $self->address, $self->port);
    Future->done();
  })->get
};

=pod

Detaches all clients when removed from the loop.

=cut

before _remove_from_loop => sub {
  if ($_[0]->children) {
    $_[0]->_logger->warningf('TCP Console closed with %u active client[s]', scalar $_[0]->children);
    $_[0]->_detach_client($_) for $_[0]->children;
  }
};

=pod

C<_init>, which is used during the parent class
L<IO::Async::Listener>'s own construction, replaces its C<$args> with
a single entry of C<handle_constructor>.

=cut

around _init => sub {
  my $orig = shift;
  my $self = shift;

=pod

C<handle_constructor> contains a coderef to attach the client
implemented by L<MooX::Async::Console::TCPClient> and handle its
L<on_line> and L<on_close> events.

=cut

  my $line  = sub { unshift @_, $self; goto \&__on_line };
  my $close = sub { unshift @_, $self; goto \&__on_close};
  %{$_[0]} = (handle_constructor => sub {
    MooX::Async::Console::TCPClient->new(on_close => $close, on_line => $line);
  });
  $self->$orig(@_);
};

use namespace::clean '__close';
sub __on_close {
  my $self = shift;
  $self->invoke_event(on_terminate =>);
  $self->_logger->informf('Client disconnected from %s:%s', $_[0]->address, $_[0]->port);
  $self->_detach_client($_[0]);
}

=head3 Client's on_line event handler

For the present this is extremely simple. The client types in a line
of text and ends it with newline. That line is broken up into a list
on whitespace and the first word in the list is the command name, the
rest its args.

Only one command may be running at a time. This is enforced by the
C<$state> variable.

=cut

use namespace::clean '__line';
sub __on_line {
  my $self = shift;
  my $client = shift;
  my ($cmd, @args) = split ' ', shift;
  my $state;            # for now - false nothing, true busy;
  die 'One command at a time for now' if $state;
  $state++;
  my $quit;
  $self->_logger->debugf('Received command %s %s', $cmd, \@args);

=pod

The L</on_command> event handler is invoked with a new L<Future>.

=cut

  my $future = $self->loop->new_future;
  $self->adopt_future(
    $future->followed_by(sub {
      # Why is this useful?
      return Future->fail($_[0]->failure) if $_[0]->failure;
      my $command_future = $_[0]->get;
      return Future->done($command_future->get) if $command_future->is_done;

=pod

Disconnecting the client is treated specially so that everything is
shutdown in an orderly manner.

If the L<Future> which is given to the command handler is failed with
the word C<quit> then this is flagged using C<$quit> and the L<Future>
is replaced with a done L<Future> with an appropriate message
substituted.

=cut

      return Future->fail($command_future->failure) if $command_future->failure ne 'quit';
      $self->_logger->debugf('Requested disconnect');
      $quit = 1;
      return Future->done('disconnecting...');

=pod

After the L<Future> completes succesfully a message is returned to the
client containing its result.

=cut

    })->then(sub {
      my $r = $self->invoke_event(on_success => @_);
      @_ = $r->get if blessed $r and $r->DOES('Future');
      my $extra = @_ ? ' - ' . (join ' ', ('%s')x@_) : '';
      # TODO: Figure out a better way to do this
      $client->say(sprintf "OK$extra", Log::Any::Proxy::_stringify_params(@_));

=pod

If the C<$quit> flag is true the client is detached.

=cut

      if ($quit) {
        $self->_logger->informf('Client disconnecting from %s:%s', $client->address, $client->port);
        $self->_detach_client($client);
      }
      Future->done(@_);

=pod

If the command handler's L<Future> was failed then a message is logged
and sent to the client.

=cut

    })->else(sub {
      # TODO: @_ may not end with a hash
      my ($message, $category, %args) = @_;
      local $self->_logger->context->{ex} = $message;
      $self->invoke_event(on_failure => %args);
      if ($category and $category eq 'console'
            and $message and $message eq "Unknown command: $cmd") {
        my $max = 1024;
        chomp $message;
        $self->_logger->debug($message);
        $message = substr($message, 0, $max-5) . " ..." if length $message > $max;
        $client->say($message);
      } else {
        $self->_logger->noticef('Command %s failed: %s', $cmd, $args{ex});
        $client->say(sprintf 'Command %s failed: %s', $cmd, $args{ex});
      }
      Future->done(@_);
    })->on_ready(sub { $state-- }));
  $self->invoke_event(on_command =>
                        command => $cmd,
                        inform  => sub { $client->say(join "\n", @_) },
                        args    => \@args,
                        then    => $future);
  return;
}

=head2 METHODS

=over

=item _attach_client($client)

=item _detach_client($client)

Add & remove the new client as a child of this notifier.

=back

=cut

sub _attach_client {
  $_[0]->_logger->debugf('Attaching TCP client %s', $_[1]);
  $_[0]->add_child($_[1]);
}

sub _detach_client {
  $_[0]->_logger->debugf('Detaching TCP client %s', $_[1]);
  $_[1]->flush unless $_[1]->{read_eof};
  $_[0]->remove_child($_[1]);
}

=head2 EVENTS

=over

=item on_accept

Implemented by this module, attaches the new client which has connected.

=back

=cut

sub on_accept {
  my $self = shift;
  my ($stream) = @_;
  $self->_logger->informf('New client connected from %s:%s', $stream->address, $stream->port);
  $self->_attach_client($stream);
}

1;

=head1 SEE ALSO

L<MooX::Async::Console>

L<MooX::Async::Console::TCPClient>

=head1 AUTHOR

Matthew King <chohag@jtan.com>

=cut
