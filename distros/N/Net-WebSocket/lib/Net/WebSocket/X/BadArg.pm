package Net::WebSocket::X::BadArg;

use strict;
use warnings;

use parent qw( Net::WebSocket::X::Base );

sub _new {
    my ($class, $name, $val) = @_;

    my $caller = (caller 1)[3];

    return $class->SUPER::_new(
        "$caller: invalid “$name” ($val)",
        name => $name,
        value => $val,
    );
}

1;
