package Net::Async::MCP::Server::Transport::StreamableHTTP;
# ABSTRACT: Streamable HTTP transport for Net::Async::MCP::Server

use strict;
use warnings;

use parent 'IO::Async::Notifier';

use JSON::MaybeXS qw( encode_json decode_json );
use MIME::Base64 qw( decode_base64 );
use Encode      qw( decode FB_DEFAULT );
use Scalar::Util qw( looks_like_number );
use HTTP::Server::PSGI;

our $VERSION = '0.003';


# The methods whose name-ish parameter is mirrored into Mcp-Name, and the
# parameter it is taken from. Same table the client half uses.
my %NAME_PARAM = (
  'tools/call'     => 'name',
  'resources/read' => 'uri',
  'prompts/get'    => 'name',
);

# The header names the spec owns. HTTP/1.1 header lookup is case-insensitive
# but we still need canonical spellings to read PSGI's HTTP_MCP_PROTOCOL_VERSION
# (a CGI-style env key is one underscore per dash, uppercased) back into the
# spec's form.
my $PROTOCOL_HEADER     = 'MCP-Protocol-Version';
my $METHOD_HEADER       = 'Mcp-Method';
my $NAME_HEADER         = 'Mcp-Name';
my $PARAM_HEADER_PREFIX = 'Mcp-Param-';

sub new {
  my ( $class, %params ) = @_;
  my $server = delete $params{server};
  my $self   = $class->SUPER::new(%params);
  $self->{server} = $server if defined $server;
  return $self;
}

sub configure {
  my ( $self, %params ) = @_;
  for my $key (qw( server host port path origin_allow )) {
    $self->{$key} = delete $params{$key} if exists $params{$key};
  }

  $self->{host}        //= '127.0.0.1';
  $self->{port}        //= 8080;
  $self->{path}        //= '/mcp';
  $self->{origin_allow} //= [];

  # Adapt origin_allow to a hash for O(1) membership tests.
  if ( ref $self->{origin_allow} eq 'ARRAY' ) {
    my %o = map { $_ => 1 } @{ $self->{origin_allow} };
    $self->{origin_allow_set} = \%o;
  }

  $self->SUPER::configure(%params);
}


sub server { $_[0]->{server} }


sub host { $_[0]->{host} }


sub port { $_[0]->{port} }


sub path { $_[0]->{path} }


sub origin_allow { $_[0]->{origin_allow} || [] }


sub to_app {
  my ( $self ) = @_;
  my $transport = $self;

  return sub {
    my ( $env ) = @_;
    return $transport->_handle_request($env);
  };
}


sub listen {
  my ( $self, %opts ) = @_;
  my $host = $self->{host};

  # Refuse to silently expose the server on a public interface.
  unless ( $opts{allow_external_bind}
    || $host eq '127.0.0.1'
    || $host eq '::1'
    || $host eq 'localhost'
    || $host eq '' ) {
    warn "StreamableHTTP listening on $host:${\$self->{port}}; "
      . "this is non-loopback. Set 'host' to 127.0.0.1 or pass "
      . "allow_external_bind to acknowledge.\n";
  }

  my $server = HTTP::Server::PSGI->new(
    host => $host,
    port => $self->{port},
  );
  $server->run( $self->to_app );
  return $server;
}

# --- The PSGI dispatch path ----------------------------------------------

# Reads the request body off the PSGI input handle. PSGI gives us a stream
# to read from, not a string; this is straightforward but the format's two
# scalar/array forms are easy to get wrong.
sub _read_body {
  my ( $env ) = @_;
  my $in = $env->{'psgi.input'};
  return '' unless $in;

  my $cl = $env->{CONTENT_LENGTH};
  return '' unless defined $cl && length $cl && $cl =~ /\A[0-9]+\z/;

  my $body = '';
  my $remaining = $cl;
  while ( $remaining > 0 ) {
    my $chunk = '';
    my $read  = $in->read( $chunk, $remaining );
    return $body unless defined $read && $read > 0;
    $body .= $chunk;
    $remaining -= $read;
  }
  return $body;
}

