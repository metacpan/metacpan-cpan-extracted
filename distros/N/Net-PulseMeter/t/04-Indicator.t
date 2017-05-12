#!perl

use warnings;
use strict;
use lib 't/tlib';
use Test::More;
use MockedRedis;
use Net::PulseMeter::Sensor::Base;
use Net::PulseMeter::Sensor::Indicator;

my $r = MockedRedis->new;
Net::PulseMeter::Sensor::Base->redis($r);
my $s = Net::PulseMeter::Sensor::Indicator->new("foo");
    
subtest 'describe .event' => sub {
    $s->redis->flushdb;
    $s->event(11);
    ok(
        $r->get($s->value_key) == 11,
        "it saves value"
    );
};

done_testing();
