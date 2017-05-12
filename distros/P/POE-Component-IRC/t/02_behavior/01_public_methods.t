use strict;
use warnings FATAL => 'all';
use POE::Component::IRC;
use Test::More tests => 1;

my @methods = qw(
    spawn
    new
    nick_name
    localaddr
    server
    port
    server_name
    session_id
    session_alias
    send_queue
    connected
    disconnect
    logged_in
    raw_events
    isupport
    isupport_dump_keys
    yield
    call
    delay
    delay_remove
    resolver
    send_event
);

can_ok('POE::Component::IRC', @methods);