# Header lookup by the spec's spelling: maps the name to the PSGI env key
# (HTTP_ + uppercased, dashes to underscores). PSGI servers already normalise
# header names that way, which is what makes this case-insensitive in
# practice; there is no fallback scan of other env keys.
sub _lookup_psgi_header {
  my ( $env, $name ) = @_;
  my $psgi_key = 'HTTP_' . uc $name;
  $psgi_key =~ tr/-/_/;
  return $env->{$psgi_key};
}

sub _check_origin {
  my ( $self, $env ) = @_;

  my $set = $self->{origin_allow_set};
  return undef unless $set && keys %$set;

  my $origin = $env->{HTTP_ORIGIN};
  return undef unless defined $origin && length $origin;

  return undef if $set->{$origin};
  return $self->_origin_blocked_response();
}

sub _origin_blocked_response {
  my ( $self ) = @_;
  my $body = encode_json({
    jsonrpc => '2.0',
    id      => undef,
    error   => {
      code    => -32600,
      message => 'Forbidden: invalid Origin',
    },
  });
  return [
    403,
    [
      'Content-Type'   => 'application/json',
      'Content-Length' => length($body),
    ],
    [$body],
  ];
}

# The PSGI entry point (private) — one call per HTTP request. Exposed
# mostly for tests that want to feed canned %env hashes around to_app.
sub _handle_request {
  my ( $self, $env ) = @_;

  # Anything not on the configured MCP endpoint is a 404. A real server
  # might also host a management UI or health check; this one does not.
  my $path = $env->{PATH_INFO} // '/';
  $path = '/' . $path unless $path =~ m{^/};
  return $self->_not_found_response() unless $path eq $self->{path};

  # Origin is checked on every request, including GET/DELETE — the spec's
  # DNS-rebinding guard isn't only about POST.
  if ( my $err = $self->_check_origin($env) ) {
    return $err;
  }

  my $method = $env->{REQUEST_METHOD} // 'GET';

  # Per the 2026-07-28 spec, the only client-server methods this revision
  # binds to the MCP endpoint are POST and GET on /mcp. GET is the legacy
  # stream-open hook that 2025-03-26..2025-11-25 servers used, and this
  # revision dropped it — answering 405 makes the era difference visible.
  unless ( $method eq 'POST' || $method eq 'GET' || $method eq 'DELETE' ) {
    return $self->_method_not_allowed_response();
  }

  if ( $method eq 'GET' || $method eq 'DELETE' ) {
    return $self->_method_not_allowed_response();
  }

  # Content-Type MUST be application/json. Anything else (text/plain,
  # multipart/form-data, an empty body with a notification) is a client
  # error we surface immediately rather than waste a parse on.
  my $ct = $env->{CONTENT_TYPE} // '';
  unless ( $ct =~ m{^application/json\b}i ) {
    return $self->_json_rpc_error_response(
      -32700, 'Content-Type must be application/json', undef,
    );
  }

  my $body = _read_body($env);
  my $request = eval { decode_json($body) };
  if ( $@ || ref $request ne 'HASH' ) {
    return $self->_json_rpc_error_response(
      -32700, 'Parse error', undef,
    );
  }

  # A notification (no id) is accepted and discarded; the spec calls for
  # 202 Accepted with no body. The 2026-07-28 spec explicitly notes that
  # "header requirements for notification POSTs are not defined by this
  # revision", so we skip the full header validation path here.
  if ( !defined $request->{id} ) {
    $self->server->handle($request);
    return $self->_accepted_response();
  }

  if ( my $err = $self->_validate_headers($env, $request) ) {
    return $err;
  }

  # subscriptions/listen has no server->client push channel to deliver
  # *ListChanged in 0.002, so it falls through to handle() and gets the
  # normal -32601 — the same answer the Stdio transport gives. Real push
  # delivery is deferred to k24.

  # Default: synchronous JSON-RPC dispatch. handle() returns either a
  # response hashref or undef (the no-id case we already handled above
  # doesn't reach here, so undef here would be a malformed request —
  # treat it as such).
  my $response = $self->server->handle($request);
  if ( !$response ) {
    return $self->_json_rpc_error_response(
      -32600, 'Invalid request', $request->{id},
    );
  }

  # The client's Accept governs whether we wrap as JSON or as SSE. The
  # spec gives the server the choice per request, and clients that send
  # both content types leave it free. We pick the one the client says it
  # can handle; absent Accept, default to application/json.
  my $accept = $env->{HTTP_ACCEPT} // '';
  my $sse    = $accept =~ m{text/event-stream}i;

  if ( $sse && ( $response->{error} || !$response->{result} ) ) {
    # Errors and notifications don't naturally stream; SSE alone won't
    # carry a JSON-RPC error in any spec-mandated way. Stay on JSON.
    $sse = 0;
  }

  if ( $sse ) {
    return $self->_handle_sse_stream($env, $request, $response);
  }

  # A spec-mandated JSON-RPC error takes its matching HTTP status (404 for
  # method-not-found, 400 for a protocol/version parity error); everything
  # else stays 200 with the payload in the body. Error responses never
  # reach the SSE branch above - the downgrade already forced $sse off.
  return $self->_json_response(
    $response,
    $self->_http_status_for_response($response),
  );
}

