use strict; use warnings FATAL => 'all';
use Test::More;
use Test::TypeTiny;

use POEx::ZMQ::Types -all;

use POEx::ZMQ;

# ZMQContext
my $ctx = POEx::ZMQ->context;
should_pass $ctx, ZMQContext;
should_fail bless([]), ZMQContext;

# ZMQEndpoint
should_pass 'tcp://127.0.0.1:1234', ZMQEndpoint;
should_pass 'ipc:///foo/bar',       ZMQEndpoint;
should_pass 'inproc://#foo',        ZMQEndpoint;
should_pass 'inproc://bar-baz',     ZMQEndpoint;
should_pass 'pgm://eth0;10.0.0.1:1234', ZMQEndpoint;
should_pass 'epgm://192.168.0.1;239.192.0.1:1234', ZMQEndpoint;
should_fail 'foo://1.2.3.4',        ZMQEndpoint;

# ZMQSocketBackend
use POEx::ZMQ::FFI::Socket;
my $ffi = POEx::ZMQ::FFI::Socket->new(
  context => $ctx, type => ZMQ_ROUTER
);

should_pass $ffi, ZMQSocketBackend;
should_fail bless([]), ZMQSocketBackend;

# ZMQSocket, ZMQSocket[$type]
my $rtr = POEx::ZMQ->socket(type => ZMQ_ROUTER);
should_pass $rtr, ZMQSocket;
should_pass $rtr, ZMQSocket[ZMQ_ROUTER];
should_pass $rtr, ZMQSocket['ZMQ_ROUTER'];
should_fail $rtr, ZMQSocket[ZMQ_REP];
should_fail $rtr, ZMQSocket['ZMQ_REP'];
should_fail bless([]), ZMQSocket;
should_fail bless([]), ZMQSocket['ZMQ_ROUTER'];
should_fail bless([]), ZMQSocket[ZMQ_ROUTER];

# ZMQSocketType
should_pass ZMQ_ROUTER, ZMQSocketType;
should_fail 'foo',      ZMQSocketType;


done_testing
