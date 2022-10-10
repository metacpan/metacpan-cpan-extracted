# NAME

Net::HTTP2 - HTTP/2 in Perl, simplified.

# SYNOPSIS

See [Net::HTTP2::Client::Mojo](https://metacpan.org/pod/Net%3A%3AHTTP2%3A%3AClient%3A%3AMojo).

# DESCRIPTION

This distribution wraps [Protocol::HTTP2](https://metacpan.org/pod/Protocol%3A%3AHTTP2) to
simplify use of [HTTP/2](https://www.rfc-editor.org/rfc/rfc9113) in
Perl.

See [Net::HTTP2::Client](https://metacpan.org/pod/Net%3A%3AHTTP2%3A%3AClient) for the client interface.

(This class itself exposes no code; it’s just here as generic documentation
for the distribution.)

# STATUS

This module is experimental. Interface changes may still happen,
and error handling may not be all up to snuff. Please file bug reports
as appropriate.

# EVENT LOOPS/ABSTRACTIONS

HTTP/2 fits most naturally into non-blocking (rather than blocking) I/O;
hence, this module requires use of an event loop. To ensure broad
compatibility, this library supports multiple event loop abstractions.
Currently [AnyEvent](https://metacpan.org/pod/AnyEvent), [IO::Async](https://metacpan.org/pod/IO%3A%3AAsync), and [Mojolicious](https://metacpan.org/pod/Mojolicious) are supported.

# TLS

Since the major web browsers require TLS for HTTP/2, this library does, too.
Thus, this library needs [Net::SSLeay](https://metacpan.org/pod/Net%3A%3ASSLeay), and it must link to an
[OpenSSL](https://openssl.org) that supports ALPN or NPN.

(NB: Otherwise, this module and its non-core dependency tree are pure Perl!)

If there’s a need for unencrypted HTTP/2, it can be added easily enough.

# CHARACTER ENCODING

Unless otherwise noted, all strings into & out of this library
are byte strings.

# ERROR HANDLING

Most thrown errors are [Net::HTTP2::X::Base](https://metacpan.org/pod/Net%3A%3AHTTP2%3A%3AX%3A%3ABase) instances.

# SEE ALSO

- [Shuvgey](https://metacpan.org/pod/Shuvgey) is an HTTP/2 server. Like this module it wraps
[Protocol::HTTP2](https://metacpan.org/pod/Protocol%3A%3AHTTP2), but it targets a more specific use case.
- [Net::Curl::Easier](https://metacpan.org/pod/Net%3A%3ACurl%3A%3AEasier) offers another path to HTTP/2 in Perl as long
as your system’s [curl](https://curl.se) supports it.
- [HTTP::Tiny](https://metacpan.org/pod/HTTP%3A%3ATiny) comes with Perl and exposes a simple interface for
running HTTP/1 queries.

# LICENSE & COPYRIGHT

Copyright 2022 Gasper Software Consulting. All rights reserved.

Net::HTTP2 is licensed under the same terms as Perl itself (cf.
[perlartistic](https://metacpan.org/pod/perlartistic)).