# --- Header validation per spec section "Server Validation" -------------

sub _validate_headers {
  my ( $self, $env, $request ) = @_;

  # MCP-Protocol-Version: derived from the body's
  # _meta.io.modelcontextprotocol/protocolVersion; missing or mismatched
  # is a HeaderMismatch.
  my $protocol_header = _lookup_psgi_header($env, $PROTOCOL_HEADER);
  unless ( defined $protocol_header && length $protocol_header ) {
    return $self->_header_mismatch(
      "$PROTOCOL_HEADER header is required",
      $request->{id},
    );
  }
  my $body_version = $self->_meta_field($request, 'io.modelcontextprotocol/protocolVersion');
  unless ( defined $body_version && length $body_version ) {
    return $self->_json_rpc_error_response(
      -32602,
      'Invalid params: missing io.modelcontextprotocol/protocolVersion',
      $request->{id},
    );
  }
  unless ( $protocol_header eq $body_version ) {
    return $self->_header_mismatch(
      "$PROTOCOL_HEADER header '$protocol_header' does not match "
        . "body '$body_version'",
      $request->{id},
    );
  }

  # io.modelcontextprotocol/clientCapabilities: the spec requires it to be
  # present in params._meta on every request; its value is not inspected,
  # so a JSON null satisfies the check. This presence test lives here in
  # the HTTP transport - not in the shared handle() - so a missing required
  # field is rejected with the spec's 400 Bad Request, while the -32602
  # handle() itself can still return (an unknown tool/resource/prompt name)
  # remains an application-level error on HTTP 200.
  unless (
    $self->_meta_has( $request, 'io.modelcontextprotocol/clientCapabilities' )
  ) {
    return $self->_json_rpc_error_response(
      -32602,
      'Invalid params: missing io.modelcontextprotocol/clientCapabilities',
      $request->{id},
    );
  }

  # Mcp-Method: mirrors method.
  my $method_header = _lookup_psgi_header($env, $METHOD_HEADER);
  unless ( defined $method_header && length $method_header ) {
    return $self->_header_mismatch(
      "$METHOD_HEADER header is required",
      $request->{id},
    );
  }
  my $body_method = $request->{method};
  unless ( defined $body_method && length $body_method ) {
    return $self->_json_rpc_error_response(
      -32600, 'Missing JSON-RPC method', $request->{id},
    );
  }
  unless ( $method_header eq $body_method ) {
    return $self->_header_mismatch(
      "$METHOD_HEADER header '$method_header' does not match body",
      $request->{id},
    );
  }

  # Mcp-Name: required for tools/call, resources/read, prompts/get.
  my $name_param = $NAME_PARAM{ $body_method };
  if ( $name_param ) {
    my $name_header = _lookup_psgi_header($env, $NAME_HEADER);
    unless ( defined $name_header && length $name_header ) {
      return $self->_header_mismatch(
        "$NAME_HEADER header is required for $body_method",
        $request->{id},
      );
    }

    my $body_params = ref $request->{params} eq 'HASH' ? $request->{params} : {};
    my $body_name   = $body_params->{$name_param};
    unless ( defined $body_name && length $body_name ) {
      return $self->_json_rpc_error_response(
        -32602,
        "Invalid params: missing params.$name_param",
        $request->{id},
      );
    }

    my $decoded_name = $self->_decode_header($name_header);
    unless ( defined $decoded_name && $decoded_name eq $body_name ) {
      return $self->_header_mismatch(
        "$NAME_HEADER header value does not match body "
          . "params.$name_param",
        $request->{id},
      );
    }
  }

  # Mcp-Param-{Name}: only meaningful for tools/call. The spec names these
  # via x-mcp-header annotations in the tool's inputSchema, which the
  # server's registry holds. Two rules:
  #   1. an annotated property that carries a non-null value in
  #      params.arguments MUST have its Mcp-Param-{Name} header;
  #   2. every Mcp-Param-* header present must match the argument it names
  #      (the annotated property, else an argument of that very name).
  if ( $body_method eq 'tools/call' ) {
    my $params = ref $request->{params} eq 'HASH' ? $request->{params} : {};
    my $arguments = ref $params->{arguments} eq 'HASH' ? $params->{arguments} : {};

    # Unknown tool: no schema check; handle() answers -32602 as before.
    my $tool = ( defined $params->{name} && !ref $params->{name} )
      ? $self->server->find_tool( $params->{name} )
      : undef;
    my @annotated = $tool ? @{ $self->_header_params( $tool->{inputSchema} ) } : ();
    my %by_header = map { lc $_->{name} => $_ } reverse @annotated;

    for my $param (@annotated) {
      my $value = _arg_value( $arguments, $param->{path} );
      next unless defined $value;
      my $header = _lookup_psgi_header( $env, $PARAM_HEADER_PREFIX . $param->{name} );
      unless ( defined $header ) {
        return $self->_header_mismatch(
          "$PARAM_HEADER_PREFIX$param->{name} header is required",
          $request->{id},
        );
      }
    }

    # HTTP field names are case-insensitive (RFC 9110) and tool authors
    # are free to annotate a JSON property `region` with x-mcp-header
    # "Region", so the body-side lookup has to follow.
    my %lc_args = map { lc $_ => $_ } keys %$arguments;

    for my $key ( sort keys %{$env} ) {
      next unless $key =~ m{^HTTP_MCP_PARAM_(.+)$};
      my $arg_name = $1;
      $arg_name =~ tr/_/-/;
      my $header_value = $env->{$key};

      my ( $body_value, $body_label, $type );
      if ( my $param = $by_header{ lc $arg_name } ) {
        $body_value = _arg_value( $arguments, $param->{path} );
        $body_label = join '.', @{ $param->{path} };
        $type       = $param->{type};
      }
      else {
        my $body_key = $lc_args{ lc $arg_name };
        unless ($body_key) {
          return $self->_header_mismatch(
            "$PARAM_HEADER_PREFIX$arg_name header set but body "
              . "has no arguments.$arg_name",
            $request->{id},
          );
        }
        $body_value = $arguments->{$body_key};
        $body_label = $body_key;
      }

      my $decoded = $self->_decode_header($header_value);
      unless (
        defined $decoded
        && $self->_header_value_matches( $decoded, $body_value, $type )
      ) {
        return $self->_header_mismatch(
          "$PARAM_HEADER_PREFIX$arg_name header value does not "
            . "match body arguments.$body_label",
          $request->{id},
        );
      }
    }
  }

  return undef;
}

