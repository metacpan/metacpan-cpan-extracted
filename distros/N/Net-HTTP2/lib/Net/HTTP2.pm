package Net::HTTP2;

use strict;
use warnings;

our $VERSION = '0.02';

=encoding utf-8

=head1 NAME

Net::HTTP2 - HTTP/2 in Perl, simplified.

=head1 SYNOPSIS

See L<Net::HTTP2::Client::Mojo>.

=head1 DESCRIPTION

This distribution wraps L<Protocol::HTTP2> to
simplify use of L<HTTP/2|https://www.rfc-editor.org/rfc/rfc9113> in
Perl.

See L<Net::HTTP2::Client> for the client interface.

(This class itself exposes no code; it’s just here as generic documentation
for the distribution.)

=head1 STATUS

This module is experimental. Interface changes may still happen,
and error handling may not be all up to snuff. Please file bug reports
as appropriate.

=head1 EVENT LOOPS/ABSTRACTIONS

HTTP/2 fits most naturally into non-blocking (rather than blocking) I/O;
hence, this module requires use of an event loop. To ensure broad
compatibility, this library supports multiple event loop abstractions.
Currently L<AnyEvent>, L<IO::Async>, and L<Mojolicious> are supported.

=head1 TLS

Since the major web browsers require TLS for HTTP/2, this library does, too.
Thus, this library needs L<Net::SSLeay>, and it must link to an
L<OpenSSL|https://openssl.org> that supports ALPN or NPN.

(NB: Otherwise, this module and its non-core dependency tree are pure Perl!)

If there’s a need for unencrypted HTTP/2, it can be added easily enough.

=head1 CHARACTER ENCODING

Unless otherwise noted, all strings into & out of this library
are byte strings.

=head1 ERROR HANDLING

Most thrown errors are L<Net::HTTP2::X::Base> instances.

=head1 SEE ALSO

=over

=item * L<Shuvgey> is an HTTP/2 server. Like this module it wraps
L<Protocol::HTTP2>, but it targets a more specific use case.

=item * L<Net::Curl::Easier> offers another path to HTTP/2 in Perl as long
as your system’s L<curl|https://curl.se> supports it.

=item * L<HTTP::Tiny> comes with Perl and exposes a simple interface for
running HTTP/1 queries.

=back

=cut

=head1 LICENSE & COPYRIGHT

Copyright 2022 Gasper Software Consulting. All rights reserved.

Net::HTTP2 is licensed under the same terms as Perl itself (cf.
L<perlartistic>).

=cut

1;
