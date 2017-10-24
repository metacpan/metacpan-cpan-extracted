package Net::WebSocket::X::BadHTTPMethod;

use strict;
use warnings;

use Net::WebSocket::Constants ();

use parent qw( Net::WebSocket::X::Base );

sub _new {
    my ($class, $method) = @_;

    my $str = "Received invalid HTTP request method: $method";

    $str .= " - must be " . Net::WebSocket::Constants::REQUIRED_HTTP_METHOD();

    return $class->SUPER::_new(
        $str,
        method => $method,
    );
}

1;
