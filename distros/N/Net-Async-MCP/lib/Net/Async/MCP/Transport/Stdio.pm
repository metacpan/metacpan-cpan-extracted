package Net::Async::MCP::Transport::Stdio;
# ABSTRACT: Stdio MCP transport via subprocess JSON-RPC
use strict;
use warnings;
use parent 'IO::Async::Notifier';

use Future;
use JSON::MaybeXS;
use Encode qw( decode );
use Carp qw( croak );
use Scalar::Util qw( weaken );

use Net::Async::MCP::JSONRPC;


sub _init {
  my ( $self, $params ) = @_;
  $self->{command} = delete $params->{command}
    or croak "command is required";
  $self->{pending} = {};
  $self->{next_id} = 0;
  $self->{buffer}  = '';
  $self->{closed}  = 0;
  $self->{json}    = JSON::MaybeXS->new(utf8 => 1, convert_blessed => 1);

  $self->{stderr_buffer} = '';
  $self->{stderr_tail}   = [];
  $self->SUPER::_init($params);
}

# Private: how many lines of the server's stderr are kept for stderr_tail and
# the failure of the requests it leaves unanswered.
my $STDERR_TAIL_LINES = 20;

sub configure {
  my ( $self, %params ) = @_;
  if (exists $params{command}) {
    $self->{command} = delete $params{command};
  }
  for my $key (qw( env cwd timeout on_notification on_stderr on_request )) {
    $self->{$key} = delete $params{$key} if exists $params{$key};
  }
  $self->SUPER::configure(%params);
}


sub _add_to_loop {
  my ( $self, $loop ) = @_;
  $self->SUPER::_add_to_loop($loop);

  require IO::Async::Process;

  # A working directory that does not exist is checked here rather than left to
  # IO::Async, which croaks about it from inside loop->add - halfway through
  # adding this transport, and before anyone holds a request that could carry
  # the reason. Failing the start instead makes it the answer to the first
  # request, the same as a command that cannot be executed.
  my $cwd = $self->{cwd};
  if (defined $cwd && !-d $cwd) {
    $self->{closed}       = 1;
    $self->{exit_message} = $self->_cannot_run("no such working directory '$cwd'");
    return;
  }

  my @setup;
  push @setup, env   => $self->_child_env if $self->{env};
  push @setup, chdir => $cwd              if defined $cwd;

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
    setup   => \@setup,
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
        my $self = $weak_self or do { $$buffref = ''; return 0 };
        $self->_on_stderr_read($buffref, $eof);
        return 0;
      },
    },
    on_finish => sub {
      my ( $proc, $exitcode ) = @_;
      my $self = $weak_self or return;
      $self->_on_finish($exitcode);
    },
    # A command that could not be executed at all. Without this handler
    # IO::Async reports it through on_finish as an ordinary exit, and the
    # reason - the errno of the failed exec - would be lost.
    on_exception => sub {
      my ( $proc, $exception, $errno, $exitcode ) = @_;
      my $self = $weak_self or return;
      $self->_on_finish($exitcode,
        $self->_cannot_run(length "$errno" ? "$errno" : $exception // 'unknown error'));
    },
  );

  $self->{process} = $process;
  $self->add_child($process);
}

# Private: the environment of the subprocess - this process's own, with env
# laid over it, a key whose value is undef removing that variable.
sub _child_env {
  my ( $self ) = @_;
  my %env     = %ENV;
  my $overlay = $self->{env};
  for my $key (keys %$overlay) {
    if (defined $overlay->{$key}) { $env{$key} = $overlay->{$key} }
    else                          { delete $env{$key} }
  }
  return \%env;
}

# Private: the one-line reason a subprocess never got to run.
sub _cannot_run {
  my ( $self, $reason ) = @_;
  my $command = $self->{command};
  my $program = ref $command eq 'ARRAY' ? $command->[0] : $command;
  $reason =~ s/\s+\z//;
  return 'MCP server failed to start: cannot run '.$program.': '.$reason;
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

  if (my $escalation = delete $self->{close_escalation}) {
    $escalation->cancel;
  }

  $self->SUPER::_remove_from_loop($loop);
}

