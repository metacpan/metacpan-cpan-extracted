package Net::ACME::X::HTTP::Network;

use strict;
use warnings;

use parent qw( Net::ACME::X::HashBase );

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
