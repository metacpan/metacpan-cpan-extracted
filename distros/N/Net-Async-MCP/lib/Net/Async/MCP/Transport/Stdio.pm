package Net::Async::MCP::Transport::Stdio;
# ABSTRACT: Stdio MCP transport via subprocess JSON-RPC
use strict;
use warnings;
use parent 'IO::Async::Notifier';

use Future;
use JSON::MaybeXS;
use Carp qw( croak );
use Scalar::Util qw( weaken );


sub _init {
  my ( $self, $params ) = @_;
  $self->{command} = delete $params->{command}
    or croak "command is required";
  $self->{pending} = {};
  $self->{next_id} = 0;
  $self->{buffer}  = '';
  $self->{closed}  = 0;
  $self->{json}    = JSON::MaybeXS->new(utf8 => 1, convert_blessed => 1);
  $self->SUPER::_init($params);
}

sub configure {
  my ( $self, %params ) = @_;
  if (exists $params{command}) {
    $self->{command} = delete $params{command};
  }
  $self->{on_notification} = delete $params{on_notification}
    if exists $params{on_notification};
  $self->SUPER::configure(%params);
}

sub _add_to_loop {
  my ( $self, $loop ) = @_;
  $self->SUPER::_add_to_loop($loop);

  require IO::Async::Process;

  # These callbacks end up on the process, and on the child streams the process
  # owns, while the transport owns the process - so capturing the transport
  # strongly here would close a cycle no refcount ever breaks, and the transport
  # would outlive its own client. Weakening them costs nothing: as long as
  # either callback can still fire, the loop holds the transport for us. The
  # loop keeps its notifiers alive strongly, and taking the transport out of the
  # loop takes the process out with it, which unwatches the child and silences
  # both callbacks. So the weak reference is never undef where it matters; the
  # guards below are for the DESTROY-ordering case only.
  weaken( my $weak_self = $self );

  my $process = IO::Async::Process->new(
    command => $self->{command},
    stdin   => { via => 'pipe_write' },
    stdout  => {
      on_read => sub {
        my ( $stream, $buffref, $eof ) = @_;
        my $self = $weak_self or return 0;
        $self->_on_stdout_read($buffref, $eof);
        return 0;
      },
    },
    stderr => {
      on_read => sub {
        my ( $stream, $buffref, $eof ) = @_;
        $$buffref = '';
        return 0;
      },
    },
    on_finish => sub {
      my ( $proc, $exitcode ) = @_;
      my $self = $weak_self or return;
      $self->_on_finish($exitcode);
    },
  );

  $self->{process} = $process;
  $self->add_child($process);
}

sub _remove_from_loop {
  my ( $self, $loop ) = @_;

  # Leaving the loop takes the process along, it being a child of this
  # transport, and with it the watches on the child's streams that _on_finish
  # waits for. So _on_finish will not run again, and everything it would have
  # settled has to be settled here instead, or it stays pending for the rest
  # of the program: the requests still waiting for an answer, and a close
  # still waiting for the exit.
  #
  # Both are failed rather than completed, because completing either would be
  # a claim this transport cannot make. Nothing here saw a response go missing
  # or a process die; what it knows is that neither can reach it any more. The
  # two messages differ in what was lost so a caller holding both can tell
  # them apart.
  #
  # Same shape as _on_finish, and for the same reasons: the keys are taken
  # before the loop, so a handler that touches the pending table as its future
  # fails cannot disturb the iteration, and every future is deleted as it is
  # settled, so neither path can reach one the other already answered.
  for my $id (keys %{$self->{pending}}) {
    my $future = delete $self->{pending}{$id};
    $future->fail("MCP server process left the loop before the request was answered")
      if $future && !$future->is_ready;
  }

  if ($self->{close_future} && !$self->{close_future}->is_ready) {
    ( delete $self->{close_future} )
      ->fail("MCP server process left the loop before it exited");
  }

  $self->SUPER::_remove_from_loop($loop);
}

