use Test::More;
use strict; use warnings FATAL => 'all';

use POEx::ZMQ;

can_ok __PACKAGE__, qw/
  ZMQ_ROUTER EAGAIN EINTR
/;

my $context = POEx::ZMQ->context(max_sockets => 10);
ok $context->max_sockets == 10, '->context ok';

my $sock = POEx::ZMQ->socket(context => $context, type => ZMQ_ROUTER);
isa_ok $sock, 'POEx::ZMQ::Socket';
ok $sock->context == $context, 'socket shortcut ok';

# instanced, no args
my $obj = POEx::ZMQ->new;
cmp_ok 
  $obj->socket(type => ZMQ_ROUTER)->context,
  '==',
  $obj->socket(type => ZMQ_REQ)->context,
  'sockets spawned off instanced POEx::ZMQ share context ok';

cmp_ok
  $obj->socket(type => ZMQ_REP)->zsock->err_handler,
  '==',
  $obj->socket(type => ZMQ_REP)->zsock->err_handler,
  'backend sockets share err_handler ok';

# instanced w/ existing context
my $existing_ctx = POEx::ZMQ->new(context => $context);
cmp_ok
  $existing_ctx->socket(type => ZMQ_REP)->context,
  '==',
  $context,
  'POEx::ZMQ instance with provided context ok';

my $obj_existing_ctx = $obj->socket(context => $context, type => ZMQ_REP);
cmp_ok $obj_existing_ctx->context, '==', $context,
  'providing context to POEx::ZMQ instance during socket creation ok';


done_testing
