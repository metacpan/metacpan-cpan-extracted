package Net::ACME2::X::UnexpectedResponse;

use strict;
use warnings;

use parent qw( Net::ACME2::X::Generic );

#named args required:
#
#   uri
#   status
#   reason
#
#optional:
#   headers
#
sub new {
    my ( $self, $args_hr ) = @_;

    return $self->SUPER::new(
        "The [asis,ACME] function “$args_hr->{'uri'}” returned an unexpected status: “$args_hr->{'status'}” ($args_hr->{'reason'}).",
        $args_hr,
    );
}

1;
