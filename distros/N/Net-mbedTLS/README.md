# NAME

Net::mbedTLS - [mbedTLS](https://tls.mbed.org/) in Perl

# SYNOPSIS

    my $fh = IO::Socket::INET->new("example.com:12345");

    my $mbedtls = Net::mbedTLS->new();

    my $client = $mbedtls->create_client($fh);

    # Optional, but useful to do separately if, e.g., you want
    # to report a successful handshake.
    $client->shake_hands();

    # Throws if the error is an “unexpected” one:
    my $input = "\0" x 23;
    my $got = $client->read($input) // do {

        # We get here if, e.g., the socket is non-blocking and we
        # weren’t ready to read.
    };

    # Similar to read(); throws on “unexpected” errors:
    my $wrote = $tls->write($byte_string) // do {
        # ...
    };

# DESCRIPTION

[OpenSSL](https://openssl.org) is great but rather large.

This distribution allows use of mbedTLS, a smaller, simpler TLS library,
from Perl.

# BENEFITS & LIABILITIES

This library, like mbedTLS itself, minimizes memory usage at
the cost of performance. After a simple TLS handshake with this library
Perl’s memory usage is about 6.5 MiB lower than when using
[IO::Socket::SSL](https://metacpan.org/pod/IO%3A%3ASocket%3A%3ASSL) for the same. On the other hand, OpenSSL does the
handshake (as of this writing) about 18 times faster.

# AVAILABLE FUNCTIONALITY

For now this module largely just exposes the ability to do TLS. mbedTLS
itself exposes a good deal more functionality like raw crypto and
configurable ciphers; if you want that stuff, file a feature request.
(A patch with a test is highly desirable!)

# BUILDING/LINKING

This library can link to mbedTLS in several ways:

- Dynamic, to system library (default): This assumes that
mbedTLS is available from some system-default location (e.g.,
`/usr`).
- Dynamic, to a specific path: To do this set
`NET_MBEDTLS_MBEDTLS_BASE` in your environment to whatever directory
contains mbedTLS’s `include` and `lib` (or `library`) directories.
- Static, to a specific path: Like the previous one, but
also set `NET_MBEDTLS_LINKING` to `static` in your environment.

Dynamic linking allows Net::mbedTLS to use the most recent
(compatible) mbedTLS but requires you to have a shared mbedTLS
available, whereas static linking alleviates that dependency at the
cost of always using the same library version.

mbedTLS, alas, as of this writing does not support
[pkg-config](https://www.freedesktop.org/wiki/Software/pkg-config/).
([GitHub issue](https://github.com/ARMmbed/mbedtls/issues/228)) If that
changes then dynamic linking may become more reliable.

NB: mbedTLS **MUST** be built with _position-independent_ code. If you’re
building your own mbedTLS then you’ll need to configure that manually.
GCC’s `-fPIC` flag does this; see this distribution’s CI tests for an example.

# METHODS

## $obj = _CLASS_->new( %OPTS )

Instantiates this class. %OPTS are:

- `trust_store_path` (optional) - Filesystem path to the trust
store (i.e., root certificates). If not given this module will use
[Mozilla::CA](https://metacpan.org/pod/Mozilla%3A%3ACA)’s trust store.

    The trust store isn’t loaded until it’s needed, so if you don’t need
    to verify certificate chains (e.g., you’re only serving without
    TLS client authentication) you can safely omit this.

## $client = _OBJ_->create\_client( $SOCKET, %OPTS )

Initializes a client session on $SOCKET. Returns a
[Net::mbedTLS::Client](https://metacpan.org/pod/Net%3A%3AmbedTLS%3A%3AClient) instance.

%OPTS are:

- `servername` (optional) - The SNI string to send in the handshake.
- `authmode` (optional) - One of this module’s `SSL_VERIFY_*` constants. Defaults as in mbedTLS.

## $client = _OBJ_->create\_server( $SOCKET, %OPTS )

Initializes a server session on $SOCKET. Returns a
[Net::mbedTLS::Server](https://metacpan.org/pod/Net%3A%3AmbedTLS%3A%3AServer) instance.

%OPTS are:

- `servername_cb` (optional) - The callback to run once the
client’s SNI string is received. It will receive a
[Net::mbedTLS::Server::SNICallbackCtx](https://metacpan.org/pod/Net%3A%3AmbedTLS%3A%3AServer%3A%3ASNICallbackCtx) instance, which you can use
to set the necessary parameters for the new TLS session.

    If an exception is thrown, a warning is created, and the TLS session
    is aborted.

    To abort the session without a warning, return -1.

    All other outcomes of this callback tell mbedTLS to continue the
    TLS handshake.

- `key_and_certs` - A reference to an array of key and certs.
The array’s contents may be either:
    - 1 item: Concatenated PEM documents.
    - 2+ items: The key, then certificates. Any item may be in
    PEM or DER format, and any non-initial items (i.e., certificate items)
    may contain multiple certifictes.

# CONSTANTS

These come from mbedTLS:

- Error states: `ERR_SSL_WANT_READ`, `ERR_SSL_WANT_WRITE`,
`ERR_SSL_ASYNC_IN_PROGRESS`, `ERR_SSL_CRYPTO_IN_PROGRESS`,
`MBEDTLS_ERR_SSL_CLIENT_RECONNECT`
- Verify modes: `SSL_VERIFY_NONE`, `SSL_VERIFY_OPTIONAL`,
`SSL_VERIFY_REQUIRED`

# SEE ALSO

[Net::SSLeay](https://metacpan.org/pod/Net%3A%3ASSLeay), an XS binding to OpenSSL, is Perl’s de facto standard TLS
library.

[IO::Socket::SSL](https://metacpan.org/pod/IO%3A%3ASocket%3A%3ASSL) wraps Net::SSLeay with logic to make TLS _almost_ as
easy to use as plain TCP.

\#----------------------------------------------------------------------

# LICENSE & COPYRIGHT

Copyright 2022 Gasper Software Consulting. All rights reserved.

This library is licensed under the same terms as Perl itself.
See [perlartistic](https://metacpan.org/pod/perlartistic).

This library was originally a research project at
[cPanel, L.L.C.](https://cpanel.net).
