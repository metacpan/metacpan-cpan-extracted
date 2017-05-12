#!perl

use warnings;
use strict;
use lib 't/tlib';
use Test::More;
use Test::MockTime qw/set_fixed_time/;
use MockedRedis;
use Net::PulseMeter::Sensor::Base;
use Net::PulseMeter::Sensor::Timelined::HashedIndicator;

set_fixed_time(time);
my $r = MockedRedis->new;
Net::PulseMeter::Sensor::Base->redis($r);
my $s = Net::PulseMeter::Sensor::Timelined::HashedIndicator->new("foo");
$r->flushdb;

$s->event({foo => 1, bar => 2});
$s->event({foo => 10});

my $key = $s->current_raw_data_key;
is_deeply(
    {$r->hgetall($key)},
    {foo => 10, bar => 2},
    "it last registered multiple values to interval"
);

done_testing();
