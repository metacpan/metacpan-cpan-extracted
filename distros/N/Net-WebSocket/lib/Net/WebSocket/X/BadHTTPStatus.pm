package Net::WebSocket::X::BadHTTPStatus;

use strict;
use warnings;

use Net::WebSocket::Constants ();

use parent qw( Net::WebSocket::X::Base );

sub _new {
    my ($class, $code, $reason) = @_;

    my $str = "Received invalid HTTP status: $status";
    $str .= " ($reason)" if defined $reason;

    $str .= " - must be " . Net::WebSocket::Constants::REQUIRED_HTTP_STATUS();

    return $class->SUPER::_new(
        $str,
        code => $code,
        reason => $reason,
    );
}

1;
