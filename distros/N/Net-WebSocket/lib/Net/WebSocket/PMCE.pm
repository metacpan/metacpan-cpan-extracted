package Net::WebSocket::PMCE;

=encoding utf-8

=head1 NAME

Net::WebSocket::PMCE - WebSocket per-message compression extensions

=head1 DESCRIPTION

This module itself does nothing useful. It exists as a placeholder
for documentation on Net::WebSocket’s implementation of PMCEs
(per-message compression extensions), as defined in
L<RFC 7692|https://tools.ietf.org/html/rfc7692>.

If you’re looking for an implementation of the C<permessage-deflate>
extension, look at L<Net::WebSocket::PMCE::deflate>. Note that
C<permessage-deflate> is a specific B<example> of a PMCE;
as of this writing it’s also the only
one that seems to enjoy widespread use.

=head1 DESIGN

PMCEs implement behavior in both the handshake and in the data
exchange portion of a WebSocket session. Like Net::WebSocket itself, then,
Net::WebSocket::PMCE modules are sensibly divided into modules that handle
handshake logic (e.g., L<Net::WebSocket::PMCE::deflate::Server>) and those
that handle data (e.g., L<Net::WebSocket::PMCE::deflate::Data::Server>).

=head1 STATUS

Net::WebSocket’s PMCE support is in ALPHA status. Changes to the API are
not unlikely; be sure to check the changelog before updating,
and please report any issues you find.

=head1 REPOSITORY

L<https://github.com/FGasper/p5-Net-WebSocket>

=head1 AUTHOR

Felipe Gasper (FELIPE)

=head1 COPYRIGHT

Copyright 2017 by L<Gasper Software Consulting, LLC|http://gaspersoftware.com>

=head1 LICENSE

This distribution is released under the same license as Perl.

=cut

die 'Don’t use this module.';

1;