sub _meta_field {
  my ( $self, $request, $name ) = @_;
  my $params = ref $request->{params} eq 'HASH' ? $request->{params} : {};
  my $meta   = ref $params->{_meta} eq 'HASH' ? $params->{_meta} : {};
  return $meta->{$name};
}

# Presence-only companion to _meta_field: a required _meta key whose value is
# not otherwise inspected (a JSON null is a legitimate value) is checked with
# exists, not truthiness.
sub _meta_has {
  my ( $self, $request, $name ) = @_;
  my $params = ref $request->{params} eq 'HASH' ? $request->{params} : {};
  my $meta   = ref $params->{_meta} eq 'HASH' ? $params->{_meta} : {};
  return exists $meta->{$name};
}

# Decodes a Mcp-Name / Mcp-Param-* header. A value wrapped in the
# =?base64?...?= sentinel is decoded from Base64 of UTF-8; everything else
# is returned as-is. A value that looks like the sentinel but doesn't
# actually decode is flagged as an invalid header.
sub _decode_header {
  my ( $self, $value ) = @_;

  if ( $value =~ /\A=\?base64\?(.*)\?=\z/s ) {
    my $raw = $1;
    my $bytes = eval { decode_base64($raw) };
    return undef unless defined $bytes && length $bytes;
    my $decoded = eval { decode('UTF-8', $bytes, FB_DEFAULT) };
    return $decoded unless $@;
    return undef;
  }

  return $value;
}

