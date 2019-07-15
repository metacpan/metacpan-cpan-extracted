package Net::ACME2::X::ACME;

use strict;
use warnings;

use parent qw( Net::ACME2::X::Generic );

=encoding utf-8

=head1 NAME

Net::ACME2::X::ACME

=head1 SYNOPSIS

    local $@;

    eval { ...; 1 } or do {
        if ( ref($@) && (ref $@)->isa('Net::ACME2::X::ACME') ) {
            my $acme_err = $@->get('acme');

            my $http_err = $@->get('http');
        }
    };

=head1 DESCRIPTION

This class represents an ACME protocol error.

=head1 PROPERTIES

=over

=item * C<http> - An instance of L<Net::ACME2::X::HTTP::Protocol>
that represents the failure.

=item * C<acme> - An instance of L<Net::ACME2::Error> that represents
the error as the ACME server sent it in the HTTP payload. If there was no
such error (e.g., if a network error occurred), this will be undef.

=back

=cut

#----------------------------------------------------------------------
# This class indicates that the ACME server gave an error response.
# It should be coincident with a 4xx-level HTTP response.
#----------------------------------------------------------------------

#named args required:
#
#   http
#   acme
#
#optional:
#   headers
#
sub new {
    my ( $self, $args_hr ) = @_;

    my $http = $args_hr->{'http'};

    my $http_str = join( ' ', $http->get('status'), $http->get('reason') );
    my $url = $http->get('url');

    my $acme_str = $args_hr->{'acme'}->to_string();

    return $self->SUPER::new(
        "“$url” indicated an ACME error: $http_str ($acme_str).",
        $args_hr,
    );
}

1;