sub send_request {
  my ( $self, $method, $params, %options ) = @_;

  if ($self->{closed}) {
    return Future->fail("MCP server process has exited");
  }

  # resolve_on_notification names the notification a server answers a request
  # with in place of a response - how subscriptions/listen is answered. This
  # transport cannot settle a request from a notification: the answer would
  # arrive at on_notification like any other, leaving the request waiting for
  # a response the server is not going to send. Refused on the spot rather
  # than left to hang, and nothing is written: a request that went out anyway
  # would open a subscription on the server that nothing here could stop.
  if (defined $options{resolve_on_notification}) {
    return Future->fail("MCP subscriptions/listen is not usable over the stdio "
      . "transport: the transport cannot settle a request from a notification "
      . "(resolve_on_notification)");
  }

  my $id = ++$self->{next_id};
  my $request = {
    jsonrpc => '2.0',
    id      => $id,
    method  => $method,
    defined $params ? ( params => $params ) : (),
  };

  my $json_line = $self->{json}->encode($request) . "\n";
  $self->{process}->stdin->write($json_line);

  my $future = $self->loop->new_future;
  $self->{pending}{$id} = $future;

  # The pending table holds the future and the future holds this callback, so
  # the callback must not hold the transport: that closes a reference cycle no
  # refcount ever breaks. Future drops its on_cancel list as soon as a future
  # is marked ready, so a request answered by the server, or failed by
  # _on_finish, never reaches this code.
  weaken( my $weak_self = $self );
  $future->on_cancel(sub {
    my $self = $weak_self or return;
    delete $self->{pending}{$id};
    return if $self->{closed};
    $self->send_notification('notifications/cancelled', { requestId => $id });
    return;
  });

  return $future;
}


sub send_notification {
  my ( $self, $method, $params ) = @_;

  if ($self->{closed}) {
    return Future->fail("MCP server process has exited");
  }

  my $request = {
    jsonrpc => '2.0',
    method  => $method,
    defined $params ? ( params => $params ) : (),
  };

  my $json_line = $self->{json}->encode($request) . "\n";
  $self->{process}->stdin->write($json_line);

  return Future->done;
}


sub close {
  my ( $self ) = @_;
  return Future->done if $self->{closed};

  $self->{closed} = 1;

  if ($self->{process} && $self->{process}->is_running) {
    my $future = $self->loop->new_future;
    $self->{close_future} = $future;
    $self->{process}->kill('TERM');
    return $future;
  }

  return Future->done;
}


sub is_alive { !$_[0]->{closed} }


sub mirrors_header_params { 0 }



sub _on_stdout_read {
  my ( $self, $buffref, $eof ) = @_;
  $self->{buffer} .= $$buffref;
  $$buffref = '';

  while ($self->{buffer} =~ s/^(.*?)\n//) {
    my $line = $1;
    $line =~ s/\r$//;
    next if $line eq '';

    my $response = eval { $self->{json}->decode($line) };
    next unless $response && ref $response eq 'HASH';

    # A line that answers no request is a notification the server sent of its
    # own accord, and goes to the event rather than the pending table: the
    # notifications/progress of a running tools/call is only worth anything
    # while the call is still running. A line with neither an id nor a method
    # is no JSON-RPC message this client can place at all, and is dropped.
    my $id = $response->{id};
    if (!defined $id) {
      next unless defined $response->{method};
      $self->maybe_invoke_event(on_notification => $response);
      next;
    }

    # An id with neither a result nor an error is a server-initiated request,
    # which this client does not answer. It has to be recognised before the
    # lookup below rather than after it: the server numbers its own requests,
    # nothing keeps those numbers apart from ours, and a collision would
    # otherwise answer a live request of ours with nothing.
    next unless exists $response->{result} || exists $response->{error};

    my $future = delete $self->{pending}{$id};
    next unless $future;

    # The raw JSON-RPC error object travels with the message as the details of
    # a failure in category "mcp", so a caller can read the code and any
    # error->{data} the server sent instead of parsing the message for them.
    if (my $err = $response->{error}) {
      $future->fail("MCP error $err->{code}: $err->{message}", mcp => $err);
    }
    else {
      $future->done($response->{result});
    }
  }
}

