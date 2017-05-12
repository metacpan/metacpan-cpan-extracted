package Net::WAMP::X::RawSocket::BadPongOrder;

use strict;
use warnings;

use parent qw( Net::WAMP::X::Base );

sub _new {
    my ($class, $received) = @_;

    return $class->SUPER::_new(
        "Received PONGs out of order: received “$received”; expected “$self->[0]”",
        received => $received,
        expected => $self->[0],
    );
}

1;
