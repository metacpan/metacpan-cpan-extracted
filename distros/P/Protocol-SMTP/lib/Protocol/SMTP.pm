package Protocol::SMTP;
# ABSTRACT: Mail sending protocol implementation
use strict;
use warnings;

our $VERSION = '0.002';

=head1 NAME

Protocol::SMTP - abstract support for the SMTP mail sending protocol

=head1 VERSION

version 0.002

=head1 SYNOPSIS

 use Protocol::SMTP::Client;

=head1 DESCRIPTION

See L<Protocol::SMTP::Client>. Note that this is an abstract protocol
handler, it does not deal with the transport itself - use L<Net::Async::SMTP>
if you want to send emails.

Features supported at the moment:

=over 4

=item * STARTTLS upgrading

=item * Multiple recipients per outgoing email

=item * 8BITMIME body encoding

=item * SASL authentication

=back

Missing features:

=over 4

=item * Everything else

=back

=cut

1;

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2012-2014. Licensed under the same terms as Perl itself.
