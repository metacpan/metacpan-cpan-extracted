package Net::WebSocket::X::ControlPayloadTooLong;

use strict;
use warnings;

use parent qw( Net::WebSocket::X::Base );

sub _new {
    my ($class, $type, $payload) = @_;

    return $class->SUPER::_new(
        "A control frame (type “$type”) cannot have a payload ($payload) of over 125 bytes!",
        type => $type,
        payload => $payload,
    );
}

1;
