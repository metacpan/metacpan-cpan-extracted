# Hacking on Tailscale for Perl

## Prerequisites

* Rust toolchain (1.91+)
* Go 1.26+ (for integration tests)
* Perl 5.20+ with cpanm
* `FFI::Platypus`, `HTTP::Request`, `HTTP::Response` (install via cpanm)

## Building

Build the Rust shared library:

```sh
cd /path/to/tailscale-rs
cargo build --release -p ts_ffi
```

Build the Go test helper:

```sh
cd testenv
go build -o testenv .
```

Or use `Makefile.dev` to do both:

```sh
make -f Makefile.dev all
```

## Running the integration tests

```sh
make -f Makefile.dev test
```

Or manually:

```sh
TS_LIB_PATH=/path/to/tailscale-rs/target/release prove -Ilib t/
```

The tests start a local testcontrol server (Go), a DERP relay, and a
STUN server, then create two Perl nodes on the test tailnet and verify
they can exchange an HTTP request.

## Releasing

1. Bump the `$VERSION` in `lib/Tailscale.pm`.

2. Build a distribution tarball:

```sh
perl Makefile.PL
make manifest
make disttest
make dist
```

This produces `Tailscale-X.XX.tar.gz`.

3. Upload to CPAN:

```sh
cpan-upload Tailscale-X.XX.tar.gz
```

`cpan-upload` authenticates to PAUSE (the CPAN upload server).  It
reads credentials from `~/.pause`:

```
user BRADFITZ
password your-pause-password
```

The file must not be world-readable (`chmod 600 ~/.pause`).

You can also pass `-u USERNAME` on the command line and be prompted for
the password interactively, which avoids storing it on disk.

If you don't have `cpan-upload` installed:

```sh
cpanm CPAN::Uploader
```

You need a [PAUSE account](https://pause.perl.org/) to upload.

## Project layout

```
lib/
  Tailscale.pm              Main module (FFI bindings)
  Tailscale/
    TcpStream.pm            TCP stream wrapper
    TcpListener.pm          TCP listener wrapper
    HttpServer.pm           Minimal HTTP server
examples/
  http-client.pl            Demo HTTP client
  http-server.pl            Demo HTTP server
t/
  integration.t             Integration tests (requires Go + Rust)
testenv/
  main.go                   Go test helper (testcontrol + DERP + STUN)
  go.mod / go.sum
```

## Changes to tailscale-rs

The Perl bindings require several patches to tailscale-rs that aren't
yet upstream as of 2026-04-15. This is all a work in progress.
