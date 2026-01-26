package Plack::Handler::H2;

use strict;
use warnings;
use File::Temp;
use Plack::Handler::H2::Writer;

require XSLoader;
our $VERSION = '0.0.2';
XSLoader::load(__PACKAGE__, $VERSION);

sub new {
    my ($class, %args) = @_;
    return bless \%args, $class;
}

sub run {
    my ($self, $app) = @_;

    die "Unsupported OS for Plack::Handler::H2" if $^O !~ /linux|darwin|freebsd|openbsd/i;

    if (!defined $self->{ssl_cert_file} || !defined $self->{ssl_key_file}) {
        my $cert_dir = File::Temp->newdir( CLEANUP => 1 );
        warn("SSL certificate or key file not provided. Generating self-signed certificate.\n");
        ($self->{ssl_cert_file}, $self->{ssl_key_file}) = $self->_generate_self_signed_cert($cert_dir);
        warn("Generated self-signed certificate at $self->{ssl_cert_file} and key at $self->{ssl_key_file}\n");
        warn("!!! WARNING !!! Self-signed certificates may not be trusted by clients.\n");
    }

    if (!$self->{port} && $self->{port} ne '0') {
        $self->{port} = 5000;
    }

    my $res = ph2_run_wrapper($self, $app, {
        ssl_cert => $self->{ssl_cert_file},
        ssl_key  => $self->{ssl_key_file},
        address  => $self->{host} // '0.0.0.0',
        port     => $self->{port},
        timeout  => $self->{timeout} // 120,
        read_timeout => $self->{read_timeout} // 60,
        write_timeout => $self->{write_timeout} // 60,
        request_timeout => $self->{request_timeout} // 30,
        max_request_body_size => $self->{max_request_body_size} // 10 * 1024 * 1024 # (10 MB)
    });
    return $res;
}

sub _generate_self_signed_cert {
    my ($self, $cert_dir) = @_;

    my $cert_file = File::Temp->new( DIR => $cert_dir, SUFFIX => '.crt' );
    my $key_file = File::Temp->new( DIR => $cert_dir, SUFFIX => '.key' );

    my $openssl_check = `which openssl`;
    chomp($openssl_check);
    unless ($openssl_check) {
        die "OpenSSL is not installed or not found in PATH. Cannot generate self-signed certificate.";
    }

    my $cmd = "openssl req -x509 -newkey rsa:2048 -keyout $key_file -out $cert_file -days 365 -nodes -subj '/CN=localhost' 2>/dev/null";
    system($cmd);

    return ($cert_file, $key_file);
}

sub _responder {
    my ($env, $session) = @_;
    my $responder = sub {
        my $response = shift;
        if (ref($response) ne 'ARRAY' || (@$response < 2 || @$response > 3)) {
            warn "Invalid PSGI response in responder";
            return [500, ['Content-Type' => 'text/plain'], ['Internal Server Error: invalid response from application']];
        }

        if (scalar @$response == 2) {
            ph2_stream_write_headers_wrapper($env, $session, $response);
            return Plack::Handler::H2::Writer->new({
                response => $response,
                writer => sub {
                    my ($end_stream, $data) = @_;
                    ph2_stream_write_data_wrapper($env, $session, $end_stream, $data);    
                }
            });
        }

        return $response;
    };

    return $responder;
}

1;

__END__

=head1 NAME

Plack::Handler::H2 - High-performance HTTP/2 server handler for Plack

=head1 SYNOPSIS

Create a PSGI application file (C<app.psgi>):

    my $app = sub {
        my $env = shift;
        return [
            200,
            ['Content-Type' => 'text/plain'],
            ['Hello, HTTP/2 World!']
        ];
    };

Run with plackup:

    # With custom certificates
    plackup -s H2 \
        --ssl-cert-file=/path/to/server.crt \
        --ssl-key-file=/path/to/server.key \
        --port=8443 \
        app.psgi

    # Development mode (auto-generates self-signed certificate)
    plackup -s H2 --port=8443 app.psgi

=head1 DESCRIPTION

Plack::Handler::H2 is a production-ready PSGI/Plack handler that implements 
HTTP/2 server functionality using native C++ code with Perl XS bindings. It 
leverages industry-standard libraries (nghttp2, libevent, OpenSSL) to provide 
efficient, asynchronous HTTP/2 request handling with TLS/SSL support.

This handler is designed to be used with C<plackup> for most use cases. Direct 
instantiation is only recommended for advanced scenarios where plackup cannot 
be used.

=head1 FEATURES

=over 4

=item * B<Full HTTP/2 Protocol Support>

Complete HTTP/2 implementation using nghttp2 with header compression (HPACK), 
stream multiplexing, server push capabilities, and flow control.

=item * B<TLS/SSL Required>

Secure connections with OpenSSL, including ALPN (Application-Layer Protocol 
Negotiation). Supports OpenSSL 1.1.1+ and 3.0+. Automatically generates 
self-signed certificates for development.

=item * B<Streaming Responses>

