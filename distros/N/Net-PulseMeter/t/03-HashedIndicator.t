#!perl

use warnings;
use strict;
use lib 't/tlib';
use Test::More;
use MockedRedis;
use Net::PulseMeter::Sensor::Base;
use Net::PulseMeter::Sensor::HashedIndicator;

my $r = MockedRedis->new;
Net::PulseMeter::Sensor::Base->redis($r);
my $s = Net::PulseMeter::Sensor::HashedIndicator->new("foo");
    
subtest 'describe .event' => sub {
    $s->redis->flushdb;
    my $data = {1 => 10, 2 => 20};
    $s->event($data);
    is_deeply(
        {$r->hgetall($s->value_key)},
        $data,
        "it saves multiple values"
    );
};

done_testing();
