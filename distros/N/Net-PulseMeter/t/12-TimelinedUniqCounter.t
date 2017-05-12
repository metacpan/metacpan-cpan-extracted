#!perl

use warnings;
use strict;
use lib 't/tlib';
use Test::More;
use Test::MockTime qw/set_fixed_time/;
use MockedRedis;
use Net::PulseMeter::Sensor::Base;
use Net::PulseMeter::Sensor::Timelined::UniqCounter;

set_fixed_time(time);
my $r = MockedRedis->new;
Net::PulseMeter::Sensor::Base->redis($r);
my $s = Net::PulseMeter::Sensor::Timelined::UniqCounter->new("foo");
$r->flushdb;

$s->event("foo");
$s->event("bar");
$s->event("foo");

my $key = $s->current_raw_data_key;
ok(
    $r->scard($key) == 2,
    "it counts uniq values"
);

done_testing();
