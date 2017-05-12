#!perl

use warnings;
use strict;
use lib 't/tlib';
use Test::More;
use Test::MockTime qw/set_fixed_time/;
use MockedRedis;
use Net::PulseMeter::Sensor::Base;
use Net::PulseMeter::Sensor::Timelined::Indicator;

set_fixed_time(time);
my $r = MockedRedis->new;
Net::PulseMeter::Sensor::Base->redis($r);
my $s = Net::PulseMeter::Sensor::Timelined::Indicator->new("foo");
$r->flushdb;

$s->event(1);
$s->event(2);

my $key = $s->current_raw_data_key;
ok(
    $r->get($key) == 2,
    "it saves last registered value per interval"
);

done_testing();
