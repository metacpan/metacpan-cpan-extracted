package Net::ACME2::X::HTTP::Protocol;

=encoding utf-8

=head1 NAME

Net::ACME2::X::HTTP::Protocol

=head1 DESCRIPTION

This exception class means that an error occurred with an HTTP
request, and the problem had specifically to do with something
that happened on the remote server, not just a general connection
problem. For example, this class would be suitable for use when
you get a 500 (Internal Server Error) or a 404 (Not Found), but it
would not be suitable for use if you get a Connection Refused TCP
error when trying to connect.

Subclasses L<X::Tiny::Base>.

=head1 PROPERTIES

Unless otherwise indicated, these come directly from
L<HTTP::Tiny::UA::Response>:

=over

=item * C<method> - The request’s HTTP method.

=item * C<url> - The URL for which the request was intended.

=item * C<status>

=item * C<reason>

=item * C<headers>

=item * C<content>

=item * C<redirects>

=back

=cut

use strict;
use warnings;

use parent qw( Net::ACME2::X::Generic );

# In a normal HTTP response, we don't necessarily know if the body is going
# to be meaningful for display, so only include the first chunk.
#
#(accessed from tests)
use constant BODY_DISPLAY_SIZE => 1_024;

#named args required:
#
#   method
#   reason
#   url
#   status
#
sub new {
    my ( $self, $args_hr ) = @_;

    my $content = $args_hr->{'content'};
    if ( defined($content) && length($content) > BODY_DISPLAY_SIZE() ) {
        substr( $content, BODY_DISPLAY_SIZE() ) = '…';
    }

    $content ||= q<>;

    return $self->SUPER::new(
        "The response to the HTTP “$args_hr->{'method'}” request from “$args_hr->{'url'}” indicated an error ($args_hr->{'status'}, $args_hr->{'reason'}): “$content”",
        $args_hr,
    );
}

1;
