package Net::Async::MCP::Transport::InProcess;
# ABSTRACT: In-process MCP transport via direct MCP::Server calls
use strict;
use warnings;

use Future;
use MCP::Server::Context;
use Scalar::Util qw( blessed );
use Carp qw( croak );


sub new {
  my ( $class, %args ) = @_;
  croak "server is required" unless $args{server};
  return bless {
    server  => $args{server},
    next_id => 0,
  }, $class;
}


sub send_request {
  # %options: binding hints from the client, none of which apply in process
  my ( $self, $method, $params, %options ) = @_;

  my $id = ++$self->{next_id};
  my $request = {
    jsonrpc => '2.0',
    id      => $id,
    method  => $method,
    defined $params ? ( params => $params ) : (),
  };

  my $response = $self->{server}->handle($request, MCP::Server::Context->new);

  # Handle Mojo::Promise from async MCP tools
  if (blessed($response) && $response->isa('Mojo::Promise')) {
    my ( $resolved, $error );
    $response->then(
      sub { $resolved = $_[0] },
      sub { $error = $_[0] },
    )->wait;
    return Future->fail("MCP async tool error: $error") if $error;
    $response = $resolved;
  }

  # A JSON-RPC response is plain data, so anything still blessed here is a
  # return shape only a transport can serve. MCP::Server hands back an
  # MCP::Server::Subscription for subscriptions/listen once the server has a
  # notification capable transport of its own, expecting it to be turned into a
  # notification stream. In process there is nothing to stream over, and that
  # is our limitation to report, not a malformed response from the server.
  if (blessed $response) {
    return Future->fail(
      "MCP server returned a " . ref($response) . " for '$method' instead of a "
      . "JSON-RPC response: the in-process transport cannot carry "
      . "server-initiated notifications, so subscriptions/listen is not usable "
      . "here");
  }

  return $self->_process_response($response);
}


sub send_notification {
  my ( $self, $method, $params ) = @_;

  my $request = {
    jsonrpc => '2.0',
    method  => $method,
    defined $params ? ( params => $params ) : (),
  };

  $self->{server}->handle($request, MCP::Server::Context->new);
  return Future->done;
}


sub close { Future->done }


sub is_alive { 1 }


sub mirrors_header_params { 0 }


sub _process_response {
  my ( $self, $response ) = @_;

  return Future->fail("No response from MCP server") unless $response;
  return Future->fail("Invalid response from MCP server")
    unless ref $response eq 'HASH';

  # The message alone cannot carry a code to switch on or an error->{data} to
  # read, so the raw JSON-RPC error object travels with it as the details of a
  # failure in category "mcp". The message stays the first element, so a caller
  # reading the failure in scalar context sees exactly what it saw before.
  if (my $err = $response->{error}) {
    return Future->fail("MCP error $err->{code}: $err->{message}", mcp => $err);
  }

  return Future->done($response->{result});
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Async::MCP::Transport::InProcess - In-process MCP transport via direct MCP::Server calls

=head1 VERSION

version 0.004

=head1 SYNOPSIS

    # Usually created automatically by Net::Async::MCP
    use Net::Async::MCP;

    my $mcp = Net::Async::MCP->new(server => $my_mcp_server);
    $loop->add($mcp);

    # Or construct directly for testing:
    use Net::Async::MCP::Transport::InProcess;

    my $transport = Net::Async::MCP::Transport::InProcess->new(
        server => $my_mcp_server,
    );

=head1 DESCRIPTION

L<Net::Async::MCP::Transport::InProcess> provides direct in-process
communication with an L<MCP::Server> instance. It calls C<handle()>
directly on the server object, passing a fresh L<MCP::Server::Context> with
each request, making it the most efficient transport for Perl-based MCP
servers running in the same process. The context carries no scopes, so
L<MCP::Server>'s OAuth scope checks impose no restriction for this transport.

If a tool returns a L<Mojo::Promise> (from an async MCP server
implementation), the promise is resolved synchronously via C<wait()>. For
fully non-blocking async tools, use L<Net::Async::MCP::Transport::Stdio>
with a separate subprocess instead.

Communication is strictly request/response: there is no stream the server
could push notifications back over, so C<subscriptions/listen> is not usable
with this transport. See L</send_request>.

This transport is selected automatically by L<Net::Async::MCP> when
constructed with a C<server> argument.

=head2 new

    my $transport = Net::Async::MCP::Transport::InProcess->new(
        server => $mcp_server,
    );

Constructs a new in-process transport. Requires a C<server> argument which
must be an L<MCP::Server> instance (or any object with a C<handle> method
that accepts a JSON-RPC request hashref and an L<MCP::Server::Context>
instance).

=head2 send_request

    my $future = $transport->send_request($method, \%params);

Sends a JSON-RPC request to the MCP server by calling C<handle()> directly.
Returns a L<Future> that resolves to the C<result> value from the response,
or fails with an error message if the server returns a JSON-RPC error.

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
else. The failures this transport raises on its own - a missing or unusable
response, an async tool that rejected, and the C<subscriptions/listen> refusal
below - carry their message alone, so a caller that finds no category knows
there is no server error object behind it.

Accepts the same optional trailing name/value options as the other transports,
C<header_params> among them, and ignores all of them: they describe how a
request is mirrored into HTTP headers, and this transport hands the request to
the server as it stands. See
L<Net::Async::MCP::Transport::HTTP/send_request>.

C<subscriptions/listen> is the one method that cannot be served here. If the
server object has a notification capable transport of its own, L<MCP::Server>
answers that request with an L<MCP::Server::Subscription> object rather than a
JSON-RPC response, leaving it to the transport to turn it into a notification
stream; this transport has none, so the returned L<Future> fails saying that it
cannot carry server-initiated notifications. A server without such a transport
never gets that far and answers with JSON-RPC error -32601
(C<METHOD_NOT_FOUND>), which is reported like any other server error.

=head2 send_notification

    my $future = $transport->send_notification($method, \%params);

Sends a JSON-RPC notification (a request with no C<id>, expecting no
response) directly to the server via C<handle()>. Returns an immediately
resolved L<Future>.

=head2 close

    my $future = $transport->close;

No-op for the in-process transport since there is no external process or
connection to close. Returns an immediately resolved L<Future>.

=head2 is_alive

    my $alive = $transport->is_alive;

Always true: the server object lives in the same process, so there is no
connection state that could go away. Used by L<Net::Async::MCP/ping> for its
transport-level liveness check.

=head2 mirrors_header_params

    my $mirrors = $transport->mirrors_header_params;

Always false: there are no HTTP headers here to mirror tool arguments
annotated with C<x-mcp-header> into, so L<Net::Async::MCP/call_tool> resolves
none and never fetches a tool list to do it.

=head1 SEE ALSO

=over 4

=item * L<Net::Async::MCP> - Main client module that uses this transport

=item * L<Net::Async::MCP::Transport::Stdio> - Alternative transport for external subprocesses

=item * L<MCP::Server> - The MCP server this transport communicates with

=item * L<MCP::Server::Context> - Per-request context passed to C<handle()>

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
