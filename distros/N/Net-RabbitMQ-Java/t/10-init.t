use strict;
use warnings;

use Net::RabbitMQ::Java;
use Test::More tests => 1;

ok(eval { Net::RabbitMQ::Java->init; 1 })
    or diag($@);

1;
