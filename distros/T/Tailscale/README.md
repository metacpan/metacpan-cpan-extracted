# Tailscale for Perl

Perl bindings for [tailscale-rs](https://github.com/tailscale/tailscale-rs), a
Rust implementation of Tailscale similar to Go's
[tsnet](https://pkg.go.dev/tailscale.com/tsnet). This lets you join a
[Tailscale](https://tailscale.com/) network directly from a Perl program with no
`tailscaled` daemon required.

You can dial outbound TCP connections to machines on your tailnet and listen for
inbound connections, making it straightforward to write both clients and servers
that communicate exclusively over your private Tailscale network.

> **Note:** tailscale-rs is experimental, pre-1.0 software. The Rust library
> sets `TS_RS_EXPERIMENT=this_is_unstable_software` internally. APIs may change.

## Prerequisites

* **Rust toolchain** (1.91+) -- to build `libtailscalers.so` from tailscale-rs
* **Perl** 5.20+
* **cpanm** (or any CPAN client) -- to install Perl dependencies
* **Go** 1.26+ -- only needed to run the integration tests

## Building the shared library

Clone tailscale-rs and build the C FFI shared library:

```sh
git clone https://github.com/tailscale/tailscale-rs.git
cd tailscale-rs
cargo build --release -p ts_ffi
```

This produces `target/release/libtailscalers.so`. Tell the Perl module where to
find it by setting `TS_LIB_PATH`:

```sh
export TS_LIB_PATH=/path/to/tailscale-rs/target/release
```

## Installing Perl dependencies

```sh
cpanm FFI::Platypus FFI::CheckLib HTTP::Request HTTP::Response
```

Or let `Makefile.PL` pull them in:

```sh
perl Makefile.PL && make
```

## Quick start

### Joining your tailnet

Every program needs a **config path** (a JSON file that stores cryptographic
keys -- created automatically on first run) and an **auth key** (a
[Tailscale auth key](https://tailscale.com/kb/1085/auth-keys/) to authorize the
node).

```perl
use Tailscale;

my $ts = Tailscale->new(
    config_path => "/tmp/my-app-state.json",
    auth_key    => "tskey-auth-...",
);

my $ip = $ts->ipv4_addr();   # e.g. "100.64.0.5"
print "I'm on the tailnet at $ip\n";
```

### HTTP client -- fetching a page from a tailnet peer

```perl
use Tailscale;

my $ts = Tailscale->new(
    config_path => "state.json",
    auth_key    => "tskey-auth-...",
);

my $stream = $ts->tcp_connect("100.100.100.100:80");
$stream->send_all("GET / HTTP/1.0\r\nHost: my-server\r\nConnection: close\r\n\r\n");

my $response = "";
while (defined(my $chunk = $stream->recv(4096))) {
    $response .= $chunk;
}
print $response;
```

### HTTP server -- serving requests on your tailnet

```perl
use Tailscale;
use Tailscale::HttpServer;
use HTTP::Response;

my $ts = Tailscale->new(
    config_path => "state.json",
    auth_key    => "tskey-auth-...",
);

print "Listening on " . $ts->ipv4_addr() . ":8080\n";

my $httpd = Tailscale::HttpServer->new(tailscale => $ts, port => 8080);
$httpd->run(sub {
    my ($req) = @_;    # HTTP::Request object

    my $res = HTTP::Response->new(200);
    $res->header('Content-Type' => 'text/plain');
    $res->content("Hello from Perl on Tailscale!\n");
    return $res;
});
```

Then from any other machine on your tailnet:

```sh
curl http://<tailscale-ip>:8080/
```

## API reference

### Tailscale

```perl
my $ts = Tailscale->new(
    config_path => "state.json",    # required -- key state file (created if missing)
    auth_key    => "tskey-auth-...",  # optional -- omit if already authorized
    hostname    => "my-app",        # optional -- requested tailnet hostname
    control_url => "https://...",     # optional -- custom control server (for testing)
);

$ts->ipv4_addr()                # returns e.g. "100.64.0.1"
$ts->tcp_connect("ip:port")     # returns Tailscale::TcpStream
$ts->tcp_listen($port)          # returns Tailscale::TcpListener
$ts->close()                    # shuts down the node
```

### Tailscale::TcpListener

```perl
my $listener = $ts->tcp_listen(8080);
my $stream   = $listener->accept();    # blocks until a connection arrives
$listener->close();
```

### Tailscale::TcpStream

```perl
$stream->send($data)        # send bytes, returns number sent
$stream->send_all($data)    # send all bytes (loops internally)
$stream->recv($maxlen)      # receive up to $maxlen bytes; returns undef on EOF
$stream->close()
```

### Tailscale::HttpServer

A minimal HTTP/1.0 server that uses `HTTP::Request` for parsing and
`HTTP::Response` for formatting. Runs on top of the Tailscale TCP primitives.

```perl
my $httpd = Tailscale::HttpServer->new(tailscale => $ts, port => 8080);

# Serve forever:
$httpd->run(sub {
    my ($req) = @_;          # HTTP::Request
    return HTTP::Response->new(200, "OK", ['Content-Type' => 'text/plain'], "hi\n");
});
```

## Running the examples

```sh
# Terminal 1: start an HTTP server on your tailnet
TS_LIB_PATH=/path/to/tailscale-rs/target/release \
  perl -Ilib examples/http-server.pl state-server.json tskey-auth-...

# Terminal 2: fetch from it
TS_LIB_PATH=/path/to/tailscale-rs/target/release \
  perl -Ilib examples/http-client.pl state-client.json tskey-auth-... 100.x.y.z:8080
```

## Running the tests

The integration tests require Go (to build a test control server with DERP
relay) and the compiled `libtailscalers.so`.

```sh
# Build everything
make -f Makefile.dev all

# Run tests
make -f Makefile.dev test
```

Or manually:

```sh
cd testenv && go build -o testenv . && cd ..
TS_LIB_PATH=/path/to/tailscale-rs/target/release prove -Ilib t/
```

The tests spin up a local Tailscale control plane (using Go's `testcontrol`
package), a DERP relay server, and a STUN server. Two Perl nodes join this
private test network and exchange an HTTP request/response over it.

## Architecture

```
┌──────────────┐     FFI      ┌────────────────────┐
│  Perl code   │─────────────▶│  libtailscalers    │
│  (Tailscale  │FFI::Platypus │  (Rust cdylib)     │
│   module)    │              │  from tailscale-rs │
└──────────────┘              └────────────────────┘
                                       │
                              WireGuard + DERP
                                       │
                              ┌──────────────────┐
                              │   Your tailnet   │
                              └──────────────────┘
```

The Perl module uses [FFI::Platypus](https://metacpan.org/pod/FFI::Platypus) to
call the C FFI functions exported by tailscale-rs (`ts_init`, `ts_tcp_connect`,
`ts_tcp_send`, etc.). No XS or C compiler is needed at Perl build time -- only
the pre-built `libtailscalers.so`.

## License

BSD-3-Clause, matching tailscale-rs.
