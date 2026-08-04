package Net::NATS2::Message;

use v5.10;
use strict;
use warnings;

use Net::NATS2::Base;

has $_ for qw(subject sid reply_to length header_length headers data subscription);

1;
