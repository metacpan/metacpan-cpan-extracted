package Net::WebSocket::X::BadAccept;

use strict;
use warnings;

use parent qw( Net::WebSocket::X::Base );

sub _new {
    my ($class, $should_be, $received) = @_;

    my $caller = (caller 1)[3];

    return $class->SUPER::_new(
        "Received invalid “Accept” ($received) from server! (expected: “$should_be”)",
        received => $received,
        expected => $should_be,
    );
}

1;
