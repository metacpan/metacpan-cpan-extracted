package Net::Async::MCP::Transport::HTTP;
# ABSTRACT: Streamable HTTP MCP transport via Net::Async::HTTP
use strict;
use warnings;
use parent 'IO::Async::Notifier';

use Future;
use JSON::MaybeXS;
use Carp qw( croak );
use Encode qw( encode is_utf8 );
use MIME::Base64 qw( encode_base64 );
use Scalar::Util qw( blessed weaken );


# The methods whose name-ish parameter is mirrored into Mcp-Name, and the
# parameter it is taken from. Same table as MCP::Client and MCP::Server's HTTP
# transport, which compares the header against exactly this field of the body.
my %NAME_PARAM = (
  'prompts/get'    => 'name',
  'resources/read' => 'uri',
  'tools/call'     => 'name',
);

my $DEFAULT_STALL_TIMEOUT = 60;

# Where a subscription's acknowledgement carries the id every later message on
# that stream is tagged with, and the only handle there is on a running
# subscription. Written out for the same reason the protocol version key above
# is: it is a name on the wire, not something a locally installed L<MCP> has
# any say in.
my $SUBSCRIPTION_ID_META = 'io.modelcontextprotocol/subscriptionId';

sub _init {
  my ( $self, $params ) = @_;
  $self->{url} = delete $params->{url}
    or croak "url is required";
  # exists, not defined: an explicit undef is a caller switching a timeout off,
  # and has to survive the default applied below.
  for my $key (qw( headers timeout stall_timeout )) {
    $self->{$key} = delete $params->{$key} if exists $params->{$key};
  }
  $self->{stall_timeout} = $DEFAULT_STALL_TIMEOUT
    unless exists $self->{stall_timeout};
  $self->{next_id} = 0;
  $self->{json}    = JSON::MaybeXS->new(utf8 => 1, convert_blessed => 1);

  # Every request that has not finished, by JSON-RPC id: the Future the caller
  # holds, the exchange it is being answered over, and the subscription it
  # opened where it opened one. Both halves are needed here rather than only
  # the one the caller sees, because leaving the loop has to settle the Future
  # and close the stream, and neither can be reached from the other.
  $self->{pending} = {};

  # Subscription id to the request id of the exchange carrying it, which is
  # what turns the one handle a caller has on a running subscription into the
  # stream to close.
  $self->{subscriptions} = {};

  $self->SUPER::_init($params);
}

sub configure {
  my ( $self, %params ) = @_;
  if (exists $params{url}) {
    $self->{url} = delete $params{url};
  }
  $self->{headers} = delete $params{headers} if exists $params{headers};
  $self->{on_notification} = delete $params{on_notification}
    if exists $params{on_notification};
  $self->{on_subscription_end} = delete $params{on_subscription_end}
    if exists $params{on_subscription_end};
  for my $key (qw( timeout stall_timeout )) {
    next unless exists $params{$key};
    $self->{$key} = delete $params{$key};
    # Only once this transport has joined a loop is there an HTTP client to
    # reconfigure; before that _add_to_loop picks the values up itself.
    $self->{http}->configure($key => $self->{$key}) if $self->{http};
  }
  $self->SUPER::configure(%params);
}

sub _add_to_loop {
  my ( $self, $loop ) = @_;
  $self->SUPER::_add_to_loop($loop);

  require Net::Async::HTTP;

  my $http = Net::Async::HTTP->new(
    max_connections_per_host => 0,
    timeout                  => $self->{timeout},
    stall_timeout            => $self->{stall_timeout},
  );
  $self->{http} = $http;
  $self->add_child($http);
}

sub _remove_from_loop {
  my ( $self, $loop ) = @_;

  # Leaving the loop takes the HTTP client along, it being a child of this
  # transport, and with it every connection an answer could still arrive over.
  # So nothing still open can ever be settled from outside again, and it has to
  # be settled here or it stays pending for the rest of the program - the same
  # lesson as L<Net::Async::MCP::Transport::Stdio>'s own _remove_from_loop.
  #
  # The caller's Future is failed rather than completed: nothing here saw a
  # response go missing, what it knows is that none can reach it any more. Its
  # exchange is cancelled afterwards, which closes the stream; doing it the
  # other way round would settle the Future as cancelled and lose the reason
  # with it.
  for my $id (keys %{ $self->{pending} }) {
    my $pending = delete $self->{pending}{$id} or next;

    delete $self->{subscriptions}{ $pending->{subscription} }
      if defined $pending->{subscription};

    my $outcome = $pending->{outcome};
    $outcome->fail("MCP HTTP transport left the loop before the request was answered")
      if $outcome && !$outcome->is_ready;

    my $exchange = $pending->{exchange};
    $exchange->cancel if $exchange && !$exchange->is_ready;
  }

  $self->SUPER::_remove_from_loop($loop);
}

# The Future a caller is handed. An IO::Async::Future wherever there is a loop
# to take one from, which is every transport that has an HTTP client to send
# with: only the plain Future knows no ->await, and a caller's ->get on one
# that is not ready yet dies instead of running the loop until it is.
sub _new_future {
  my ( $self ) = @_;
  my $loop = $self->loop or return Future->new;
  return $loop->new_future;
}


