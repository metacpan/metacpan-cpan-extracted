package Net::WebSocket::X::MissingHeaders;

use strict;
use warnings;

use parent qw( Net::WebSocket::X::Base );

sub _new {
    my ($class, @names) = @_;

    return $class->SUPER::_new(
        sprintf("Missing header(s): @names"),
        names => \@names,
    );
}

1;
