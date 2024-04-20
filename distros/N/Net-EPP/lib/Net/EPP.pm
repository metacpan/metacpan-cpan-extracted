package Net::EPP;
use vars qw($VERSION);
use Net::EPP::Client;
use Net::EPP::Frame;
use Net::EPP::Protocol;
use Net::EPP::ResponseCodes;
use Net::EPP::Simple;
use strict;

our $VERSION = '0.27';

1;

__END__

=pod

=head1 NAME

Net::EPP - a Perl library for the Extensible Provisioning Protocol (EPP).

=head1 DESCRIPTION

EPP is the Extensible Provisioning Protocol. EPP (defined in
L<STD 69|https://www.rfc-editor.org/info/std69>) is an application-layer
client-server protocol for the provisioning and management of objects stored in
a shared central repository. Specified in XML, the protocol defines generic
object management operations and an extensible framework that maps protocol
operations to objects. As of writing, its only well-developed application is the
provisioning of domain names, hosts, and related contact details.

This package offers a number of Perl modules which implement various EPP-
related functions:

=over

=item * a low-level protocol implementation (L<Net::EPP::Protocol>);

=item * a low-level client (L<Net::EPP::Client>);

=item * a high(er)-level client (L<Net::EPP::Simple>);

=item * an EPP frame builder (L<Net::EPP::Frame>);

=item * a utility library to export EPP response codes
(L<Net::EPP::ResponseCodes>).

=back

=head1 SEE ALSO

=over

=item * L<Net::EPP::Server> - an EPP server implementation.

=item * L<App::pepper> - a command-line EPP client.

=back

=head1 AUTHORS

This module is maintained by L<Gavin Brown|https://metacpan.org/author/GBROWN>,
with the assistance of other contributors around the world, including (but not
limited to):

=over

=item * Rick Jansen

=item * Mike Kefeder

=item * Sage Weil

=item * Eberhard Lisse

=item * Yulya Shtyryakova

=item * Ilya Chesnokov

=item * Simon Cozens

=item * Patrick Mevzek

=item * Alexander Biehl

=item * Christian Maile

=item * Tony Finch

=back

=head1 COPYRIGHT

This module is (c) 2008 - 2023 CentralNic Ltd and 2024 Gavin Brown. This module
is free software; you can redistribute it and/or modify it under the same terms
as Perl itself.

=cut
