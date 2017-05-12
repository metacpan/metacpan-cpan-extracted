#!perl

use warnings;
use strict;
use lib 't/tlib';
use Test::More;
use MockedRedis;
use Net::PulseMeter::Sensor::Base;
use Net::PulseMeter::Sensor::UniqCounter;

my $r = MockedRedis->new;
Net::PulseMeter::Sensor::Base->redis($r);
my $s = Net::PulseMeter::Sensor::UniqCounter->new("foo");
    
subtest 'describe .event' => sub {
    $s->redis->flushdb;
    $s->event($_) for (1, 1, 2, 2, 2, 3);
    
    ok(
        $r->scard($s->value_key) == 3,
        "it counts uniq values"
    );
};

done_testing();