# Compares a decoded Mcp-Param-{Name} header against the body argument it
# mirrors, honouring the wire encoding the spec (and the sibling client's
# _header_value) uses. A raw `eq` mishandled the non-string JSON types:
#   - a JSON boolean stringifies to "1"/"" in Perl but is carried on the wire
#     as lowercase 'true'/'false', so it is compared against those words;
#   - a JSON number is carried as its decimal string and compared *numerically*
#     ("42" and "42.0" agree), with a non-numeric header rejected up front;
#   - everything else (plain strings, an undef / JSON-null body) falls back
#     to `eq`.
# Without a declared type, a JSON string that merely looks numeric (e.g. "42")
# is indistinguishable from a JSON number at the Perl level, so it takes the
# numeric path; with the schema's declared type 'string' it compares as a
# string, while a declared integer keeps the numeric leniency.
sub _header_value_matches {
  my ( $self, $header_decoded, $body_value, $type ) = @_;

  # A null or missing body value compares as the empty string, as the
  # final `eq` always has; stated explicitly so it does not warn.
  $body_value = '' unless defined $body_value;

  if ( JSON::MaybeXS::is_bool($body_value) ) {
    return $header_decoded eq ( $body_value ? 'true' : 'false' );
  }

  # A declared string is a string, whatever it looks like: "42" vs "42.0"
  # differ. Only the schema's type can tell, so it is passed in when known.
  if ( defined $type && $type eq 'string' && !ref $body_value ) {
    return "$header_decoded" eq "$body_value";
  }

  if ( !ref $body_value && looks_like_number($body_value) ) {
    return unless looks_like_number($header_decoded);
    return $header_decoded == $body_value;
  }

  return "$header_decoded" eq "$body_value";
}

