package Protocol::TLS;
use 5.008001;
use strict;
use warnings;

our $VERSION = "0.04";

1;
__END__

=encoding utf-8

=head1 NAME

Protocol::TLS - pure Perl TLS protocol implementation

=head1 SYNOPSIS

    use Protocol::TLS;

=head1 DESCRIPTION

Protocol::TLS is a pure Perl implementation of RFC 5246 ( Transport Layer
Security v1.2 ). All cryptographic functions can be loaded from a separate
Protocol::TLS::Crypto::* plugins (that may be are not pure Perl).

=head1 STATUS

Current status - experimental. Current implementation supports only TLS 1.2, and
MAY BE will support 1.1 and 1.0. It'll NEVER support SSL 3.0.

Supported ciphers (for now):

=over

=item TLS_RSA_WITH_AES_128_CBC_SHA

=item TLS_RSA_WITH_NULL_SHA256

=item TLS_RSA_WITH_NULL_SHA

=back

=head1 MODULES

=head2 L<Protocol::TLS::Client>

Client protocol decoder/encoder

=head2 L<Protocol::TLS::Server>

Server protocol decoder/encoder

=head2 L<Protocol::TLS::Crypto::CryptX>

Crypto plugin based on a crypto toolkit
L<CryptX|https://metacpan.org/pod/CryptX>, that is also based on
L<libtomcrypt|https://github.com/libtom/libtomcrypt> library (Public Domain
License). Also used Crypt::X509 for certificate parsing.

=head1 LICENSE

Copyright (C) Vladimir Lettiev.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Vladimir Lettiev E<lt>thecrux@gmail.comE<gt>

=cut

