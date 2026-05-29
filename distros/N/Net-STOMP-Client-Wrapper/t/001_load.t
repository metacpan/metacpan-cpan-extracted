use strict;
use warnings;

use Test::More tests => 19;
BEGIN { use_ok('Net::STOMP::Client::Wrapper') };

my $obj = Net::STOMP::Client::Wrapper->new;

isa_ok($obj, 'Net::STOMP::Client::Wrapper');

can_ok($obj, 'host');
can_ok($obj, 'port');
can_ok($obj, 'login');
can_ok($obj, 'passcode');
can_ok($obj, 'vhost');
can_ok($obj, 'queue_name');
can_ok($obj, 'destination');
can_ok($obj, 'subscribe_id');
can_ok($obj, 'subscribe_ack');
can_ok($obj, 'subscribe_prefetch_count');

can_ok($obj, 'stomp');
can_ok($obj, 'stomp_connect');
can_ok($obj, 'stomp_connect_subscribe');
can_ok($obj, 'stomp_disconnect');

can_ok($obj, 'send');
can_ok($obj, 'management_api');
can_ok($obj, 'management_api_get_queue');