Full support for PSGI streaming and delayed responses, including chunked 
transfer without Content-Length, progressive rendering, and server-sent 
events compatibility.

=item * B<Asynchronous I/O>

Event-driven architecture using libevent2 with non-blocking request handling, 
concurrent stream processing, and efficient memory management for large request 
bodies.

=item * B<High Performance>

Native C++ implementation with minimal overhead, automatic buffering strategy 
for request bodies (memory for small, temp files for large), and HTTP/2 header 
compression.

=item * B<PSGI Compliant>

Full compatibility with PSGI specification and works with any PSGI-compatible 
framework including Dancer2, Mojolicious::Lite, and custom PSGI applications.

=back

=head1 CONFIGURATION

When using plackup, configuration is provided via command-line options:

=head2 SSL/TLS Options

=over 4

=item B<--ssl-cert-file> (optional)

Path to SSL certificate file in PEM format. If not provided, a self-signed 
certificate is automatically generated for development use.

=item B<--ssl-key-file> (optional)

Path to SSL private key file in PEM format. Required if C<--ssl-cert-file> 
is provided.

=back

=head2 Server Options

=over 4

=item B<--host> (optional, default: C<0.0.0.0>)

IP address to bind to.

=item B<--port> (optional, default: C<5000>)

Port number to listen on.

=item B<--timeout> (optional, default: C<120>)

General timeout in seconds.

=item B<--read-timeout> (optional, default: C<60>)

Read timeout in seconds.

=item B<--write-timeout> (optional, default: C<60>)

Write timeout in seconds.

=item B<--request-timeout> (optional, default: C<30>)

Request timeout in seconds.

=item B<--max-request-body-size> (optional, default: C<10485760>)

Maximum request body size in bytes (default is 10MB).

=back

=head2 Example with Custom Configuration

    plackup -s H2 \
        --host=127.0.0.1 \
        --port=8443 \
        --ssl-cert-file=server.crt \
        --ssl-key-file=server.key \
        --max-request-body-size=20971520 \
        app.psgi

=head1 METHODS

=head2 new

    my $handler = Plack::Handler::H2->new(%options);

Creates a new handler instance. This is typically called by plackup and 
rarely needs to be called directly.

B<Options:>

=over 4

=item * C<ssl_cert_file> - Path to SSL certificate file

=item * C<ssl_key_file> - Path to SSL private key file

=item * C<host> - IP address to bind to

=item * C<port> - Port number to listen on

=item * C<timeout> - General timeout in seconds

=item * C<read_timeout> - Read timeout in seconds

=item * C<write_timeout> - Write timeout in seconds

=item * C<request_timeout> - Request timeout in seconds

=item * C<max_request_body_size> - Maximum request body size in bytes

=back

=head2 run

    $handler->run($app);

Runs the PSGI application with the configured options. This method starts 
the HTTP/2 server and enters the event loop. It will not return until the 
server is shut down.

B<Parameters:>

=over 4

=item * C<$app> - A PSGI application code reference

=back

=head1 STREAMING RESPONSES

Plack::Handler::H2 fully supports PSGI streaming responses using the delayed 
response pattern. This is useful for:

=over 4

=item * Large responses that don't fit in memory

=item * Server-sent events

=item * Progressive rendering

=item * Long-polling

=back

=head2 Streaming Example

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

The writer object is an instance of L<Plack::Handler::H2::Writer> which 
provides C<write()> and C<close()> methods for sending data chunks.

=head1 SSL/TLS CONFIGURATION

=head2 Production Use

For production, obtain valid certificates from a trusted Certificate Authority:

    # Using Let's Encrypt (example)
    certbot certonly --standalone -d yourdomain.com

Then run with plackup:

    plackup -s H2 \
        --ssl-cert-file=/etc/letsencrypt/live/yourdomain.com/fullchain.pem \
        --ssl-key-file=/etc/letsencrypt/live/yourdomain.com/privkey.pem \
        --port=443 \
        --host=0.0.0.0 \
        app.psgi

=head2 Development Use

For development and testing, simply run plackup without certificate options 
to auto-generate self-signed certificates:

    plackup -s H2 --port=8443 app.psgi

Or generate your own self-signed certificate:

    openssl req -x509 -newkey rsa:4096 -keyout server.key -out server.crt \
        -days 365 -nodes -subj "/CN=localhost"

    plackup -s H2 \
        --ssl-cert-file=server.crt \
        --ssl-key-file=server.key \
        --port=8443 \
        app.psgi

B<Note:> Browsers will display security warnings for self-signed certificates. 
You'll need to accept the security exception to proceed.

=head1 SYSTEM REQUIREMENTS

=head2 System Libraries

=over 4

=item * B<nghttp2> - HTTP/2 C library (version 1.x)

=item * B<libevent2> - Event notification library (version 2.x)

=item * B<OpenSSL> - TLS/SSL cryptographic library (version 1.1.1 or 3.0+)

=item * B<C++ Compiler> - GCC 7+, Clang 5+, or equivalent with C++17 support

