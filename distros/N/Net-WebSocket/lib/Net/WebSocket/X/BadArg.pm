package Net::WebSocket::X::BadArg;

use strict;
use warnings;

use parent qw( Net::WebSocket::X::Base );

sub _new {
    my ($class, $name, $val, $why) = @_;

    my $caller = (caller 1)[3];

    if ($why) {
        return $class->SUPER::_new(
            "$caller: invalid “$name” ($val) - $why",
            name => $name,
            value => $val,
            why => $why,
        );
    }

    my $disp_val = $val;
    $disp_val = q<> if !defined $val;

    return $class->SUPER::_new(
        sprintf("%s: invalid “%s” (%s)", $caller, $name, $disp_val),
        name => $name,
        value => $val,
    );
}

1;
