package Net::WebSocket::X::UnsupportedProtocolVersion;

use strict;
use warnings;

use parent qw( Net::WebSocket::X::Base );

sub _new {
    my ($class, $version) = @_;

    my $str = "Received invalid WebSocket version in handshake: $version";

    $str .= " - must be " . Net::WebSocket::Constants::PROTOCOL_VERSION();

    return $class->SUPER::_new(
        $str,
        version => $version,
    );
}

1;
