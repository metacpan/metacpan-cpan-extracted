package Net::WebSocket::X::BadRequestProtocol;

use strict;
use warnings;

use Net::WebSocket::Constants ();

use parent qw( Net::WebSocket::X::Base );

sub _new {
    my ($class, $protocol) = @_;

    my $str = "Received invalid HTTP request protocol: $protocol";

    $str .= " - must be " . Net::WebSocket::Constants::REQUIRED_REQUEST_PROTOCOL();

    return $class->SUPER::_new(
        $str,
        protocol => $protocol,
    );
}

1;
