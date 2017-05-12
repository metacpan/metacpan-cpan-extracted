use Test::More;
use strict; use warnings FATAL => 'all';

use Object::RateLimiter;

# new()
eval {; Object::RateLimiter->new };
cmp_ok $@, '=~', qr/parameters/, 'new() without args dies ok';
eval {; Object::RateLimiter->new(events => 3) };
cmp_ok $@, '=~', qr/parameters/, 'new() without seconds param dies ok';
eval {; Object::RateLimiter->new(seconds => 3) };
cmp_ok $@, '=~', qr/parameters/, 'new() without events param dies ok';

my $ctrl = Object::RateLimiter->new(
  events  => 3,
  seconds => 1200,
);

isa_ok $ctrl->new(events => 1, seconds => 2), 'Object::RateLimiter';

# seconds() / events()
cmp_ok $ctrl->seconds, '==', 1200, 'seconds() ok';
cmp_ok $ctrl->events,  '==', 3,   'events() ok';

# delay()
cmp_ok $ctrl->delay, '==', 0, 'delay 1 == 0 ok';
cmp_ok $ctrl->delay, '==', 0, 'delay 2 == 0 ok';
cmp_ok $ctrl->delay, '==', 0, 'delay 3 == 0 ok';

my $delay = $ctrl->delay;
cmp_ok $delay, '>',  0, 'delay 4 > 0 ok';
cmp_ok $delay, '<=', 1200, 'delay 4 <= 1200 ok';
my $delay2 = $ctrl->delay;
cmp_ok $delay2, '>',  0, 'delay 5 > 0 ok';
cmp_ok $delay2, '<=', $delay, 'delay 5 <= delay 4 ok';

# export()
my $opts = $ctrl->export;
my $fresh = Object::RateLimiter->new(%$opts);
cmp_ok $fresh->seconds, '==', 1200, 'exported seconds() ok';
cmp_ok $fresh->events,  '==', 3,    'exported events() ok';
my $delay3 = $ctrl->delay;
cmp_ok $delay3, '>', 0, 'export/regen limiter delay > 0 ok';
cmp_ok $delay3, '<=', $delay2, 'export/regen limiter delay <= prev ok';

# clone() 
my $clone = $ctrl->clone( events => 10 );
ok $clone->_queue != $ctrl->_queue, 'cloned has its own event queue';
cmp_ok $clone->delay,   '==', 0,   'cloned with new events param ok';
cmp_ok $clone->events,  '==', 10,  'cloned has new events()';
cmp_ok $clone->seconds, '==', 1200, 'cloned kept seconds()';

# clone() + expire()
ok !$ctrl->is_expired, 'is_expired() returned false value';
ok !$ctrl->expire, 'expire() returned false value';
ok $ctrl->_queue,  'expire() left queue alone';
my $expire = $ctrl->clone( seconds => 0.5 );
cmp_ok $expire->seconds, '==', 0.5, 'cloned has new seconds()';
note "This test will sleep for one second";
sleep 1;
ok $expire->is_expired, 'is_expired() returned true value';
ok $expire->expire,  'expire() returned true value';
ok !$expire->_queue, 'expire() cleared queue';

# clear()
ok $ctrl->clear,  'clear() returned true value';
ok !$ctrl->_queue, 'clear() cleared queue';

# coderef call
cmp_ok $ctrl->(), '==', 0, 'coderef call ok';

done_testing;