sub _on_finish {
  my ( $self, $exitcode ) = @_;
  $self->{closed} = 1;

  for my $id (keys %{$self->{pending}}) {
    my $future = delete $self->{pending}{$id};
    $future->fail("MCP server process exited (code $exitcode)")
      if $future && !$future->is_ready;
  }

  if ($self->{close_future} && !$self->{close_future}->is_ready) {
    $self->{close_future}->done;
  }
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Async::MCP::Transport::Stdio - Stdio MCP transport via subprocess JSON-RPC

=head1 VERSION

version 0.004

=head1 SYNOPSIS

    # Usually created automatically by Net::Async::MCP
    use IO::Async::Loop;
    use Net::Async::MCP;

    my $loop = IO::Async::Loop->new;
    my $mcp = Net::Async::MCP->new(
        command => ['npx', '@anthropic/mcp-server-web-search'],
    );
    $loop->add($mcp);

=head1 DESCRIPTION

L<Net::Async::MCP::Transport::Stdio> communicates with an external MCP server
process via stdin/stdout using newline-delimited JSON-RPC 2.0. The subprocess
is managed as an L<IO::Async::Process> child notifier.

This transport works with any MCP server that supports the stdio transport,
regardless of implementation language (Perl, Node.js, Python, Go, etc.).

Requests are matched to responses by their JSON-RPC C<id> field. Each pending
request is represented by a L<Future> that resolves when the matching response
arrives. If the subprocess exits unexpectedly, all pending futures are failed
with an error message including the exit code.

The subprocess speaks on its own as well as in answer: a line carrying no
C<id> is a server-initiated notification - C<notifications/progress> and
C<notifications/message> during a long running C<tools/call> above all - and
is delivered to L</on_notification> the moment it is read, rather than waiting
for a response it is not part of.

This transport is selected automatically by L<Net::Async::MCP> when constructed
with a C<command> argument.

=head2 send_request

    my $future = $transport->send_request($method, \%params);

Encodes a JSON-RPC request and writes it as a newline-terminated JSON line to
the subprocess stdin. Returns a L<Future> that resolves to the C<result> value
when the matching response is read from stdout, or fails with an error if the
server returns a JSON-RPC error or the process exits.

Everything the subprocess writes before that response is read as it arrives.
A line carrying no C<id> is a notification the server sent of its own accord
and is delivered to L</on_notification> the moment it lands, so the
C<notifications/progress> and C<notifications/message> of a long running call
reach a caller while the call is still running, rather than after it. A line
with an C<id> but neither a C<result> nor an C<error> is a server-initiated
request, which this client does not answer and drops.

A JSON-RPC error fails the L<Future> with more than its message. L<Future>'s
failure convention is C<< ( $message, $category, @details ) >>, so the failure
reads C<< ( "MCP error $code: $message", 'mcp', $error ) >>: in scalar context
C<< ->failure >> is the message and nothing has changed, and in list context
the raw JSON-RPC error object comes with it.

    my ( $message, $category, $error ) = $future->failure;
    if (($category // '') eq 'mcp') {
      my $code      = $error->{code};          # -32601, -32602, ...
      my $supported = $error->{data}{supported};
    }

The C<mcp> category marks a genuine JSON-RPC error from the server and nothing
else. The failures this transport raises on its own - a request sent after the
subprocess has exited, a request still pending when it does, and a request
still pending when the transport leaves its loop - carry their message alone,
so a caller that finds no category knows there is no server error object
behind it.

Fails immediately if the subprocess has already exited.

Removing the transport from its L<IO::Async::Loop> while the request is still
pending fails it with C<MCP server process left the loop before the request
was answered>. The process leaves the loop with the transport that owns it, so
no answer can reach this client any more, and a L<Future> that would wait for
one forever is better ended with the reason it will not arrive. The message
differs from the one a pending L</close> is failed with, so a caller holding
both can tell which loss it is looking at.

Cancelling the returned L<Future> cancels the request: the pending entry is
dropped, so a response that still arrives for it is discarded, and a
C<notifications/cancelled> notification naming that request in C<requestId> is
written to the subprocess stdin. No C<reason> is sent, since C<< ->cancel >>
carries no argument to put there. Nothing is written if the future is already
done or failed, or if the subprocess has exited: a cancellation never writes
into a dead pipe.

This is the stdio form of cancellation. On Streamable HTTP a request is
cancelled by closing its response stream instead, so
L<Net::Async::MCP::Transport::HTTP> sends no such notification. Note that an
MCP server is free to ignore the notification and finish the request anyway;
cancelling only guarantees that this client stops caring about the answer.

Accepts the same optional trailing name/value options as the other transports,
C<header_params> among them, and ignores all but one: they describe how a
request is mirrored into HTTP headers, of which a JSON-RPC line on stdin has
none. The exception is C<resolve_on_notification>, which names the
notification a server answers a request with in place of a response - how a
C<subscriptions/listen> is answered. This transport cannot settle a request
from a notification: the answer would arrive at L</on_notification> like any
other, leaving the request waiting for a response the server is not going to
send. A request carrying that option therefore fails on the spot rather than
hang. See L<Net::Async::MCP::Transport::HTTP/send_request>.

=head2 send_notification

    my $future = $transport->send_notification($method, \%params);

Encodes a JSON-RPC notification (no C<id> field, no response expected) and
writes it to the subprocess stdin. Returns an immediately resolved L<Future>.

Fails immediately if the subprocess has already exited.

=head2 close

    my $future = $transport->close;

Sends SIGTERM to the subprocess and returns a L<Future> that resolves when
the process exits. If the process has already exited, returns an immediately
resolved L<Future>.

Removing the transport from its L<IO::Async::Loop> while that L<Future> is
still pending fails it with C<MCP server process left the loop before it
exited>. The process leaves the loop with the transport that owns it, so its
exit can no longer be observed from here, and a L<Future> that would wait for
it forever is better ended with the reason it will not arrive. Wait for the
close before removing the transport where the exit itself matters.

=head2 is_alive

    my $alive = $transport->is_alive;

Returns true while the subprocess can still carry requests, and false once it
has exited or L</close> has been called. Used by L<Net::Async::MCP/ping> for
its transport-level liveness check.

=head2 mirrors_header_params

    my $mirrors = $transport->mirrors_header_params;

Always false: a JSON-RPC line on stdin has no headers to mirror tool arguments
annotated with C<x-mcp-header> into, so L<Net::Async::MCP/call_tool> resolves
none and never fetches a tool list to do it.

=head2 on_notification

    my $transport = Net::Async::MCP::Transport::Stdio->new(
        command         => [ 'my-mcp-server' ],
        on_notification => sub {
            my ( $transport, $notification ) = @_;
            warn "$notification->{method}\n";
        },
    );

Invoked for every server-initiated notification read from the subprocess
stdout, with the decoded JSON-RPC notification as it stood on the wire -
C<method> and, where the notification has any, C<params>. The
C<notifications/progress> of a running C<tools/call> is what a caller usually
waits for here, and it is only worth anything while the call is still running,
which is why it is an event and not part of the L<Future> the call resolves
with.

Set through C<new> or C<configure> like any L<IO::Async::Notifier> event, or
by a subclass implementing a method of this name. Notifications are dropped
while nothing handles them: a server sends them whether or not this client
asked, and there is nothing sensible to do with one no caller wants.

=head1 SEE ALSO

=over 4

=item * L<Net::Async::MCP> - Main client module that uses this transport

=item * L<Net::Async::MCP::Transport::InProcess> - Alternative transport for in-process Perl servers

=item * L<IO::Async::Process> - Subprocess management used internally

=item * L<IO::Async::Notifier> - Base class

=back

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-net-async-mcp/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
