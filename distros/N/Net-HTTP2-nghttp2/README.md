# Net::HTTP2::nghttp2

Perl XS bindings for the [nghttp2](https://nghttp2.org/) HTTP/2 library.

## Synopsis

```perl
use Net::HTTP2::nghttp2;
use Net::HTTP2::nghttp2::Session;

# Check availability
die "nghttp2 not available" unless Net::HTTP2::nghttp2->available;

# Create an HTTP/2 server session
my $session = Net::HTTP2::nghttp2::Session->new_server(
    callbacks => {
        on_begin_headers => sub { ... },
        on_header        => sub { ... },
        on_frame_recv    => sub { ... },
        on_data_chunk_recv => sub { ... },
        on_stream_close  => sub { ... },
    },
);

# Or create a client session
my $session = Net::HTTP2::nghttp2::Session->new_client(
    callbacks => { ... },
);
```

## Description

This module provides Perl bindings for the nghttp2 C library, enabling HTTP/2 protocol support in Perl applications.

nghttp2 is one of the most mature HTTP/2 implementations, used by curl, Apache, and Firefox. It implements RFC 9113 (HTTP/2) and RFC 7541 (HPACK).

## Features

- **Full HTTP/2 support** - DATA, HEADERS, PRIORITY, RST_STREAM, SETTINGS, PUSH_PROMISE, PING, GOAWAY, WINDOW_UPDATE, CONTINUATION frames
- **HPACK header compression** - Efficient header encoding/decoding
- **Flow control** - Automatic and manual flow control management
- **Stream multiplexing** - Multiple concurrent streams over a single connection
- **Server and client modes** - Build HTTP/2 servers or clients
- **Streaming responses** - Data provider callbacks for large/dynamic responses
- **RFC 8441 support** - Extended CONNECT for WebSocket bootstrapping over HTTP/2

## Installation

```bash
cpanm Net::HTTP2::nghttp2
```

The module uses [Alien::nghttp2](https://metacpan.org/pod/Alien::nghttp2) to automatically install the nghttp2 library if not present on your system.

### Manual installation

```bash
perl Makefile.PL
make
make test
make install
```

## Examples

### HTTP/2 Server (h2c - cleartext)

```perl
use IO::Socket::INET;
use Net::HTTP2::nghttp2;
use Net::HTTP2::nghttp2::Session;

my $server = IO::Socket::INET->new(
    LocalPort => 8080,
    Listen    => 128,
    ReuseAddr => 1,
) or die "Cannot create server: $!";

while (my $client = $server->accept) {
    my $session = Net::HTTP2::nghttp2::Session->new_server(
        callbacks => {
            on_begin_headers => sub {
                my ($stream_id) = @_;
                return 0;
            },
            on_header => sub {
                my ($stream_id, $name, $value) = @_;
                # Received header: :method, :path, :scheme, etc.
                return 0;
            },
            on_frame_recv => sub {
                my ($frame) = @_;
                # HEADERS frame with END_STREAM = complete request
                if ($frame->{type} == 1 && ($frame->{flags} & 0x1)) {
                    $session->submit_response($frame->{stream_id},
                        status  => 200,
                        headers => [['content-type', 'text/plain']],
                        body    => "Hello, HTTP/2!\n",
                    );
                }
                return 0;
            },
        },
    );

    $session->send_connection_preface();

    while ($session->want_read || $session->want_write) {
        if (my $out = $session->mem_send) {
            $client->syswrite($out);
        }
        my $buf;
        last unless $client->sysread($buf, 16384);
        $session->mem_recv($buf);
    }
    $client->close;
}
```

### HTTP/2 Client (h2 - TLS)

```perl
use IO::Socket::SSL;
use Net::HTTP2::nghttp2;
use Net::HTTP2::nghttp2::Session;

my $sock = IO::Socket::SSL->new(
    PeerHost           => 'nghttp2.org',
    PeerPort           => 443,
    SSL_alpn_protocols => ['h2'],
) or die "Connection failed: $!";

die "ALPN failed" unless $sock->alpn_selected eq 'h2';

my %response;
my $session = Net::HTTP2::nghttp2::Session->new_client(
    callbacks => {
        on_header => sub {
            my ($stream_id, $name, $value) = @_;
            $response{headers}{$name} = $value;
            return 0;
        },
        on_data_chunk_recv => sub {
            my ($stream_id, $data) = @_;
            $response{body} .= $data;
            return 0;
        },
        on_stream_close => sub {
            $response{done} = 1;
            return 0;
        },
    },
);

$session->send_connection_preface();

my $stream_id = $session->submit_request(
    method    => 'GET',
    path      => '/',
    scheme    => 'https',
    authority => 'nghttp2.org',
);

while (!$response{done} && ($session->want_read || $session->want_write)) {
    if (my $out = $session->mem_send) {
        $sock->syswrite($out);
    }
    my $buf;
    last unless $sock->sysread($buf, 16384);
    $session->mem_recv($buf);
}

print "Status: $response{headers}{':status'}\n";
```

### Streaming Response

```perl
$session->submit_response($stream_id,
    status  => 200,
    headers => [['content-type', 'application/octet-stream']],
    body    => sub {
        my ($stream_id, $max_length) = @_;
        my $chunk = get_next_chunk($max_length);
        my $eof = is_last_chunk() ? 1 : 0;
        return ($chunk, $eof);
    },
);
```

### RFC 8441 - WebSocket over HTTP/2

```perl
my $session = Net::HTTP2::nghttp2::Session->new_server(
    callbacks => { ... },
    settings => {
        enable_connect_protocol => 1,  # Advertise RFC 8441 support
    },
);
```

## Conformance Testing

This module has been tested against [h2spec](https://github.com/summerwind/h2spec), the HTTP/2 conformance testing tool.

### h2spec Results

```
146 tests, 137 passed, 1 skipped, 8 failed (94% pass rate)
```

The 8 failing tests are edge cases where nghttp2 intentionally chooses lenient behavior over strict RFC compliance for better interoperability. This matches the behavior of production implementations like curl, Apache, and nginx.

### Running h2spec

```bash
# Start the test server
perl bin/h2spec-server --port 8080

# In another terminal
h2spec -h localhost -p 8080
```

## Constants

### Error Codes

- `NGHTTP2_ERR_WOULDBLOCK` - Operation would block
- `NGHTTP2_ERR_CALLBACK_FAILURE` - Callback returned an error
- `NGHTTP2_ERR_DEFERRED` - Data production deferred

### Frame Flags

- `NGHTTP2_FLAG_END_STREAM` - End of stream
- `NGHTTP2_FLAG_END_HEADERS` - End of headers
- `NGHTTP2_FLAG_ACK` - Acknowledgment
- `NGHTTP2_FLAG_PADDED` - Frame is padded
- `NGHTTP2_FLAG_PRIORITY` - Priority information present

### Settings

- `NGHTTP2_SETTINGS_MAX_CONCURRENT_STREAMS`
- `NGHTTP2_SETTINGS_INITIAL_WINDOW_SIZE`
- `NGHTTP2_SETTINGS_MAX_FRAME_SIZE`
- `NGHTTP2_SETTINGS_ENABLE_PUSH`
- `NGHTTP2_SETTINGS_ENABLE_CONNECT_PROTOCOL` - RFC 8441

## See Also

- [Alien::nghttp2](https://metacpan.org/pod/Alien::nghttp2) - Alien module for nghttp2
- [nghttp2.org](https://nghttp2.org/) - nghttp2 project homepage
- [RFC 9113](https://datatracker.ietf.org/doc/html/rfc9113) - HTTP/2
- [RFC 7541](https://datatracker.ietf.org/doc/html/rfc7541) - HPACK
- [RFC 8441](https://datatracker.ietf.org/doc/html/rfc8441) - Bootstrapping WebSockets with HTTP/2

## Author

John Napiorkowski <jjnapiork@cpan.org>

## License

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.
