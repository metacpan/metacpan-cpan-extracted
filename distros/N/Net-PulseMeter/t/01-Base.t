#!perl

use warnings;
use strict;
use lib 't/tlib';
use Test::More;
use MockedRedis;
use Net::PulseMeter::Sensor::Base;

subtest 'describe .name' => sub {
    my $base = Net::PulseMeter::Sensor::Base->new("foo");
    ok(
        $base->name eq "foo",
        "it returns sensor name"
    );
};

subtest 'describe .redis' => sub {
    my $redis = MockedRedis->new;
    Net::PulseMeter::Sensor::Base->redis($redis);

    my $base = Net::PulseMeter::Sensor::Base->new("foo");
    ok(
        ref($base->redis) eq 'MockedRedis',
        "it takes and returns redis instance"
    );
};


done_testing();
