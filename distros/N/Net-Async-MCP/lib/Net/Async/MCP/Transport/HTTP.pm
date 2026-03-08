package Net::Async::MCP::Transport::HTTP;
# ABSTRACT: Streamable HTTP MCP transport via Net::Async::HTTP
our $VERSION = '0.002';
use strict;
use warnings;
use parent 'IO::Async::Notifier';

use Future;
use JSON::MaybeXS;
use Carp qw( croak );


sub _init {
  my ( $self, $params ) = @_;
  $self->{url} = delete $params->{url}
    or croak "url is required";
  $self->{next_id}    = 0;
  $self->{session_id} = undef;
  $self->{json}       = JSON::MaybeXS->new(utf8 => 1, convert_blessed => 1);
  $self->SUPER::_init($params);
}

sub configure {
  my ( $self, %params ) = @_;
  if (exists $params{url}) {
    $self->{url} = delete $params{url};
  }
  $self->SUPER::configure(%params);
}

sub _add_to_loop {
  my ( $self, $loop ) = @_;
  $self->SUPER::_add_to_loop($loop);

  require Net::Async::HTTP;

  my $http = Net::Async::HTTP->new(
    max_connections_per_host => 0,
  );
  $self->{http} = $http;
  $self->add_child($http);
}

sub send_request {
  my ( $self, $method, $params ) = @_;

  my $id = ++$self->{next_id};
  my $request = {
    jsonrpc => '2.0',
    id      => $id,
    method  => $method,
    defined $params ? ( params => $params ) : (),
  };

  my $body = $self->{json}->encode($request);

  my @headers = (
    'Content-Type' => 'application/json',
    'Accept'       => 'application/json, text/event-stream',
  );
  if (defined $self->{session_id}) {
    push @headers, 'Mcp-Session-Id' => $self->{session_id};
  }

  require HTTP::Request;
  my $http_req = HTTP::Request->new(
    POST => $self->{url},
    [ @headers ],
    $body,
  );

  return $self->{http}->do_request(request => $http_req)->then(sub {
    my ( $response ) = @_;
    return $self->_handle_response($response);
  });
}


sub send_notification {
  my ( $self, $method, $params ) = @_;

  my $request = {
    jsonrpc => '2.0',
    method  => $method,
    defined $params ? ( params => $params ) : (),
  };

  my $body = $self->{json}->encode($request);

  my @headers = (
    'Content-Type' => 'application/json',
    'Accept'       => 'application/json, text/event-stream',
  );
  if (defined $self->{session_id}) {
    push @headers, 'Mcp-Session-Id' => $self->{session_id};
  }

  require HTTP::Request;
  my $http_req = HTTP::Request->new(
    POST => $self->{url},
    [ @headers ],
    $body,
  );

  return $self->{http}->do_request(request => $http_req)->then(sub {
    return Future->done;
  });
}


sub close {
  my ( $self ) = @_;

  if (defined $self->{session_id}) {
    require HTTP::Request;
    my $http_req = HTTP::Request->new(
      DELETE => $self->{url},
      [ 'Mcp-Session-Id' => $self->{session_id} ],
    );
    return $self->{http}->do_request(request => $http_req)->then(sub {
      $self->{session_id} = undef;
      return Future->done;
    })->else(sub {
      $self->{session_id} = undef;
      return Future->done;
    });
  }

  return Future->done;
}


sub _handle_response {
  my ( $self, $response ) = @_;

  my $status = $response->code;

  if ($status == 404) {
    $self->{session_id} = undef;
    return Future->fail("MCP session expired (HTTP 404)");
  }

  unless ($response->is_success) {
    return Future->fail("MCP HTTP error: " . $response->status_line);
  }

  # Capture session ID from response headers
  my $session_id = $response->header('Mcp-Session-Id');
  if (defined $session_id) {
    $self->{session_id} = $session_id;
  }

  my $content_type = $response->content_type // '';

  if ($content_type =~ m{^application/json}i) {
    return $self->_handle_json_response($response->decoded_content);
  }
  elsif ($content_type =~ m{^text/event-stream}i) {
    return $self->_handle_sse_response($response->decoded_content);
  }

  # 202 Accepted with no body (for notifications/responses)
  if ($status == 202) {
    return Future->done(undef);
  }

  return Future->fail("MCP HTTP unexpected content-type: $content_type");
}

