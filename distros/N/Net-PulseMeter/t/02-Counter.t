#!perl

use warnings;
use strict;
use lib 't/tlib';
use Test::More;
use MockedRedis;
use Net::PulseMeter::Sensor::Base;
use Net::PulseMeter::Sensor::Counter;

my $r = MockedRedis->new;
Net::PulseMeter::Sensor::Base->redis($r);
my $s = Net::PulseMeter::Sensor::Counter->new("foo");
    
subtest 'describe .event' => sub {
    $s->redis->flushdb;
    $s->event(10);
    $s->event(1);
    ok(
        $r->get($s->value_key) == 11,
        "it increments counter by given value"
    );
};

subtest 'describe .incr' => sub {
    $s->redis->flushdb;
    $s->incr;
    $s->incr;
    ok(
        $r->get($s->value_key) == 2,
        "it increments counter by one"
    );
};

done_testing();
