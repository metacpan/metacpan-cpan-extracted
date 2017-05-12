package Net::NATS::Message;

use strict;
use warnings;

use Class::XSAccessor {
    constructor => 'new',
    accessors => [
        'subject',
        'sid',
        'reply_to',
        'length',
        'data',
        'subscription',
    ],
};

1;
