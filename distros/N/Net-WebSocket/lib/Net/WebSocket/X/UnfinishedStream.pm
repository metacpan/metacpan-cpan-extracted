package Net::WebSocket::X::UnfinishedStream;

use strict;
use warnings;

use parent qw( Net::WebSocket::X::Base );

sub _new {
    my ($class, $streamer_obj) = @_;

    return $class->SUPER::_new(
        'Streamer object DESTROYed without having sent a final fragment!',
        streamer => $streamer_obj,
    );
}

1;
