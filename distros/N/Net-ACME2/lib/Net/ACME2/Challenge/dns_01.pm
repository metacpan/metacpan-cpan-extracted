package Net::ACME2::Challenge::dns_01;

use strict;
use warnings;

use parent qw( Net::ACME2::Challenge );

=encoding utf-8

=head1 NAME

Net::ACME2::Challenge::dns_01

=head1 DESCRIPTION

This module is instantiated by L<Net::ACME2::Authorization> and is a
subclass of L<Net::ACME2::Challenge>.

=head1 METHODS

=head2 I<OBJ>->get_record_name()

Returns the name (i.e., just the leftmost label) of the TXT record to create.

(NB: This is always the same name, as per the ACME specification.)

=cut

use constant get_record_name => '_acme-challenge';

#----------------------------------------------------------------------

=head2 I<OBJ>->get_record_value( $ACME )

Accepts a L<Net::ACME2> instance and returns the value of the TXT record
to create.

Example:

    X_XMlEGlxkmqi3B8IFROXLXogCSMGo0JUC9-cJ3Y1NY

=cut

sub get_record_value {
    my ($self, $acme) = @_;

    # Errors for the programmer.
    if (!$acme) {
        die 'Need “Net::ACME2” instance to compute DNS record value!'
    }

    # NB: These are probably loaded anyway.
    require Digest::SHA;
    require MIME::Base64;

    my $key_authz = $acme->make_key_authorization($self);

    my $sha = Digest::SHA::sha256($key_authz);

    return MIME::Base64::encode_base64url($sha);
}

1;
