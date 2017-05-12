#!perl

use warnings;
use strict;
use lib 't/tlib';
use Test::More;
use Test::MockTime qw/set_fixed_time/;
use MockedRedis;
use Net::PulseMeter::Sensor::Base;
use Net::PulseMeter::Sensor::Timeline;

my $params = {
    raw_data_ttl => 1000,
    interval => 100
};

set_fixed_time(time);
my $r = MockedRedis->new;
Net::PulseMeter::Sensor::Base->redis($r);

my $s = Net::PulseMeter::Sensor::Timeline->new("foo", %$params);

for ('raw_data_ttl', 'interval') {
    my $accessor = $_;
    subtest "describe .$accessor" => sub {
        ok(
            $s->$accessor == $params->{$accessor},
            "it returns $accessor passed to constructor"
        );
        ok(
            Net::PulseMeter::Sensor::Timeline::DEFAULTS->{$accessor}
            ==
            Net::PulseMeter::Sensor::Timeline->new("foo")->$accessor,
            "it takes default value unless specified"
        );
    };
}

subtest "describe .raw_data_key" => sub {
    ok(
        $s->raw_data_key(1) eq "pulse_meter:raw:foo:1",
        "it composes raw_data_key of name and interval id"
    );
};

subtest "describe .get_interval_id" => sub {
    ok(
        $s->get_interval_id(110) == 100,
        "it returns start of interval"
    );

};

subtest "describe .current_interval_id" => sub {
    ok(
        $s->current_interval_id == $s->get_interval_id(time),
        "it returns start of current interval"
    );
};

subtest "describe .current_raw_data_key" => sub {
    ok(
        $s->current_raw_data_key
        eq
        "pulse_meter:raw:foo:".$s->current_interval_id,
        "it returns raw_data_key for current interval"
    );
};

subtest "describe .event" => sub {
    $r->flushdb;
    $s->event(100);
    ok(
        $r->get($s->current_raw_data_key) == 100,
        "it writes data to current raw interval"
    );
    ok(
        $r->ttl($s->current_raw_data_key) == $s->raw_data_ttl,
        "it sets expiration time for raw data"
    );
};

done_testing();
