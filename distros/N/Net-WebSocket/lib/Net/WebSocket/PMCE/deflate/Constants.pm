package Net::WebSocket::PMCE::deflate::Constants;

use strict;
use warnings;

use constant {

    #lower-case so that deflate.pm satisfies Handshake.pm’s
    #extension interface
    token => 'permessage-deflate',
};

use constant VALID_MAX_WINDOW_BITS => (8 .. 15);

1;
