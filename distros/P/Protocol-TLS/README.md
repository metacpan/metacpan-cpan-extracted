# NAME

Protocol::TLS - pure Perl TLS protocol implementation

# SYNOPSIS

    use Protocol::TLS;

# DESCRIPTION

Protocol::TLS is a pure Perl implementation of RFC 5246 ( Transport Layer
Security v1.2 ). All cryptographic functions can be loaded from a separate
Protocol::TLS::Crypto::\* plugins (that may be are not pure Perl).

# STATUS

Current status - experimental. Current implementation supports only TLS 1.2, and
MAY BE will support 1.1 and 1.0. It'll NEVER support SSL 3.0.

Supported ciphers (for now):

- TLS\_RSA\_WITH\_AES\_128\_CBC\_SHA
- TLS\_RSA\_WITH\_NULL\_SHA256
- TLS\_RSA\_WITH\_NULL\_SHA

# MODULES

## [Protocol::TLS::Client](https://metacpan.org/pod/Protocol::TLS::Client)

Client protocol decoder/encoder

## [Protocol::TLS::Server](https://metacpan.org/pod/Protocol::TLS::Server)

Server protocol decoder/encoder

## [Protocol::TLS::Crypto::CryptX](https://metacpan.org/pod/Protocol::TLS::Crypto::CryptX)

Crypto plugin based on a crypto toolkit
[CryptX](https://metacpan.org/pod/CryptX), that is also based on
[libtomcrypt](https://github.com/libtom/libtomcrypt) library (Public Domain
License). Also used Crypt::X509 for certificate parsing.

# LICENSE

Copyright (C) Vladimir Lettiev.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Vladimir Lettiev &lt;thecrux@gmail.com>