# The properties of an inputSchema annotated with x-mcp-header, reachable
# from the root through a chain of "properties" keys only (never items,
# oneOf/anyOf/allOf/not, if/then/else or $ref). Same walk as the client's
# _header_params. Returns [ { name, path => [...], type } ].
sub _header_params {
  my ( $self, $schema, $path ) = @_;
  $path //= [];

  return [] unless ref $schema eq 'HASH' && ref $schema->{properties} eq 'HASH';

  my @params;
  for my $key ( sort keys %{ $schema->{properties} } ) {
    my $property = $schema->{properties}{$key};
    next unless ref $property eq 'HASH';

    my @next = ( @$path, $key );
    push @params, {
      name => $property->{'x-mcp-header'},
      path => \@next,
      type => $property->{type},
    } if defined $property->{'x-mcp-header'} && !ref $property->{'x-mcp-header'};
    push @params, @{ $self->_header_params( $property, \@next ) };
  }

  return \@params;
}

# The argument value at a property path, or undef when absent or null.
sub _arg_value {
  my ( $arguments, $path ) = @_;

  my $value = $arguments;
  for my $key (@$path) {
    return undef unless ref $value eq 'HASH';
    $value = $value->{$key};
  }
  return $value;
}

sub _header_mismatch {
  my ( $self, $message, $id ) = @_;
  return $self->_json_rpc_error_response(
    -32020, "Header mismatch: $message", $id,
  );
}

sub _json_rpc_error_response {
  my ( $self, $code, $message, $id, $data ) = @_;
  my $err = { code => $code, message => $message };
  $err->{data} = $data if defined $data;
  my $body = encode_json({
    jsonrpc => '2.0',
    id      => $id,
    error   => $err,
  });
  return [
    400,
    [
      'Content-Type'   => 'application/json',
      'Content-Length' => length($body),
    ],
    [$body],
  ];
}

sub _json_response {
  my ( $self, $response, $status ) = @_;
  $status //= 200;
  my $body = encode_json($response);
  return [
    $status,
    [
      'Content-Type'   => 'application/json',
      'Content-Length' => length($body),
    ],
    [$body],
  ];
}

# Maps a JSON-RPC error response from handle() to the HTTP status the
# 2026-07-28 spec mandates. Only two error classes carry a non-200 status:
#   -32601 (method not found)                 -> 404
#   -32020/-32021/-32022 (parity/version)     -> 400
# Everything else - a -32602 for an unknown tool/resource/prompt, a -32603
# internal error - stays 200 with the JSON-RPC error in the body, since the
# request reached a real method and failed at the application level.
sub _http_status_for_response {
  my ( $self, $response ) = @_;
  return 200
    unless ref $response eq 'HASH' && ref $response->{error} eq 'HASH';
  my $code = $response->{error}{code};
  return 200 unless defined $code;
  return 404 if $code == -32601;
  return 400 if $code == -32020 || $code == -32021 || $code == -32022;
  return 200;
}

sub _accepted_response {
  return [
    202,
    [
      'Content-Length' => 0,
    ],
    [''],
  ];
}

sub _not_found_response {
  my $body = '';
  return [
    404,
    [
      'Content-Type'   => 'text/plain',
      'Content-Length' => 0,
    ],
    [$body],
  ];
}

sub _method_not_allowed_response {
  return [
    405,
    [
      'Allow'          => 'POST',
      'Content-Length' => 0,
    ],
    [''],
  ];
}

# --- SSE response path ----------------------------------------------------

# A successful request that the client wants as SSE arrives here. We emit
# the JSON-RPC response as the single SSE event so the client gets its
# answer in the stream form it asked for; the stream is closed afterwards.
# There is no keepalive: the single event is written and the stream closed
# in the same call.
sub _handle_sse_stream {
  my ( $self, $env, $request, $response ) = @_;
  my $jsonrpc = encode_json($response);

  return sub {
    my ( $respond ) = @_;
    my $writer = $respond->([
      200,
      $self->_sse_headers,
    ]);
    $writer->write( $self->_format_sse_event( '', $jsonrpc ) );
    $writer->close;
    return;
  };
}

