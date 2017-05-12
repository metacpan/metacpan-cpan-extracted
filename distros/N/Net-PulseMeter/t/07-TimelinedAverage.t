#!perl

use warnings;
use strict;
use lib 't/tlib';
use Test::More;
use Test::MockTime qw/set_fixed_time/;
use MockedRedis;
use Net::PulseMeter::Sensor::Base;
use Net::PulseMeter::Sensor::Timelined::Average;

set_fixed_time(time);
my $r = MockedRedis->new;
Net::PulseMeter::Sensor::Base->redis($r);
my $s = Net::PulseMeter::Sensor::Timelined::Average->new("foo");
$r->flushdb;

$s->event(1);
$s->event(2);

my $key = $s->current_raw_data_key;
ok(
    $r->hget($key, "sum") == 3,
    "it saves events sum to interval"
);
ok(
    $r->hget($key, "count") == 2,
    "it saves events count to interval"
);


done_testing();
