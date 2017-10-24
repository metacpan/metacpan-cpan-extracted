package Net::WebSocket::X::UnknownSubprotocol;

use strict;
use warnings;

use parent qw( Net::WebSocket::X::Base );

sub _new {
    my ($class, $subprotocol) = @_;

    my $disp_val = $subprotocol;
    $disp_val = q<> if !defined $disp_val;

    return $class->SUPER::_new(
        "The server’s handshake included an unknown subprotocol, “$disp_val”.",
        subprotocol => $subprotocol,
    );
}

1;
