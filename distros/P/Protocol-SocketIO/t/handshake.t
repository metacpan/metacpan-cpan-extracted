use strict;
use warnings;

use Test::More tests => 3;

use_ok('Protocol::SocketIO::Handshake');

my $m = Protocol::SocketIO::Handshake->new(
    session_id        => 1234567890,
    heartbeat_timeout => 10,
    close_timeout     => 15
);
is $m->to_bytes,
  '1234567890:10:15:websocket,flashsocket,htmlfile,xhr-polling,jsonp-polling';

$m = Protocol::SocketIO::Handshake->new(
    session_id        => 1234567890,
    heartbeat_timeout => 10,
    close_timeout     => 15,
    transports        => [qw/websocket xhr-polling/]
);
is $m->to_bytes, '1234567890:10:15:websocket,xhr-polling';
