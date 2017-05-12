package Net::ACME::X::Protocol;

use strict;
use warnings;

use parent qw( Net::ACME::X::HashBase );

#named args required:
#
#   url
#   status
#   reason
#   type
#   detail
#
#optional:
#   headers
#
sub new {
    my ( $self, $args_hr ) = @_;

    return $self->SUPER::new(
        "The ACME function “$args_hr->{'url'}” indicated an error: “$args_hr->{'detail'}” ($args_hr->{'status'}, “$args_hr->{'reason'}”, $args_hr->{'type'}).",
        $args_hr,
    );
}

1;
