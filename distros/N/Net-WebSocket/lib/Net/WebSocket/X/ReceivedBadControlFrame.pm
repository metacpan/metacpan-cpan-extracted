package Net::WebSocket::X::ReceivedBadControlFrame;

use strict;
use warnings;

use parent qw( Net::WebSocket::X::Base );

sub _new {
    my ($class, $txt, $frame) = @_;

    return $class->SUPER::_new( $txt, frame => $frame );
}

1;
