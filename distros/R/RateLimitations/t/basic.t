use strict;
use Test::Most;
use Test::MockTime qw(set_relative_time restore_time);
use Test::FailWarnings;
use RateLimitations
    qw(rate_limits_for_service within_rate_limits verify_rate_limitations_config rate_limited_services all_service_consumers flush_all_service_consumers);

my $redis_server;
my $prev_redis = $ENV{REDIS_CACHE_SERVER};

eval {
    require Test::RedisServer;
    $redis_server = Test::RedisServer->new(conf => {port => 9966});
    $ENV{REDIS_CACHE_SERVER} = $redis_server->connect_info;
};

subtest 'verify_rate_limitations_config' => sub {
    ok(verify_rate_limitations_config(), 'Included rate limitations are ok');
};

my ($service, $consumer) = ('rl_internal_testing', 'CR001');
my $consume = {
    service  => $service,
    consumer => $consumer,
};

subtest 'rate_limited_services' => sub {
    ok((grep { $_ eq $service } rate_limited_services()), 'The test service is defined');
};

subtest 'rate_limits_for_service' => sub {
    throws_ok { rate_limits_for_service() } qr/Unknown service/, 'Must supply a known service name';
    eq_or_diff([rate_limits_for_service($service)], [[10, 2], [300, 6]], 'Got expected rates for our test service');
};

subtest 'all service consumers' => sub {
    plan skip_all => 'Test::RedisServer is required for this test' unless $redis_server;
    lives_ok { flush_all_service_consumers() } 'flushing does not die';
    eq_or_diff(all_service_consumers(), {}, 'leaving an empty list');
    my $result = {$service => [$consumer]};
    ok within_rate_limits($consume), 'Add a consumer';
    eq_or_diff(all_service_consumers(), $result, 'added consumer fills out our result');
    ok within_rate_limits($consume), 'Reuse the consumer';
    eq_or_diff(all_service_consumers(), $result, 'result is unchanged');
    cmp_ok flush_all_service_consumers(), '==', 1, 'flushed the single consumer';
};

subtest 'within_rate_limits' => sub {
    plan skip_all => 'Test::RedisServer is required for this test' unless $redis_server;
    note 'This depends on the form of the rate_limits_for_service tested above';
    foreach my $count (1 .. 2) {
        ok within_rate_limits($consume), 'Attempt ' . $count . ' ok';
    }
    ok !within_rate_limits($consume), 'Attempt 3 fails';
    set_relative_time(10);
    note 'Moved to the end of our limits we should be able to go again.';
    foreach my $count (1 .. 2) {
        ok within_rate_limits($consume), 'Attempt ' . $count . ' ok';
    }
    ok !within_rate_limits($consume), 'Attempt 3 fails';
    set_relative_time(20);
    note 'Moved to the end again, but now slower limit takes over (includes failures)';
    ok !within_rate_limits($consume), '... so it fails';
    set_relative_time(300);
    note 'Moved past the end of the longer slower limit';
    ok within_rate_limits($consume),  '... so we can start up again';
    ok within_rate_limits($consume),  '... but only a couple times';
    ok !within_rate_limits($consume), '... until we fail again';

    restore_time();
};

$ENV{REDIS_CACHE_SERVER} = $prev_redis;
done_testing;
