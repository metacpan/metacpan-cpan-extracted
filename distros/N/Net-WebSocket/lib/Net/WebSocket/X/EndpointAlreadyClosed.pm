package Net::WebSocket::X::EndpointAlreadyClosed;

use strict;
use warnings;

use parent qw( Net::WebSocket::X::Base );

sub _new {
    my ($class) = @_;

    return $class->SUPER::_new('This endpoint is already closed!');
}

1;
