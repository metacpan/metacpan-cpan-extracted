#!perl

use warnings;
use strict;
use lib 't/tlib';
use Test::More;
use MockedRedis;
use Net::PulseMeter::Sensor::Base;
use Net::PulseMeter::Sensor::HashedCounter;

my $r = MockedRedis->new;
Net::PulseMeter::Sensor::Base->redis($r);
my $s = Net::PulseMeter::Sensor::HashedCounter->new("foo");
    
subtest 'describe .event' => sub {
    $s->redis->flushdb;
    $s->event({foo => 10, bar => 20});
    is_deeply(
        {$r->hgetall($s->value_key)},
        {foo => 10, bar => 20, total => 30},
        "it saves multiple values"
    );
};

done_testing();
