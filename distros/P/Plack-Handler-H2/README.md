# Plack::Handler::H2

A high-performance HTTP/2 server handler for Plack, built with C++ and utilizing nghttp2, libevent, and OpenSSL.

[![Test Install](https://github.com/rawleyfowler/perl-Plack-Handler-H2/actions/workflows/test.yaml/badge.svg)](https://github.com/rawleyfowler/perl-Plack-Handler-H2/actions/workflows/test.yaml)

## Description

Plack::Handler::H2 is a high performance PSGI/Plack handler that implements HTTP/2 server functionality using native C++ code with Perl XS bindings. It leverages industry-standard libraries to provide efficient, asynchronous HTTP/2 request handling with TLS/SSL support.

## Features

- **Full HTTP/2 Protocol Support**: Complete HTTP/2 implementation using nghttp2
- **High Performance**: Native C++ implementation with minimal overhead
- **PSGI Compliant**: Full compatibility with PSGI specification

## Dependencies

### System Libraries

- **nghttp2**: HTTP/2 C library (version 1.x)
- **libevent2**: Event notification library (version 2.x)
- **OpenSSL**: TLS/SSL cryptographic library (version 1.1.1 or 3.0+)
- **C++ Compiler**: GCC 7+, Clang 5+, or equivalent with C++17 support

### Perl Modules

- Perl 5.024 or higher, with XS support
- Plack 1.0+
- File::Temp 0.22+
- XSLoader (core module)

## Installation

### Install System Dependencies

**Ubuntu/Debian:**
```bash
sudo apt-get install libnghttp2-dev libevent-dev libssl-dev g++ make
```

**CentOS/RHEL:**
```bash
sudo yum install nghttp2-devel libevent-devel openssl-devel gcc-c++ make
```

**macOS:**
```bash
brew install nghttp2 libevent openssl
```

### Build and Install the Module

From CPAN (when available):
```bash
cpanm Plack::Handler::H2
```

From source:
```bash
perl Makefile.PL
make
make test
make install
```

## Usage

### Basic Example

Create a PSGI application file (`app.psgi`):

```perl
my $app = sub {
    my $env = shift;
    return [
        200,
        ['Content-Type' => 'text/plain'],
        ['Hello, HTTP/2 World!']
    ];
};
```

Run with plackup:

```bash
# With custom certificates
plackup -s H2 \
    --ssl-cert-file=/path/to/server.crt \
    --ssl-key-file=/path/to/server.key \
    --port=8443 \
    app.psgi

# Development mode (auto-generates self-signed certificate)
plackup -s H2 --port=8443 app.psgi
```

### Streaming Response Example

Create a streaming PSGI application (`streaming.psgi`):

```perl
my $app = sub {
    my $env = shift;
    
    return sub {
        my $responder = shift;
        
        # Send headers and get writer
        my $writer = $responder->([
            200,
            ['Content-Type' => 'text/html']
        ]);
        
        # Stream data in chunks
        $writer->write("<html><body>");
        $writer->write("<h1>Streaming Response</h1>");
        sleep 1;  # Simulate processing
        $writer->write("<p>This data arrives progressively.</p>");
        $writer->write("</body></html>");
        
        # Close the stream
        $writer->close();
    };
};
```

Run with plackup:

```bash
plackup -s H2 --port=8443 streaming.psgi
```

### Configuration Options

When using plackup, you can pass options via command-line flags:

- **--ssl-cert-file** (optional): Path to SSL certificate file (PEM format)
  - If not provided, generates self-signed certificate automatically
- **--ssl-key-file** (optional): Path to SSL private key file (PEM format)
  - Required if --ssl-cert-file is provided
- **--host** (optional): IP address to bind to (default: `0.0.0.0`)
- **--port** (optional): Port number to listen on (default: `5000`)
- **--timeout** (optional): General timeout in seconds (default: `120`)
- **--read-timeout** (optional): Read timeout in seconds (default: `60`)
- **--write-timeout** (optional): Write timeout in seconds (default: `60`)
- **--request-timeout** (optional): Request timeout in seconds (default: `30`)
- **--max-request-body-size** (optional): Maximum request body size in bytes (default: `10485760` = 10MB)

Example with custom configuration:

```bash
plackup -s H2 \
    --host=127.0.0.1 \
    --port=8443 \
    --ssl-cert-file=server.crt \
    --ssl-key-file=server.key \
    --max-request-body-size=20971520 \
    app.psgi
```

**Note**: For programmatic use cases where plackup is not suitable, you can instantiate the handler directly with `Plack::Handler::H2->new()`, but this is only recommended for advanced use cases.

## Architecture

The module consists of three main layers:

1. **H2.pm**: High-level Perl interface
   - PSGI handler implementation
   - Configuration management
   - Self-signed certificate generation
   - Streaming response coordination

2. **H2.xs**: XS bindings layer
   - Efficient Perl-to-C++ interface
   - Type conversion and marshalling
   - Function wrappers for core operations

3. **plack_handler_h2.cc/h**: Core C++ implementation
   - nghttp2 integration for HTTP/2 protocol
   - libevent event loop for async I/O
   - OpenSSL for TLS/SSL and ALPN
   - Request/response handling
   - Stream multiplexing
   - Memory-efficient body handling (auto-switches to temp files for large bodies)

## Examples

The `example/` directory contains several working examples:

- **example.pl**: Basic PSGI app with form handling
- **example_streamed.pl**: Streaming response demonstration
- **example_streamed_2.pl**: Delayed response pattern
- **example_dancer2.pl**: Dancer2 framework integration
- **example_mojo.pl**: Mojolicious::Lite integration

## SSL/TLS Configuration

### Production Use

For production, obtain valid certificates from a trusted Certificate Authority:

```bash
# Using Let's Encrypt (example)
certbot certonly --standalone -d yourdomain.com
```

Then run with plackup:

```bash
plackup -s H2 \
    --ssl-cert-file=/etc/letsencrypt/live/yourdomain.com/fullchain.pem \
    --ssl-key-file=/etc/letsencrypt/live/yourdomain.com/privkey.pem \
    --port=443 \
    --host=0.0.0.0 \
    app.psgi
```

### Development, or Internal Use

For development and testing, simply run plackup without certificate options to auto-generate self-signed certificates:

```bash
# Auto-generates self-signed certificate
plackup -s H2 --port=8443 app.psgi
```

Or generate your own self-signed certificate:

```bash
openssl req -x509 -newkey rsa:4096 -keyout server.key -out server.crt \
    -days 365 -nodes -subj "/CN=localhost"

plackup -s H2 \
    --ssl-cert-file=server.crt \
    --ssl-key-file=server.key \
    --port=8443 \
    app.psgi
```

**Note**: Browsers will display security warnings for self-signed certificates. You'll need to accept the security exception to proceed.

## Performance

The handler is designed for high performance:

- Native C++ implementation minimizes overhead
- Stream multiplexing allows concurrent request processing
- Automatic buffering strategy for request bodies (memory for small, temp files for large)
- HTTP/2 header compression reduces bandwidth

## Testing

Run the test suite:
```bash
make test
```

Tests cover:
- Module loading
- Writer API
- Handler configuration
- Streaming responses
- Delayed responses
- Integration tests (requires curl with HTTP/2 support)

## Platform Support

Supported operating systems:
- Linux (Ubuntu, Debian, CentOS, RHEL, etc.)
- macOS
- FreeBSD
- OpenBSD

**Windows**: Not currently supported due to libevent requirements.

## Requirements Summary

- Perl 5.024 or higher
- C++17 compatible compiler (GCC 7+, Clang 5+, or equivalent)
- nghttp2 1.x
- libevent 2.x
- OpenSSL 1.1.1 or 3.0+

## Version

Current version: **0.0.1**

## Troubleshooting

### "Could not create SSL_CTX"
- Verify OpenSSL is properly installed
- Check that certificate and key files are readable
- Ensure certificate and key match

### "Could not read certificate file" / "Could not read private key file"
- Verify file paths are correct and absolute
- Check file permissions (should be readable by the process)
- Ensure files are in PEM format
- Check for proper line endings (UNIX style)

### Connection refused / Connection errors
- Verify the server is listening on the correct address and port
- For localhost testing, try `https://localhost:PORT` (not `http://`)

### Browser shows "NET::ERR_CERT_AUTHORITY_INVALID"
- This is normal for self-signed certificates
- Click "Advanced" and "Proceed to localhost (unsafe)" to continue
- For production, use certificates from a trusted CA

### Large request bodies failing
- Adjust `max_request_body_size` parameter (default 10MB)
- The handler automatically uses temp files for bodies > 1MB

### Roadmap

- ACME certificate handling built in

## License

This software is released under the BSD 3-Clause License. See the LICENSE file for details.

## Authors

Rawley Fowler <rawley@molluscsoftware.com>

## See Also

- [Plack](https://metacpan.org/pod/Plack) - PSGI toolkit and server adapters
- [PSGI Specification](https://metacpan.org/pod/PSGI) - Perl Web Server Gateway Interface
- [nghttp2](https://nghttp2.org/) - HTTP/2 C library
- [libevent](https://libevent.org/) - Event notification library
- [HTTP/2 Specification (RFC 7540)](https://tools.ietf.org/html/rfc7540) - The HTTP/2 protocol
- [HTTP/2 (RFC 9113)](https://www.rfc-editor.org/rfc/rfc9113.html) - Updated HTTP/2 specification