sub _sse_headers {
  return [
    'Content-Type'      => 'text/event-stream',
    'X-Accel-Buffering' => 'no',
    'Cache-Control'     => 'no-cache',
    'Connection'        => 'keep-alive',
  ];
}

# Formats a single SSE event. data lines prefix each line of the JSON
# with "data: " per the spec; the event terminator is a blank line.
sub _format_sse_event {
  my ( $self, $event_name, $data ) = @_;

  my @lines;
  if ( defined $event_name && length $event_name ) {
    push @lines, "event: $event_name";
  }
  my $payload = defined $data ? $data : '';
  for my $line ( split /\r?\n/, $payload, -1 ) {
    push @lines, "data: $line";
  }
  # The trailing blank line that terminates the event.
  return join("\n", @lines, '') . "\n";
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Async::MCP::Server::Transport::StreamableHTTP - Streamable HTTP transport for Net::Async::MCP::Server

=head1 VERSION

version 0.003

=head1 SYNOPSIS

    use IO::Async::Loop;
    use Net::Async::MCP::Server;
    use Net::Async::MCP::Server::Transport::StreamableHTTP;

    my $loop = IO::Async::Loop->new;

    my $server = Net::Async::MCP::Server->new(name => 'my-server');
    $loop->add($server);

    my $http = Net::Async::MCP::Server::Transport::StreamableHTTP->new(
        server       => $server,
        host         => '127.0.0.1',
        port         => 8080,
        path         => '/mcp',
        origin_allow => [ 'https://app.example.com' ],
    );
    $loop->add($http);

    # Primary entry point: a PSGI app you can mount under any PSGI server
    # (including an async-capable one on the same loop) or a reverse proxy.
    my $app = $http->to_app;

    # ...or, for a quick blocking local bring-up, the convenience wrapper:
    $http->listen;

=head1 DESCRIPTION

L<Net::Async::MCP::Server::Transport::StreamableHTTP> is the Streamable HTTP
transport for MCP 2026-07-28. It exposes a single HTTP POST endpoint per the
spec, validates the L<request metadata
headers|https://modelcontextprotocol.io/specification/2026-07-28/basic/transports/streamable-http#request-metadata>
against the JSON-RPC body, and answers each request with either an
C<application/json> response or a C<text/event-stream> stream.

The transport is a thin wrapper around L<Net::Async::MCP::Server/handle>: the
PSGI handler decodes the envelope and hands the request to C<handle()>. The
spec-mandated header checks run first, but only for requests that carry an
C<id> — a notification (no C<id>) skips them entirely and goes straight to
C<handle()>, since the 2026-07-28 spec does not define header requirements
for notification POSTs. Method implementations live in
L<Net::Async::MCP::Server>; this module is the HTTP layer and nothing else.

=head1 PROTOCOL

A conforming client POSTs every JSON-RPC request or notification to a single
endpoint (the C<MCP endpoint>, by default F</mcp>). Headers it MUST set:

=over 4

=item *

C<MCP-Protocol-Version> — the protocol version, mirrored from
C<params._meta.io.modelcontextprotocol/protocolVersion> in the body.

=item *

C<Mcp-Method> — mirrored from C<method>.

=item *

C<Mcp-Name> — for C<tools/call>, C<resources/read>, C<prompts/get>, mirrored
from C<params.name> (or C<params.uri> for C<resources/read>).

=item *

C<Mcp-Param-{Name}> — for any tool argument annotated with
C<x-mcp-header: "{Name}"> in the tool's C<inputSchema>, mirrored from the
matching C<arguments> value.

=back

The server looks the called tool up in its registry
(L<Net::Async::MCP::Server/find_tool>) and enforces the annotations: when an
annotated property holds a non-null value in C<arguments>, the matching
C<Mcp-Param-{Name}> header MUST be present, or the request is rejected with
C<-32020>. Annotations are found only along chains of C<properties> keys
(nested objects included); a property reached through C<items>,
C<oneOf>/C<anyOf>/C<allOf>/C<not>, C<if>/C<then>/C<else> or C<$ref> is not
statically addressable and is ignored. The header value is compared by the
property's declared type: a C<string> compares as a string, an C<integer> or
C<number> numerically ("42" equals "42.0"), a C<boolean> as C<true>/C<false>.
A call to an unknown tool is not schema-checked and gets the usual
C<-32602> from C<handle()>.

Any divergence between header value and body value is rejected with HTTP 400
and JSON-RPC error C<-32020 HeaderMismatch>.

The body MUST be a single JSON-RPC request or notification, C<Content-Type:
application/json>. The client MUST include C<Accept: application/json,
text/event-stream> so the server can pick the matching response mode.

=head2 server

    my $server = $transport->server;

Returns the L<Net::Async::MCP::Server> instance this transport feeds.

=head2 host

    my $host = $transport->host;

Returns the interface to bind on. Defaults to C<127.0.0.1>. A non-loopback
bind emits a warning from L</listen> unless C<allow_external_bind> is passed.

=head2 port

    my $port = $transport->port;

Returns the TCP port the transport binds to. Defaults to 8080.

=head2 path

    my $path = $transport->path;

Returns the URL path of the MCP endpoint. Defaults to C</mcp>.

=head2 origin_allow

    my @allow = @{ $transport->origin_allow };

Returns the ArrayRef of origin URLs the transport permits.

B<Security:> an empty list — the default — means B<allow any Origin>. The MCP
Streamable HTTP spec requires the server to validate the C<Origin> header to
prevent DNS-rebinding attacks, in which a page on an attacker's origin drives
a victim's browser into a server bound on their own machine. With the default
in force a cross-origin browser request against a loopback bind is not
rejected, so set C<origin_allow> to your known web origins on any deployment a
browser can reach. Once the list is non-empty it is the whole allowlist: a
request whose C<Origin> header is not in it gets an HTTP 403, while a request
that sends no C<Origin> header at all is still allowed.

=head2 to_app

    my $app = $transport->to_app;
    my $res = $app->($env);

Returns the PSGI application coderef, and is the primary way to run this
transport. Mount it under any PSGI server — an async-capable one driven by
the same L<IO::Async> loop, or a plain one behind a reverse proxy in
production — and the whole request path, C<application/json> and SSE alike,
runs through it. It is also what L<Plack::Test> drives in the test suite and
what L</listen> runs internally.

Unlike L</listen>, C<to_app> brings no accept loop of its own and so does not
block the event loop: the server hosting the app owns how requests are
accepted.

=head2 listen

    $http->listen;

A convenience wrapper around L</to_app> for a quick local bring-up: it binds
the configured C<host:port> with L<HTTP::Server::PSGI> and runs the app under
that server's own accept loop. That accept loop is an ordinary blocking one,
so C<listen> blocks both the caller and the L<IO::Async> loop — unlike
L<Net::Async::MCP::Server::Transport::Stdio/handle_requests>, which reads
through the loop and leaves other notifiers running, nothing else in this loop
gets a turn while C<listen> is up. To share the loop, run L</to_app> under an
async-capable PSGI server instead; a native L<IO::Async::Listener> bring-up is
left to a future ticket.

A non-loopback bind is warned about, since exposing an MCP server on a public
interface is almost always accidental and unauthenticated; pass
C<allow_external_bind> to silence the warning when you really mean it.

=head1 SEE ALSO

L<Net::Async::MCP::Server>, L<Net::Async::MCP::Server::Transport::Stdio>,
L<HTTP::Server::PSGI>, L<Plack::Test>, L<IO::Async::Notifier>.

L<https://modelcontextprotocol.io/specification/2026-07-28/basic/transports/streamable-http>
— the protocol this transport speaks.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-net-async-mcp-server/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