sub _handle_json_response {
  my ( $self, $body ) = @_;

  my $data = eval { $self->{json}->decode($body) };
  return Future->fail("MCP HTTP invalid JSON: $@") if $@;
  return Future->fail("MCP HTTP invalid response") unless ref $data eq 'HASH';

  if (my $err = $data->{error}) {
    return Future->fail("MCP error $err->{code}: $err->{message}");
  }

  return Future->done($data->{result});
}

sub _handle_sse_response {
  my ( $self, $body ) = @_;

  # Parse SSE events, find the JSON-RPC response
  my $last_data;
  for my $line (split /\n/, $body) {
    if ($line =~ /^data:\s*(.+)/) {
      my $data_str = $1;
      my $data = eval { $self->{json}->decode($data_str) };
      next unless $data && ref $data eq 'HASH';
      # Look for a JSON-RPC response (has id and result/error)
      if (exists $data->{id} && (exists $data->{result} || exists $data->{error})) {
        $last_data = $data;
      }
    }
  }

  return Future->fail("MCP HTTP no JSON-RPC response in SSE stream")
    unless $last_data;

  if (my $err = $last_data->{error}) {
    return Future->fail("MCP error $err->{code}: $err->{message}");
  }

  return Future->done($last_data->{result});
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Async::MCP::Transport::HTTP - Streamable HTTP MCP transport via Net::Async::HTTP

=head1 VERSION

version 0.002

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
(2025-11-25). Requests are sent as HTTP POST with JSON-RPC bodies, and
responses may arrive as either C<application/json> or C<text/event-stream>
(Server-Sent Events).

Session management is handled automatically via the C<Mcp-Session-Id> header.
If the server assigns a session ID during initialization, it is included in
all subsequent requests.

This transport is selected automatically by L<Net::Async::MCP> when constructed
with a C<url> argument.

=head2 send_request

    my $future = $transport->send_request($method, \%params);

Sends a JSON-RPC request as an HTTP POST to the MCP endpoint. The request
includes C<Accept: application/json, text/event-stream> to support both
direct JSON responses and SSE streams.

Returns a L<Future> that resolves to the C<result> value from the JSON-RPC
response. Handles both C<application/json> and C<text/event-stream> response
content types.

If the server returns HTTP 404, this indicates an expired session. The future
will fail with an appropriate error message.

=head2 send_notification

    my $future = $transport->send_notification($method, \%params);

Sends a JSON-RPC notification (no C<id> field, no response expected) as an
HTTP POST. The server typically responds with HTTP 202 Accepted. Returns an
immediately resolved L<Future> once the HTTP request completes.

=head2 close

    my $future = $transport->close;

Terminates the MCP session by sending an HTTP DELETE request to the MCP
endpoint with the C<Mcp-Session-Id> header. If no session is active, returns
an immediately resolved L<Future>.

=head1 SEE ALSO

=over 4

=item * L<Net::Async::MCP> - Main client module that uses this transport

=item * L<Net::Async::MCP::Transport::InProcess> - Alternative transport for in-process Perl servers

=item * L<Net::Async::MCP::Transport::Stdio> - Alternative transport for external subprocesses

=item * L<Net::Async::HTTP> - HTTP client used internally

=item * L<https://modelcontextprotocol.io/specification/2025-11-25/basic/transports> - MCP Streamable HTTP transport specification

=back

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-net-async-mcp/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de> L<https://raudss.us/>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
