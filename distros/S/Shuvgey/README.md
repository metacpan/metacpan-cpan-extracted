# NAME

Shuvgey - AnyEvent HTTP/2 (RFC 7540) Server for PSGI

# SYNOPSIS

    shuvgey --listen :8000 --tls_key=cert.key --tls_crt=cert.crt app.psgi

# DESCRIPTION

Shuvgey is a lightweight non-blocking, single-threaded HTTP/2 (RFC 7540) Server
that runs PSGI applications on top of [AnyEvent](https://metacpan.org/pod/AnyEvent) event loop.

Shuvgey use [Protocol::HTTP2](https://metacpan.org/pod/Protocol::HTTP2) for HTTP/2 support. Supported plain text HTTP/2
connections, HTTP/1.1 Upgrade, and secure TLS connections (with ALPN/NPN
protocol negotiation).

# STATUS

It's alpha stage. I can run simple [Dancer](https://metacpan.org/pod/Dancer) PSGI app and it even work!

Shuvgey pass all tests of [h2spec tool](https://github.com/summerwind/h2spec)
(version 1.01) for conformance with HTTP/2 implementation. Check it yourself:

    $ h2spec -p 443 -h shuvgey.net -t

# NAMING

There is a wellknown python non-blocking, single-threaded HTTP server Tornado.

Shuvgey is the collective name of evil forces in Komi-Zyryan and Komi-Perm
folklore. Materialized in the form of a strong wind vortex. See also wikipedia
article
[Шувгей](http://ru.wikipedia.org/wiki/%D0%A8%D1%83%D0%B2%D0%B3%D0%B5%D0%B9) (in
russian).

So Shuvgey is like Tornado, but more scary: written in Perl and support HTTP/2
protocol.

# OPTIONS

Avaliable all options from [plackup](https://metacpan.org/pod/plackup) and also some specific Shuvgey options:

- --no\_tls - don't encrypt connection
- --upgrade - use HTTP/1.1 Upgrade protocol to upgrade to HTTP/2 (no tls)
- --tls\_key - path to private key
- --tls\_crt - path to certificate

# LICENSE

Copyright (C) Vladimir Lettiev.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Vladimir Lettiev <thecrux@gmail.com>
