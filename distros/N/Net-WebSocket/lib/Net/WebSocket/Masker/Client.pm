package Net::WebSocket::Masker::Client;

use strict;
use warnings;

use Net::WebSocket::Mask ();

sub FRAME_MASK_ARGS {
    return( mask => Net::WebSocket::Mask::create() );
}

1;