sub send_request {
  my ( $self, $method, $params, %options ) = @_;

  if ($self->{closed}) {
    return Future->fail($self->{exit_message} // "MCP server process has exited");
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

  # The loop holds the timer until it fires, and the request holds it to stop
  # it the moment the request is settled any other way - answered, failed by
  # the exit, cancelled - so a finished request leaves no timer behind. The
  # timer holds the transport weakly, for the same reason as on_cancel above.
  my $timeout = $self->{timeout};
  if (defined $timeout) {
    my $timer = $self->loop->delay_future(after => $timeout)->on_done(sub {
      my $self = $weak_self or return;
      $self->_time_out($id, $method, $timeout);
    });
    $future->on_ready(sub { $timer->cancel unless $timer->is_ready });
  }

  return $future;
}

# Private: a request whose timeout ran out before its answer arrived. Cancelled
# the way a caller's ->cancel cancels it - the entry dropped, so a late answer
# lands on nothing, and the server told unless it is already going - but
# failed rather than cancelled, so the caller learns why.
sub _time_out {
  my ( $self, $id, $method, $timeout ) = @_;
  my $future = delete $self->{pending}{$id} or return;
  $self->send_notification('notifications/cancelled', {
    requestId => $id,
    reason    => 'timed out after '.$timeout.'s',
  }) unless $self->{closed};
  $future->fail('MCP stdio request '.$method.' timed out after '.$timeout.'s', 'timeout');
  return;
}


sub send_notification {
  my ( $self, $method, $params ) = @_;

  if ($self->{closed}) {
    return Future->fail($self->{exit_message} // "MCP server process has exited");
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


# Private: how long close waits for the subprocess after closing its stdin
# before sending SIGTERM, and again after that before SIGKILL.
my $CLOSE_GRACE = 2;

sub close {
  my ( $self ) = @_;
  return $self->{close_future} // Future->done if $self->{closed};

  $self->{closed} = 1;

  if ($self->{process} && $self->{process}->is_running) {
    my $future = $self->loop->new_future;
    $self->{close_future} = $future;

    # The order the MCP stdio binding gives: close the server's stdin, which
    # is how a server learns that its client is done, and only signal one that
    # is still there after a grace period - first SIGTERM, then SIGKILL.
    # Held on the transport, and cancelled by _on_finish, so the signals are
    # never sent to a process that already exited on its own.
    weaken( my $weak_self = $self );
    $self->{process}->stdin->close_when_empty;
    $self->{close_escalation} = $self->loop->delay_future(after => $CLOSE_GRACE)
      ->then(sub {
        my $self = $weak_self or return Future->done;
        $self->_signal('TERM');
        return $self->loop->delay_future(after => $CLOSE_GRACE);
      })
      ->then(sub {
        my $self = $weak_self or return Future->done;
        $self->_signal('KILL');
        return Future->done;
      });

    return $future;
  }

  return Future->done;
}

# Private: a signal to the subprocess, if it is still there to receive one.
sub _signal {
  my ( $self, $signal ) = @_;
  my $process = $self->{process};
  $process->kill($signal) if $process && $process->is_running;
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
    # which on_request may answer. It has to be recognised before the lookup
    # below rather than after it: the server numbers its own requests, nothing
    # keeps those numbers apart from ours, and a collision would otherwise
    # answer a live request of ours with nothing.
    unless (exists $response->{result} || exists $response->{error}) {
      $self->_on_server_request($response) if defined $response->{method};
      next;
    }

    my $future = delete $self->{pending}{$id};
    next unless $future;

    $self->_settle_response($future, $response);
  }
}

# Private: the class that reads the error of a response, named once.
sub _jsonrpc_class { 'Net::Async::MCP::JSONRPC' }

# Private: the answer to a request of ours, read without trusting its shape -
# the subprocess is whatever the host was told to run. Every branch settles
# the future, which has already left the pending table: one that died here
# would take the loop down and leave the request waiting forever.
sub _settle_response {
  my ( $self, $future, $response ) = @_;

  # The raw JSON-RPC error object travels with the message as the details of
  # a failure in category "mcp", so a caller can read the code and any
  # error->{data} the server sent instead of parsing the message for them. An
  # error in any other shape - a string, a number, false - still says the
  # request failed, with the text it carries and no category.
  if (defined(my $err = $response->{error})) {
    my @failure = $self->_jsonrpc_class->error_failure($response);
    return $future->fail(@failure) if @failure;
    return $future->fail('MCP stdio error response: '.$self->_jsonrpc_class->error_text($err));
  }

  # "error": null sits next to every result in JSON-RPC 1.0 and says nothing
  # there. Without a result it answers nothing, and an undef handed out as the
  # result would be a success the server never reported.
  return $future->done($response->{result}) if exists $response->{result};
  return $future->fail('MCP stdio invalid response: a null error and no result');
}

# Private: a request the server sent, answered with whatever on_request
# returns, if anything.
sub _on_server_request {
  my ( $self, $request ) = @_;
  return unless $self->can_event('on_request');

  my $answer = $self->invoke_event(on_request => $request);
  return unless ref $answer eq 'HASH'
    && ( exists $answer->{result} || exists $answer->{error} );
  return if $self->{closed};

  my $response = {
    jsonrpc => '2.0',
    id      => $request->{id},
    exists $answer->{error}
      ? ( error  => $answer->{error} )
      : ( result => $answer->{result} ),
  };
  $self->{process}->stdin->write($self->{json}->encode($response) . "\n");
  return;
}

# Private: the server's stderr, split into lines for on_stderr and the tail.
sub _on_stderr_read {
  my ( $self, $buffref, $eof ) = @_;
  $self->{stderr_buffer} .= $$buffref;
  $$buffref = '';

  my @lines;
  while ($self->{stderr_buffer} =~ s/^(.*?)\n//) {
    push @lines, $1;
  }
  # The last line of a server that exits without a final newline is a line
  # all the same, and often the one that says why it exited.
  push @lines, delete $self->{stderr_buffer}
    if $eof && length $self->{stderr_buffer};
  $self->{stderr_buffer} //= '';

  for my $line (@lines) {
    $line =~ s/\r\z//;
    $line = decode('UTF-8', $line);

    if ($line =~ /\S/) {
      my $tail = $self->{stderr_tail};
      push @$tail, $line;
      shift @$tail while @$tail > $STDERR_TAIL_LINES;
    }

    $self->maybe_invoke_event(on_stderr => $line);
  }
}

sub stderr_tail { @{ $_[0]->{stderr_tail} } }


sub _on_finish {
  my ( $self, $exitcode, $reason ) = @_;
  $self->{closed} = 1;

  if (my $escalation = delete $self->{close_escalation}) {
    $escalation->cancel;
  }

  my $message = $self->{exit_message} = $self->_exit_message($exitcode, $reason);
  for my $id (keys %{$self->{pending}}) {
    my $future = delete $self->{pending}{$id};
    $future->fail($message)
      if $future && !$future->is_ready;
  }

  if ($self->{close_future} && !$self->{close_future}->is_ready) {
    $self->{close_future}->done;
  }
}

# Private: why the subprocess can no longer answer, on one line: the reason it
# never ran, or its exit status, followed by what it last wrote to stderr.
sub _exit_message {
  my ( $self, $exitcode, $reason ) = @_;

  my $message = $reason // 'MCP server process exited ('
    . ( $exitcode & 127 ? 'signal ' . ( $exitcode & 127 ) : 'code ' . ( $exitcode >> 8 ) )
    . ')';

  my @tail = $self->stderr_tail;
  $message .= '; stderr: ' . join(' | ', @tail) if @tail;
  return $message;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Async::MCP::Transport::Stdio - Stdio MCP transport via subprocess JSON-RPC

=head1 VERSION

version 0.007

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

=head2 env

    my $transport = Net::Async::MCP::Transport::Stdio->new(
        command => [ 'npx', '-y', '@modelcontextprotocol/server-github' ],
        env     => { GITHUB_TOKEN => $token, NODE_OPTIONS => undef },
    );

Optional. A HashRef laid over this process's C<%ENV> for the subprocess: a key
with a value sets that variable, a key whose value is C<undef> removes it.
Everything else in C<%ENV> is inherited as it stands. Without it the subprocess
inherits C<%ENV> unchanged.

=head2 cwd

Optional. The working directory the subprocess starts in. Without it the
subprocess inherits this process's current directory. A directory that does
not exist fails the start the same way a command that cannot be executed does
- see L</send_request>.

Both C<env> and C<cwd> describe the process as it is started, which happens
when the transport is added to a loop; configuring either afterwards changes
nothing for a process that is already running.

=head2 timeout

    my $transport = Net::Async::MCP::Transport::Stdio->new(
        command => [ 'my-mcp-server' ],
        timeout => 120,
    );

Optional. The limit in seconds on how long a request waits for its answer.
Unset by default, and then a request waits for as long as the subprocess
lives: an MCP C<tools/call> may legitimately run for minutes, and only a
caller that knows its own upper bound can pick one. A request still
unanswered when the limit runs out is cancelled - its pending entry dropped
and C<notifications/cancelled> written to the subprocess, as
L</send_request> describes for a cancel - and its L<Future> fails with
C<MCP stdio request METHOD timed out after Ns> in category C<timeout>, the
category L<Net::Async::HTTP> gives a timed out HTTP request.

As in the HTTP transport, C<0> is a limit of zero seconds rather than "no
limit": leave it undef to have none. The limit applies to every request sent
after it is set, and each request keeps the one it was sent with.

=head2 on_stderr

    my $transport = Net::Async::MCP::Transport::Stdio->new(
        command   => [ 'my-mcp-server' ],
        on_stderr => sub {
            my ( $transport, $line ) = @_;
            warn "mcp: $line\n";
        },
    );

Invoked once for every line the subprocess writes to its stderr, with the line
decoded from UTF-8 and without its line ending. The MCP stdio binding leaves
stderr to the server for free-form logging, so nothing here treats a line as
an error. Without a handler the lines are still read - a server whose stderr
nobody drains stalls once the pipe is full - and dropped.

Either way the last 20 non-empty lines are kept, see L</stderr_tail>, and
quoted in the failure of every request the subprocess leaves unanswered when
it exits, because that is usually where it said why.

=head2 on_request

Invoked for every request the server sends to the client - a line with an
C<id> and a C<method> but neither a C<result> nor an C<error> - with the
decoded JSON-RPC request. A handler that returns a HashRef holding a C<result>
or an C<error> has it written back as the response to that request; anything
else leaves the request unanswered. Without a handler every such request is
dropped.

L<Net::Async::MCP> sets this to a handler of its own: a server of a
handshake-based revision may ask its client for a C<ping>, and the client
answers it there. What to answer is the protocol's to decide, and writing the
answer is this transport's.

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
request, which goes to L</on_request> and is dropped where that does not
answer it.

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
behind it. The one exception is a request that ran out of L</timeout>, which
fails in category C<timeout>.

An C<error> that is no JSON-RPC error object - a string, a number, an array, a
hash without a C<code> - still fails the request, with
C<MCP stdio error response: TEXT> carrying the value or its JSON, and no
category, since there is no error object to hand over. A C<"error": null> next
to a C<result> is a success, as JSON-RPC 1.0 wrote it; without one it fails
with C<MCP stdio invalid response: a null error and no result>. A server
answering in a shape it should not never leaves the request waiting.

Fails immediately if the subprocess has already exited. A request still
pending when it exits fails with C<MCP server process exited (code N)> - or
C<(signal N)> - followed by the last lines the subprocess wrote to its stderr,
joined with C< | >, where it wrote any. A subprocess that never ran - a
command that cannot be executed, a L</cwd> that does not exist - fails every
request with C<MCP server failed to start: cannot run PROGRAM: REASON>
instead, rather than leaving it to wait for an answer that cannot come.

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

A request that runs into L</timeout> is cancelled the same way, with a
C<reason> saying so, and its L<Future> fails in category C<timeout> rather
than being cancelled.

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

Shuts the subprocess down in the order the MCP stdio binding gives, and
returns a L<Future> that resolves when it has exited: its stdin is closed
first, which a server reads as its client being done; if it is still running
2 seconds later it is sent SIGTERM, and 2 seconds after that SIGKILL. A server
that exits on the end of its input - as servers are expected to - is therefore
never signalled at all. If the process has already exited, returns an
immediately resolved L<Future>; calling it again while the shutdown is still
under way returns the same L<Future> as the first call.

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

=head2 stderr_tail

    my @lines = $transport->stderr_tail;

The last 20 non-empty lines the subprocess wrote to its stderr, oldest first,
decoded from UTF-8 and without their line endings. Kept whether or not an
L</on_stderr> handler is set, and still there after the subprocess has exited,
which is when they are usually wanted.

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
