package Net::WebSocket::X::BadToken;

use strict;
use warnings;

use parent qw( Net::WebSocket::X::Base );

sub _new {
    my ($class, $badtoken) = @_;

    my $disp_val = $badtoken;
    $disp_val = q<> if !defined $disp_val;

    return $class->SUPER::_new(
        "“$disp_val” is not a valid HTTP token.",
    );
}

1;