=back

=head2 Installation of Dependencies

B<Ubuntu/Debian:>

    sudo apt-get install libnghttp2-dev libevent-dev libssl-dev g++ make

B<CentOS/RHEL:>

    sudo yum install nghttp2-devel libevent-devel openssl-devel gcc-c++ make

B<macOS:>

    brew install nghttp2 libevent openssl

=head2 Perl Requirements

=over 4

=item * Perl 5.024 or higher with XS support

=item * Plack 1.0+

=item * File::Temp 0.22+

=item * XSLoader (core module)

=back

=head1 PLATFORM SUPPORT

Supported operating systems:

=over 4

=item * Linux (Ubuntu, Debian, CentOS, RHEL, etc.)

=item * macOS

=item * FreeBSD

=item * OpenBSD

=back

B<Windows:> Not currently supported due to libevent requirements.

=head1 ARCHITECTURE

The module consists of three main layers:

=over 4

=item 1. B<H2.pm> - High-level Perl interface

PSGI handler implementation, configuration management, self-signed certificate 
generation, and streaming response coordination.

=item 2. B<H2.xs> - XS bindings layer

Efficient Perl-to-C++ interface, type conversion and marshalling, and function 
wrappers for core operations.

=item 3. B<plack_handler_h2.cc/h> - Core C++ implementation

nghttp2 integration for HTTP/2 protocol, libevent event loop for async I/O, 
OpenSSL for TLS/SSL and ALPN, request/response handling, stream multiplexing, 
and memory-efficient body handling (auto-switches to temp files for large bodies).

=back

=head1 PERFORMANCE

The handler is designed for high performance:

=over 4

=item * Native C++ implementation minimizes overhead

=item * Asynchronous I/O prevents blocking

=item * Stream multiplexing allows concurrent request processing

=item * Automatic buffering strategy (memory for small bodies, temp files for large)

=item * HTTP/2 header compression reduces bandwidth

=back

See the C<benchmark/> directory in the distribution for benchmarking tools to 
compare with other Plack handlers.

=head1 TROUBLESHOOTING

=head2 "Could not create SSL_CTX"

=over 4

=item * Verify OpenSSL is properly installed

=item * Check that certificate and key files are readable

=item * Ensure certificate and key match

=back

=head2 "Could not read certificate file" / "Could not read private key file"

=over 4

=item * Verify file paths are correct and absolute

=item * Check file permissions (should be readable by the process)

=item * Ensure files are in PEM format

=item * Check for proper line endings (UNIX style)

=back

=head2 Connection refused / Connection errors

=over 4

=item * Verify the server is listening on the correct address and port

=item * Check firewall settings

=item * Ensure no other service is using the same port

=item * For localhost testing, try C<https://localhost:PORT> (not C<http://>)

=back

=head2 Browser shows "NET::ERR_CERT_AUTHORITY_INVALID"

This is normal for self-signed certificates. Click "Advanced" and "Proceed to 
localhost (unsafe)" to continue. For production, use certificates from a 
trusted CA.

=head2 Large request bodies failing

Adjust C<--max-request-body-size> parameter (default 10MB). The handler 
automatically uses temp files for bodies larger than 1MB.

=head1 EXAMPLES

The C<example/> directory in the distribution contains several working examples:

=over 4

=item * B<example.pl> - Basic PSGI app with form handling

=item * B<example_streamed.pl> - Streaming response demonstration

=item * B<example_streamed_2.pl> - Delayed response pattern

=item * B<example_dancer2.pl> - Dancer2 framework integration

=item * B<example_mojo.pl> - Mojolicious::Lite integration

=back

=head1 SEE ALSO

=over 4

=item * L<Plack> - PSGI toolkit and server adapters

=item * L<PSGI> - Perl Web Server Gateway Interface specification

=item * L<Plack::Handler::H2::Writer> - Streaming response writer

=item * L<nghttp2|https://nghttp2.org/> - HTTP/2 C library

=item * L<libevent|https://libevent.org/> - Event notification library

=item * L<RFC 7540|https://tools.ietf.org/html/rfc7540> - HTTP/2 specification

=item * L<RFC 9113|https://www.rfc-editor.org/rfc/rfc9113.html> - Updated HTTP/2 specification

=back

=head1 VERSION

Version 0.0.1

=head1 REPOSITORY

L<https://github.com/rawleyfowler/perl-Plack-Handler-H2>

Report bugs and issues at: L<https://github.com/rawleyfowler/perl-Plack-Handler-H2/issues>

=head1 AUTHOR

Rawley Fowler E<lt>rawley@molluscsoftware.comE<gt>

=head1 LICENSE

This software is released under the BSD 3-Clause License. See the LICENSE 
file in the distribution for details.

=head1 ACKNOWLEDGMENTS

Built with:

=over 4

=item * nghttp2 for HTTP/2 protocol implementation

=item * libevent for asynchronous I/O

=item * OpenSSL for TLS/SSL security

=back

Special thanks to the Plack community and all contributors.

=cut