sub send_request {
  my ( $self, $method, $params, %options ) = @_;

  my $id = ++$self->{next_id};
  my $request = {
    jsonrpc => '2.0',
    id      => $id,
    method  => $method,
    defined $params ? ( params => $params ) : (),
  };

  my $body = $self->{json}->encode($request);

  require HTTP::Request;
  my $http_req = HTTP::Request->new(
    POST => $self->{url},
    [ $self->_standard_headers($method, $params, %options) ],
    $body,
  );

  # The Future the caller holds, and deliberately not the one the exchange
  # below ends in. What answers a request is its message, and the end of the
  # body that message arrived in is a different moment: a server is free to
  # hold an event stream open after its response, and for a subscription it
  # always does - that request is answered by a notification and the stream
  # then runs for as long as the subscription does. Waiting for the body to
  # end would mean waiting for the stall timeout in the first case and forever
  # in the second.
  my $outcome = $self->_new_future;
  my $pending = $self->{pending}{$id} = { outcome => $outcome };

  my $exchange = $self->{http}->do_request(
    request   => $http_req,
    on_header => sub { $self->_response_reader($outcome, $id, \%options, @_) },
  )->then(sub {
    my ( $result ) = @_;

    # Both body readers end in the Future for the JSON-RPC outcome, and
    # Net::Async::HTTP passes whatever they return through as the result of
    # its own. A response object instead means the body never reached them:
    # a redirect, which it consumes itself rather than handing over - it does
    # not follow one for a POST, so this is where a redirected endpoint ends
    # up, and the status line is all there is to report.
    return $result if blessed($result) && $result->isa('Future');
    return $self->_handle_response($result);
  });

  # Held on the transport because the caller no longer holds it: a Future
  # nothing refers to is collected mid-flight, and this one is the request.
  $pending->{exchange} = $exchange;

  # These callbacks live on the two Futures the pending entry holds, so
  # capturing the transport strongly would close a cycle no refcount breaks.
  # It is never undef where it matters: a transport with a request in flight is
  # in a loop, and the loop holds it.
  weaken( my $weak_self = $self );

  # Cancelling the answer cancels the request, which over Streamable HTTP
  # means closing the stream it would have been answered on - there is no
  # notifications/cancelled in this binding. Reached through the pending table
  # rather than by capturing the exchange, which would be the other half of
  # the same cycle.
  $outcome->on_cancel(sub {
    my $self = $weak_self or return;
    my $exchange = ( $self->{pending}{$id} // {} )->{exchange} or return;
    $exchange->cancel unless $exchange->is_ready;
  });

  $exchange->on_ready(sub {
    my ( $finished ) = @_;

    if ( my $self = $weak_self ) {
      my $ended = delete $self->{pending}{$id};

      # Whether the subscription is still registered tells who ended it:
      # stop_subscription and close take the entry out before they close the
      # stream, so an end that came from the server's side - a stream the
      # server closed, a connection that failed - reaches here with the entry
      # standing, and that is the end on_subscription_end reports. An end this
      # client caused itself has nobody waiting to be told.
      if ($ended && defined $ended->{subscription}
        && delete $self->{subscriptions}{ $ended->{subscription} }) {
        $self->maybe_invoke_event(on_subscription_end => $ended->{subscription});
      }
    }

    # An exchange that ends after the caller was answered has nothing left to
    # tell it. This is every subscription: it was settled by its
    # acknowledgement, and the stream ending afterwards - closed by
    # L</stop_subscription>, by the server, or by the connection failing - is
    # reported through L</on_subscription_end> above rather than through this
    # Future, which was settled long before.
    return if $outcome->is_ready;

    # Otherwise the exchange is where the answer comes from: an HTTP error, a
    # body that could not be read, a stream that ended without saying
    # anything, or a plain JSON response that was only complete at the end.
    return $outcome->cancel if $finished->is_cancelled;
    return $outcome->fail($finished->failure) if $finished->is_failed;
    return $outcome->done($finished->get);
  });

  return $outcome;
}



sub send_notification {
  my ( $self, $method, $params ) = @_;

  my $request = {
    jsonrpc => '2.0',
    method  => $method,
    defined $params ? ( params => $params ) : (),
  };

  my $body = $self->{json}->encode($request);

  require HTTP::Request;
  my $http_req = HTTP::Request->new(
    POST => $self->{url},
    [ $self->_standard_headers($method, $params) ],
    $body,
  );

  return $self->{http}->do_request(request => $http_req)->then(sub {
    my ( $response ) = @_;
    return $self->_handle_notification_response($response);
  });
}


sub close {
  my ( $self ) = @_;
  $self->stop_subscription($_) for keys %{ $self->{subscriptions} };
  return Future->done;
}


sub stop_subscription {
  my ( $self, $subscription_id ) = @_;

  return 0 unless defined $subscription_id;
  my $id = delete $self->{subscriptions}{$subscription_id};
  return 0 unless defined $id;

  $self->_close_stream($id);
  return 1;
}


sub is_alive { 1 }


sub mirrors_header_params { 1 }



# Net::Async::HTTP hands the response header over as soon as it has it and
# takes the callback for the body in return, so this is where the content type
# decides how the body is read: an event stream carries notifications the
# server sends before its response and has to be read as it arrives, while
# every other body says nothing until it is complete and is judged whole.
sub _response_reader {
  my ( $self, $outcome, $id, $options, $header ) = @_;

  return $self->_sse_reader($outcome, $id, $options)
    if $header->is_success
    && ($header->content_type // '') =~ m{^text/event-stream}i;

  return sub {
    return $header->add_content(@_) if @_;
    return $self->_handle_response($header);
  };
}

# Reads an SSE body as it arrives. Returns the callback Net::Async::HTTP feeds
# the body to: once per chunk of bytes as it lands, and once with no arguments
# at the end of the stream, where whatever it returns becomes the result of the
# request's Future - here the Future the JSON-RPC outcome is reported through.
#
# A chunk ends wherever the network put it, mid-line and mid-character
# included, so nothing leaves the buffer before its newline has arrived and
# nothing is decoded before its event is complete.
sub _sse_reader {
  my ( $self, $outcome, $id, $options ) = @_;

  # A reader driven directly rather than from send_request answers nobody, but
  # still has to have something to settle: _handle_sse_response reads a whole
  # body through here and hands back what this ends up with.
  $outcome //= $self->_new_future;

  # What the client said settles this request in place of a response. Named by
  # the client and not worked out here: which method that is is MCP semantics,
  # and a transport reading the request's own method and deciding for itself
  # would be guessing where it was told.
  my $resolve_on = ( $options // {} )->{resolve_on_notification};

  my $buffer = '';
  my @data;

  # One line of the stream, its newline already taken off. A blank line ends
  # an event, a line opening with a colon is a comment - the shape of the
  # keep-alives a server sends to hold an idle stream open - and every other
  # line is a field, of which this client reads only "data".
  my $line = sub {
    my ( $text ) = @_;

    $text =~ s/\r\z//;

    if (length $text) {
      return if $text =~ /^:/;
      my ( $field, $value ) = split /:/, $text, 2;
      return unless defined $field && $field eq 'data';
      $value = '' unless defined $value;
      $value =~ s/^ //;
      push @data, $value;
      return;
    }

    my $event = join "\n", @data;
    @data = ();
    return unless length $event;

    # Not every event is JSON-RPC this client can use, and one that is not is
    # no reason to abandon a stream that still owes it a response.
    my $decoded = eval { $self->{json}->decode($event) };
    return unless ref $decoded eq 'HASH';

    # An event that answers no request is a notification - unless it is the
    # one the client named as this request's answer, which is how a
    # subscription is acknowledged: it settles the request rather than being
    # delivered as an event of its own, since it is what the caller asked for
    # and not something that happened while it waited.
    unless (exists $decoded->{id}) {
      return $self->_open_subscription($outcome, $id, $decoded)
        if defined $resolve_on
        && !$outcome->is_ready
        && ( $decoded->{method} // '' ) eq $resolve_on;

      return $self->maybe_invoke_event(on_notification => $decoded);
    }

    # An event that does answer settles the request the moment it lands rather
    # than at the end of the body: a stream holds the answer to exactly one
    # request, so the first one is kept and what comes after cannot make an
    # earlier answer untrue. An id without a result or an error is a
    # server-initiated request, which this client does not answer, so it is
    # dropped.
    $self->_settle_response($outcome, $decoded)
      if !$outcome->is_ready
      && (exists $decoded->{result} || exists $decoded->{error});

    return;
  };

  return sub {
    unless (@_) {
      # The end of the stream terminates whatever it interrupted: a server
      # that closed right behind its last data line still said it.
      $line->($buffer) if length $buffer;
      $buffer = '';
      $line->('');
      return $self->_sse_result($outcome, $resolve_on);
    }

    my ( $chunk ) = @_;
    return unless defined $chunk;

    # The JSON decoder has utf8 => 1 and wants bytes, which is what
    # Net::Async::HTTP hands over. Characters would be decoded a second time
    # and every non-ASCII event lost to the failed decode above.
    $chunk = encode('UTF-8', $chunk) if is_utf8($chunk);

    $buffer .= $chunk;
    $line->($1) while $buffer =~ s/^([^\n]*)\n//;

    return;
  };
}

# The answer an event carrying one settles the request with, taken as it lands
# rather than held until the stream ends.
sub _settle_response {
  my ( $self, $outcome, $data ) = @_;

  if (defined(my $err = $data->{error})) {
    my @failure = $self->_jsonrpc_error_failure($data);
    return $outcome->fail(@failure) if @failure;
    return $outcome->fail($self->_foreign_error_message($err));
  }

  return $outcome->done($data->{result});
}

# The acknowledgement of a subscription, which is the answer to the request
# that opened it: its params are what the caller is handed - the subscription
# id and the notification types the server honoured - and the id is what the
# stream is filed under, since closing that stream is the only way to end the
# subscription again.
sub _open_subscription {
  my ( $self, $outcome, $id, $acknowledgement ) = @_;

  my $params = ref $acknowledgement->{params} eq 'HASH' ? $acknowledgement->{params} : {};
  my $meta   = ref $params->{_meta} eq 'HASH' ? $params->{_meta} : {};
  my $subscription_id = $meta->{$SUBSCRIPTION_ID_META};

  # A subscription with no id is one nothing can address: it cannot be stopped
  # and a close cannot reach it either, so handing it to a caller would be
  # handing over a stream with no way of ending it. The stream goes with the
  # refusal, which is what ends it on this side.
  unless (defined $subscription_id && length $subscription_id) {
    $outcome->fail("MCP HTTP subscription acknowledged without a subscription id");
    $self->_close_stream($id);
    return;
  }

  $self->{subscriptions}{$subscription_id} = $id;
  $self->{pending}{$id}{subscription} = $subscription_id if $self->{pending}{$id};

  return $outcome->done($params);
}

# Closing the stream a request is running on, which is what both cancelling a
# request and unsubscribing come down to over this binding: Net::Async::HTTP
# closes the connection when its request Future is cancelled.
sub _close_stream {
  my ( $self, $id ) = @_;

  return 0 unless defined $id;
  my $exchange = ( $self->{pending}{$id} // {} )->{exchange} or return 0;
  return 0 if $exchange->is_ready;

  $exchange->cancel;
  return 1;
}

# What a finished SSE stream leaves the exchange with. The answer it carried is
# already the caller's, so handing the same Future back keeps the exchange
# resolving with exactly what the request resolved with; only a stream that
# said nothing has anything of its own to report.
sub _sse_result {
  my ( $self, $outcome, $resolve_on ) = @_;

  return $outcome if $outcome->is_ready;

  # A subscription is never answered with a response, so reporting a missing
  # one would send a caller looking for something the server was never going
  # to send.
  return Future->fail("MCP HTTP stream ended before the subscription was acknowledged")
    if defined $resolve_on;

  return Future->fail("MCP HTTP no JSON-RPC response in SSE stream");
}

# The metadata headers every POST carries. They are read back out of the body
# instead of out of transport state so that the two cannot drift apart: the
# server compares header against body and answers -32020 when they differ.
sub _standard_headers {
  my ( $self, $method, $params, %options ) = @_;

  $params = {} unless ref $params eq 'HASH';

  my @headers = (
    'Content-Type' => 'application/json',
    'Accept'       => 'application/json, text/event-stream',
  );

  # Absent for a request built without _meta, and for a notification sent
  # through send_notification with no params at all - this client sends none
  # itself, but the method stays open to callers. Sending a made up version
  # would be worse than sending none: the server only compares what it gets.
  my $version = ($params->{_meta} // {})->{'io.modelcontextprotocol/protocolVersion'};
  push @headers, 'MCP-Protocol-Version' => $version if defined $version;

  push @headers, 'Mcp-Method' => $method;

  if (my $key = $NAME_PARAM{$method}) {
    push @headers, 'Mcp-Name' => $self->_encode_header($params->{$key} // '');
  }

  # Tool arguments annotated with x-mcp-header, already resolved and formatted
  # by the client: which arguments these are and what they look like is MCP
  # semantics, only the wire form is this transport's business. They travel
  # through the same sentinel encoding as Mcp-Name, which is what the server
  # undoes before comparing.
  for my $param (@{ $options{header_params} // [] }) {
    push @headers,
      "Mcp-Param-$param->{name}" => $self->_encode_header($param->{value} // '');
  }

  # The caller's own headers go first and the derived ones after, so an
  # Authorization can be added while an Mcp-Method cannot be taken over.
  return ( $self->_caller_headers(@headers), @headers );
}

# The headers configured on this transport, minus every field the request
# derives from its body. Dropping them is not the same as ordering them:
# HTTP::Headers keeps a field given twice in one list as two values of one
# header rather than letting the later win, so a colliding caller header would
# travel alongside the derived one and diverge from the body just as visibly.
sub _caller_headers {
  my ( $self, @derived ) = @_;

  my $headers = $self->{headers};
  return () unless ref $headers eq 'HASH';

  my %derived;
  for (my $i = 0; $i < @derived; $i += 2) {
    $derived{ lc $derived[$i] } = 1;
  }

  return map  { $_ => $headers->{$_} }
         grep { !$derived{ lc $_ } }
         sort keys %$headers;
}

# A header value that is not printable ASCII travels base64 encoded in a
# sentinel, as does one that already looks like the sentinel itself, which
# would otherwise be decoded by the server into something the body never said.
sub _encode_header {
  my ( $self, $value ) = @_;

  return $value
    if $value =~ /^[\x20-\x7e]*\z/ && $value !~ /^=\?base64\?.*\?=$/;

  return '=?base64?' . encode_base64(encode('UTF-8', $value), '') . '?=';
}

sub _handle_response {
  my ( $self, $response ) = @_;

  my $status = $response->code;

  unless ($response->is_success) {
    # An MCP server renders JSON-RPC errors with a non-2xx status taken from
    # the request context (400 for a rejected _meta, 403 for insufficient
    # scope, 404 for METHOD_NOT_FOUND), so the body carries the real error and
    # must win over the HTTP status. Only a non-2xx without a JSON-RPC error
    # body is an HTTP-level problem.
    if (my @failure = $self->_jsonrpc_error_from_body($response)) {
      return Future->fail(@failure);
    }

    return Future->fail("MCP HTTP error: " . $response->status_line);
  }

  my $content_type = $response->content_type // '';

  # charset => 'none' undoes Content-Encoding but leaves the body as UTF-8
  # bytes, which is what the JSON decoder below expects; letting
  # decoded_content apply the charset too would decode text/event-stream twice.
  if ($content_type =~ m{^application/json}i) {
    return $self->_handle_json_response($response->decoded_content(charset => 'none'));
  }
  elsif ($content_type =~ m{^text/event-stream}i) {
    return $self->_handle_sse_response($response->decoded_content(charset => 'none'));
  }

  # 202 Accepted with no body (for notifications/responses)
  if ($status == 202) {
    return Future->done(undef);
  }

  return Future->fail("MCP HTTP unexpected content-type: $content_type");
}

# A notification is answered with a status and nothing this client reads, so
# the status is all there is to judge - 202 Accepted with an empty body is the
# normal case. Deliberately not routed through _handle_response, which would
# fail exactly that empty body as invalid JSON.
sub _handle_notification_response {
  my ( $self, $response ) = @_;

  return Future->done if $response->is_success;

  if (my @failure = $self->_jsonrpc_error_from_body($response)) {
    return Future->fail(@failure);
  }

  return Future->fail("MCP HTTP error: " . $response->status_line);
}

sub _jsonrpc_error_from_body {
  my ( $self, $response ) = @_;

  my $body = eval { $response->decoded_content(charset => 'none') };
  return () unless defined $body && length $body;

  my $data = eval { $self->{json}->decode($body) };
  return $self->_jsonrpc_error_failure($data);
}

# The Future->fail arguments for a decoded body that carries a JSON-RPC error
# object, and the empty list for anything else. Not every JSON error body is a
# JSON-RPC one: an MCP server answers a bad method with
# {error => 'Method not allowed'}, and a gateway in between may invent its own
# shape, so the shape is checked before it is read as an object.
#
# The message alone cannot carry a code to switch on or an error->{data} to
# read, so the raw error object travels with it as the details of a failure in
# category "mcp". The message stays the first element, so a caller reading the
# failure in scalar context sees exactly what it saw before.
sub _jsonrpc_error_failure {
  my ( $self, $data ) = @_;

  return () unless ref $data eq 'HASH';

  my $err = $data->{error};
  return () unless ref $err eq 'HASH' && defined $err->{code};

  return (
    "MCP error $err->{code}: " . ($err->{message} // '(no message)'),
    mcp => $err,
  );
}

# A body that says "error" in a shape this client cannot read as JSON-RPC still
# says the request failed. Report it as a failure carrying whatever text it
# holds rather than reaching into it as if it were an object.
sub _foreign_error_message {
  my ( $self, $err ) = @_;

  my $text = ref $err ? eval { $self->{json}->encode($err) } // 'unknown error' : $err;
  return "MCP HTTP error response: $text";
}

sub _handle_json_response {
  my ( $self, $body ) = @_;

  my $data = eval { $self->{json}->decode($body) };
  return Future->fail("MCP HTTP invalid JSON: $@") if $@;
  return Future->fail("MCP HTTP invalid response") unless ref $data eq 'HASH';

  if (defined(my $err = $data->{error})) {
    my @failure = $self->_jsonrpc_error_failure($data);
    return Future->fail(@failure) if @failure;
    return Future->fail($self->_foreign_error_message($err));
  }

  return Future->done($data->{result});
}

# A whole SSE body in hand rather than a stream to read from, which is the
# same events through the same reader, all at once. Only a caller holding a
# complete response gets here: a streamed one is read by _sse_reader itself.
sub _handle_sse_response {
  my ( $self, $body ) = @_;

  my $read = $self->_sse_reader;
  $read->($body);
  return $read->();
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Async::MCP::Transport::HTTP - Streamable HTTP MCP transport via Net::Async::HTTP

=head1 VERSION

version 0.004

=head1 SYNOPSIS

    # Usually created automatically by Net::Async::MCP
    use IO::Async::Loop;
    use Net::Async::MCP;

    my $loop = IO::Async::Loop->new;
    my $mcp = Net::Async::MCP->new(
        url => 'https://example.com/mcp',
    );
    $loop->add($mcp);

=head1 DESCRIPTION

L<Net::Async::MCP::Transport::HTTP> communicates with a remote MCP server
over HTTP using the Streamable HTTP transport defined in the MCP specification
(2026-07-28). Requests are sent as HTTP POST with JSON-RPC bodies, and
responses may arrive as either C<application/json> or C<text/event-stream>
(Server-Sent Events).

There is no session to manage. The current revision is stateless: it dropped
protocol sessions and the C<Mcp-Session-Id> header entirely, and every request
describes itself through its own C<_meta>. A conforming server must ignore that
header and never mint or echo a session ID, so this transport neither sends nor
reads one.

The revision mirrors a request's metadata into HTTP headers so that
intermediaries can route on it without parsing the body:
C<MCP-Protocol-Version>, C<Mcp-Method>, and for the three methods with a
name-ish parameter (C<tools/call>, C<prompts/get>, C<resources/read>) also
C<Mcp-Name>. The body stays the truth; this transport derives the headers from
it rather than from any state of its own, because a conforming server compares
the two and rejects a missing or diverging header with C<-32020>
(C<HEADER_MISMATCH>).

The same holds for tool arguments annotated with C<x-mcp-header> in a tool's
input schema, which travel as C<Mcp-Param-{Name}> alongside a C<tools/call>.
This transport does not go looking for them: which arguments are annotated
follows from the tool's schema, so L<Net::Async::MCP/call_tool> resolves them
and hands the finished name/value pairs to L</send_request>, which encodes them
like any other header. A server rejects a C<tools/call> that passes an
annotated argument without its header just as it rejects a header for an
argument the call did not pass.

A response is read off the stream it arrives on rather than waited for at the
end of it, which is what lets a subscription work at all: that request is
answered by a notification and its stream then runs for as long as the
subscription does. See L</Subscriptions>.

This transport is selected automatically by L<Net::Async::MCP> when constructed
with a C<url> argument.

=head2 new

    my $transport = Net::Async::MCP::Transport::HTTP->new(
        url     => 'https://example.com/mcp',
        headers => { Authorization => "Bearer $token" },
    );

Constructs a new HTTP transport. C<url> is required and names the MCP endpoint
every request is POSTed to. Usually not called directly: L<Net::Async::MCP>
builds this transport itself and passes the same arguments through, so a caller
configures them there.

C<headers> is a HashRef of headers added to every POST - the place for
everything the protocol does not describe, an C<Authorization: Bearer ...> for
a server behind OAuth above all. They go on the request underneath the headers
this transport derives from the body, so a caller can add its own but cannot
replace C<MCP-Protocol-Version>, C<Mcp-Method>, C<Mcp-Name> or an
C<Mcp-Param-{Name}>: a header that disagrees with the body is exactly what a
conforming server answers with C<-32020>. A colliding header is dropped rather
than sent alongside the derived one, which would be the same divergence in
another shape.

C<timeout> and C<stall_timeout> are handed to the underlying
L<Net::Async::HTTP>, in seconds. C<stall_timeout> defaults to 60 and is the
only one with a default: it fires when a request spends that long without a
single byte moving in either direction, which is the hung connection a client
cannot otherwise notice, and it does not touch a request that is still making
progress. C<timeout>, the wall-clock limit on a whole request, deliberately has
no default - an MCP C<tools/call> may legitimately run for minutes, so a
default here would break working setups rather than protect them, and only a
caller that knows its own upper bound can pick one.

Pass C<stall_timeout> as C<0> (or C<undef>) to switch the stall timeout off.
C<timeout> is off unless set, and has to stay C<undef> to stay off: a
C<timeout> of C<0> is a real limit of zero seconds that fails every request
immediately.

=head2 send_request

    my $future = $transport->send_request($method, \%params);
    my $future = $transport->send_request($method, \%params,
        header_params => [ { name => 'Region', value => 'europe-west1' } ]);
    my $future = $transport->send_request('subscriptions/listen', \%params,
        resolve_on_notification => 'notifications/subscriptions/acknowledged');

Sends a JSON-RPC request as an HTTP POST to the MCP endpoint. The request
includes C<Accept: application/json, text/event-stream> to support both
direct JSON responses and SSE streams, plus the metadata headers derived from
the body as described above.

Optional trailing name/value options carry hints the body cannot express.

C<header_params> is an ArrayRef of hashrefs with C<name> and C<value>, one per
tool argument annotated with C<x-mcp-header>, which this transport sends as
C<Mcp-Param-{Name}>. The value arrives formatted the way the server compares it
- L<Net::Async::MCP/call_tool> resolves it from the tool's input schema - and
this transport only encodes it for the wire.

C<resolve_on_notification> names the notification method that answers this
request in place of a response, which is how a C<subscriptions/listen> is
answered and the only request that works this way today. The client says so
rather than this transport working it out from the method it was handed: which
requests are answered by a notification is MCP semantics, and a transport
deciding for itself would be guessing where it can be told. See
L</Subscriptions> for the whole shape.

Returns a L<Future> that resolves to the C<result> value from the JSON-RPC
response. Handles both C<application/json> and C<text/event-stream> response
content types.

An C<application/json> answer is read whole, as there is nothing to read
before it is complete. A C<text/event-stream> is read as it arrives instead,
because a server may send C<notifications/progress> and
C<notifications/message> on the stream of a long running request before the
response it answers with: an event carrying no C<id> is such a notification
and is delivered to L</on_notification> the moment it lands, an event with an
C<id> and a C<result> or C<error> is the response and settles the L<Future>. A
stream that ends without one fails it with C<MCP HTTP no JSON-RPC response in
SSE stream>.

The response settles the L<Future> where it stands in the stream, not where
the stream ends. Nothing obliges a server to close the stream behind its
response, and one that holds it open would otherwise hold the caller until the
stall timeout gave up on a stream with nothing left to say. What the stream
carries afterwards is delivered to L</on_notification> as before, and the end
of it changes nothing about an answer already given.

If the server answers with a non-2xx status, a JSON-RPC error in the body wins
over the status: MCP servers render errors such as C<METHOD_NOT_FOUND> with a
404 and a rejected C<_meta> with a 400, so the future fails with that
C<MCP error $code: $message>. A non-2xx without a JSON-RPC error body fails
with the HTTP status line.

An C<error> member that is not a JSON-RPC error object - a bare string, as
L<MCP::Server>'s own HTTP transport renders its refusals, or whatever shape a
gateway in between invents - fails the L<Future> as well, carrying the text the
body held.

A JSON-RPC error fails the L<Future> with more than its message, wherever in
the body or the stream it was found. L<Future>'s failure convention is
C<< ( $message, $category, @details ) >>, so the failure reads
C<< ( "MCP error $code: $message", 'mcp', $error ) >>: in scalar context
C<< ->failure >> is the message and nothing has changed, and in list context
the raw JSON-RPC error object comes with it.

    my ( $message, $category, $error ) = $future->failure;
    if (($category // '') eq 'mcp') {
      my $code      = $error->{code};          # -32601, -32602, ...
      my $supported = $error->{data}{supported};
    }

The C<mcp> category marks a genuine JSON-RPC error from the server and nothing
else. The failures around it - the HTTP status line, an unreadable or
unexpected body, the foreign C<error> shape above, and a stream that ended
without a response - carry their message alone, so a caller that finds no
category knows there is no server error object behind it.

Cancelling the returned L<Future> cancels the request by closing the stream it
would have been answered on, which is what cancellation is over Streamable
HTTP: this binding defines no C<notifications/cancelled>, so nothing is sent -
see L<Net::Async::MCP::Transport::Stdio/send_request> for the other form.

Removing the transport from its L<IO::Async::Loop> while the request is still
pending fails it with C<MCP HTTP transport left the loop before the request
was answered> and closes its stream. The HTTP client leaves the loop with the
transport that owns it, so no answer can reach this client any more, and a
L<Future> that would wait for one forever is better ended with the reason it
will not arrive.

=head2 Subscriptions

A C<subscriptions/listen> is the one request a server never answers with a
JSON-RPC response. It opens an event stream, writes
C<notifications/subscriptions/acknowledged> as the first message on it, and
then holds the stream open to carry the notifications that were subscribed to
for as long as the subscription lasts. A client waiting for a response waits
for something the specification does not have the server send.

So the request names what does answer it:

    my $params = await $transport->send_request('subscriptions/listen',
        { notifications => { toolsListChanged => 1 } },
        resolve_on_notification => 'notifications/subscriptions/acknowledged');

    my $id = $params->{_meta}{'io.modelcontextprotocol/subscriptionId'};

The L<Future> resolves with the acknowledgement's C<params>: the subscription
id in C<_meta>, and under C<notifications> the types the server actually
honoured, which is not necessarily everything that was asked for. The
acknowledgement is the answer and so is not also delivered to
L</on_notification>; everything the stream carries after it is.

The stream then stays open and this transport holds it, filed under the
subscription id. L</stop_subscription> ends it, and so does L</close> for
every one still running. Two subscriptions run on two streams and are stopped
one at a time.

Three things go wrong loudly rather than quietly:

=over 4

=item *

A stream that ends before the acknowledgement fails the L<Future> with
C<MCP HTTP stream ended before the subscription was acknowledged> rather than
with the missing-response message, which would name a message the server was
never going to send.

=item *

An acknowledgement without a subscription id fails it with
C<MCP HTTP subscription acknowledged without a subscription id> and closes the
stream. Such a subscription could be neither stopped nor closed, so handing it
over would hand over a stream with no way of ending it.

=item *

A server that refuses the method answers with a JSON-RPC error rather than a
stream, and that fails the L<Future> like any other error.
C<resolve_on_notification> says what settles the request when the stream
carries it, not that nothing else can.

=back

What is not reported is the B<reason> a subscription ended. The stream can
end in more than one way - the server closing it, the connection failing
underneath it - and they all end the subscription with them, reported alike
through L</on_subscription_end>. L</stop_subscription> is the one end this
transport causes itself, and that one is not reported at all.

=head2 send_notification

    my $future = $transport->send_notification($method, \%params);

Sends a JSON-RPC notification (no C<id> field, no response expected) as an
HTTP POST. The server typically responds with HTTP 202 Accepted. Returns a
L<Future> that resolves once the HTTP request completes with a 2xx status,
whether or not it carries a body: a notification has no answer this client
would read.

A non-2xx status fails the returned L<Future>, with the same precedence as on
the request path: a JSON-RPC error in the body wins over the status, and only a
body without one falls back to the HTTP status line. Such an error carries the
C<mcp> category and the raw error object like any other, as described under
L</send_request>.

The revision defines no header requirements for notification POSTs, so a
notification carries whatever its body supports and nothing more: always
C<Mcp-Method>, and C<MCP-Protocol-Version> only when the notification has an
C<_meta> to take it from.

=head2 close

    my $future = $transport->close;

Ends every subscription still running and returns an immediately resolved
L<Future>.

Nothing is sent. There is no session to terminate, since the current revision
is stateless and each request stands on its own, and a server on this revision
answers C<DELETE> on the MCP endpoint with C<405 Method Not Allowed>. What
there is to end are the streams L</send_request> opened for a subscription:
those are the one thing this transport holds that outlives the request that
started it, and closing the stream is what unsubscribes.

Requests still in flight are left alone. Their caller holds a L<Future> and is
waiting for an answer that may well still arrive, and a close is not a reason
to take it away.

=head2 stop_subscription

    my $stopped = $transport->stop_subscription($subscription_id);

Ends the subscription of that id by closing the stream it runs on, and returns
true if there was one to end. Closing the stream is what unsubscribing is in
this revision: there is no request that cancels a subscription, and no
acknowledgement of one - a server drops the subscription when its stream
finishes.

The C<$subscription_id> is the one the acknowledgement carried, which
L</send_request> hands back as part of the value a subscription request
resolves with:

    my $params = await $transport->send_request('subscriptions/listen',
        { notifications => { toolsListChanged => 1 } },
        resolve_on_notification => 'notifications/subscriptions/acknowledged');

    my $id = $params->{_meta}{'io.modelcontextprotocol/subscriptionId'};

Returns false for an id this transport is not running a subscription under,
which is the same answer an id that already ended gets: a subscription is
forgotten as soon as its stream is over, however it ended. That makes this the
way to ask whether one is still running. The prompt way is
L</on_subscription_end>, which fires the moment a stream ends on its own - the
server closing it, the connection failing - because the request's L<Future>
was settled by the acknowledgement long before and cannot report it. A stop
this transport caused itself, through this method or L</close>, is not an end
on_subscription_end reports.

=head2 is_alive

    my $alive = $transport->is_alive;

Always true: the transport holds no connection between requests, so a dead
endpoint only shows up when a request is actually made. Used by
L<Net::Async::MCP/ping> for its transport-level liveness check.

=head2 mirrors_header_params

    my $mirrors = $transport->mirrors_header_params;

Always true: this binding mirrors tool arguments annotated with
C<x-mcp-header> into C<Mcp-Param-{Name}> headers, so
L<Net::Async::MCP/call_tool> has to resolve them from the tool's input schema
before calling L</send_request> - and is worth fetching a tool list for when it
does not know the schema yet. The other transports answer false and are spared
that request.

=head2 on_notification

    my $transport = Net::Async::MCP::Transport::HTTP->new(
        url             => 'https://example.com/mcp',
        on_notification => sub {
            my ( $transport, $notification ) = @_;
            warn "$notification->{method}\n";
        },
    );

Invoked for every server-initiated notification that arrives on the response
stream of a request, with the decoded JSON-RPC notification as it stood on the
wire - C<method> and, where the notification has any, C<params>. The
C<notifications/progress> of a running C<tools/call> is what a caller usually
waits for here, and it is only worth anything while the call is still running,
which is why it is an event and not part of the L<Future> the call resolves
with.

Set through C<new> or C<configure> like any L<IO::Async::Notifier> event, or
by a subclass implementing a method of this name. Notifications are dropped
while nothing handles them: a server sends them whether or not this client
asked, and there is nothing sensible to do with one no caller wants.

=head2 on_subscription_end

    my $transport = Net::Async::MCP::Transport::HTTP->new(
        url                  => 'https://example.com/mcp',
        on_subscription_end  => sub {
            my ( $transport, $subscription_id ) = @_;
        },
    );

Invoked when a subscription's stream ends on its own, with the subscription id
as its second argument - the same id the acknowledgement handed back and
L</stop_subscription> takes. That is the one handle a caller has on a running
subscription, so it is also the one thing worth telling it that ended.

A subscription is answered by its acknowledgement, and the L<Future> of the
request that opened it is settled there and then; the stream then runs for as
long as the subscription does. So the only way a subscription can come to the
caller's attention again is its end - and there are two kinds. An end this
transport causes itself, through L</stop_subscription> or L</close>, happens
because the caller asked for it and is not reported. An end that comes from
the server's side - the server closing the stream, the connection failing
underneath it, a gateway giving up on it - reaches a caller holding nothing
but an already-settled L<Future>, and that is the end this event reports, the
moment the stream ends. The two are told apart by whether the subscription was
still registered when its stream ended; L</stop_subscription> and L</close>
deregister before they close, so only an end that came from outside arrives
with it standing.

Set through C<new> or C<configure> like any L<IO::Async::Notifier> event, or
by a subclass implementing a method of this name. This is the only transport
that can fire it: it is the only one with a stream a subscription runs on -
the InProcess and Stdio transports cannot carry a subscription at all.

=head1 SEE ALSO

=over 4

=item * L<Net::Async::MCP> - Main client module that uses this transport

=item * L<Net::Async::MCP::Transport::InProcess> - Alternative transport for in-process Perl servers

=item * L<Net::Async::MCP::Transport::Stdio> - Alternative transport for external subprocesses

=item * L<Net::Async::HTTP> - HTTP client used internally

=item * L<https://modelcontextprotocol.io/specification/2026-07-28/basic/transports> - MCP Streamable HTTP transport specification

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
