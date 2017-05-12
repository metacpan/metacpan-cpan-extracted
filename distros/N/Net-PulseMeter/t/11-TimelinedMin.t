#!perl

use warnings;
use strict;
use lib 't/tlib';
use Test::More;
use Test::MockTime qw/set_fixed_time/;
use MockedRedis;
use Net::PulseMeter::Sensor::Base;
use Net::PulseMeter::Sensor::Timelined::Min;

set_fixed_time(time);
my $r = MockedRedis->new;
Net::PulseMeter::Sensor::Base->redis($r);
my $s = Net::PulseMeter::Sensor::Timelined::Min->new("foo");
$r->flushdb;

$s->event(1);
$s->event(2);
$s->event(1);

my $key = $s->current_raw_data_key;
ok(
    [$r->zrange($key, 0, -1, "WITHSCORES")]->[1] == 1,
    "it saves min to interval"
);

done_testing();
