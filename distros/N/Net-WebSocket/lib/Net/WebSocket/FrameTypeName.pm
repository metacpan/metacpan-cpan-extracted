package Net::WebSocket::FrameTypeName;

use strict;
use warnings;

sub get_module {
    my ($name) = @_;

    if (index($name, '::') != -1) {
        return $name;
    }

    return "Net::WebSocket::Frame::$name";
}

1;
