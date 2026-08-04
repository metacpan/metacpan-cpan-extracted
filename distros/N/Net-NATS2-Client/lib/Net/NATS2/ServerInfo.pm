package Net::NATS2::ServerInfo;

use v5.10;
use strict;
use warnings;

use Net::NATS2::Base;

has $_ for qw(server_id version go host port auth_required ssl_required tls_required max_payload headers nonce);

1;
