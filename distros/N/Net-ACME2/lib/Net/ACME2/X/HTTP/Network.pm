package Net::ACME2::X::HTTP::Network;

=encoding utf-8

=head1 NAME

Net::ACME2::X::HTTP::Network

=head1 DESCRIPTION

This exception class means that an error beneath the HTTP layer occurred:
e.g., maybe the server refused the TCP connection, the TLS handshake failed,
etc.

Subclasses L<X::Tiny::Base>.

=head1 PROPERTIES

=over

=item * C<method> - The request’s HTTP method.

=item * C<url> - The URL for which the request was intended.

=item * C<error> - A human-readable string that describes the failure.

=back

=cut

use strict;
use warnings;

use parent qw( Net::ACME2::X::Generic );

#named args required:
#
#   error
#   method
#   url
#
sub new {
    my ( $self, $args_hr ) = @_;

    return $self->SUPER::new(
        "The system failed to send an HTTP “$args_hr->{'method'}” request to “$args_hr->{'url'}” because of an error: $args_hr->{'error'}",
        $args_hr,
    );
}

1;
