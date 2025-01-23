use strict;
use warnings FATAL => 'all';
use lib './xt/lib';

BEGIN {
    use Test::More;
    plan skip_all =>
        'Skip tests using local Docker / Redis Cluster / Valgrind because AUTHOR_TESTING is not set' unless $ENV{AUTHOR_TESTING};
};

eval {
    use Test::Valgrind (extra_supps => [ './xt/lib/memcheck-extra.supp' ]);
};
plan skip_all => 'Test::Valgrind is required to test your distribution with valgrind' if $@;

use Test::Docker::RedisCluster qw/get_startup_nodes/; # Valgrind check this module too
use Redis::Cluster::Fast;

Redis::Cluster::Fast::srandom(1111);

my $redis = Redis::Cluster::Fast->new(
    startup_nodes => get_startup_nodes,
    connect_timeout => 0.5,
    command_timeout => 0.5,
    max_retry_count => 10,
);

$redis->del('valgrind');
$redis->set('valgrind', 123);

eval {
    # wide character
    $redis->set('euro', "\x{20ac}");
};

my $pid = fork;
if ($pid == 0) {
    # child
    $redis->incr('valgrind');
    $redis->cluster_info;
    exit 0;
} else {
    # parent
    $redis->incr('valgrind');
    $redis->cluster_info;
    waitpid($pid, 0);
}

$redis->get('valgrind');
$redis->cluster_info;

eval {
    Redis::Cluster::Fast->new(
        startup_nodes => [
            'localhost:1111corrupted'
        ],
    );
};

{
    my $redis_2 = Redis::Cluster::Fast->new(
        startup_nodes => get_startup_nodes,
    );
    $redis_2->ping;

    my $pid = fork;
    if ($pid == 0) {
        # child
        # Do nothing
        # call event_reinit at DESTROY
        exit 0;
    } else {
        # parent
        # Do nothing
        waitpid($pid, 0);
    }
    $redis_2->ping;
}

{
    my $redis = Redis::Cluster::Fast->new(
        startup_nodes => get_startup_nodes,
    );
    $redis->del('pipeline');

    $redis->set('pipeline', 12345, sub {
        my ($result, $error) = @_;
    });
    $redis->get('pipeline', sub {
        my ($result, $error) = @_;
    });
    $redis->get('pipeline', sub {
        my ($result, $error) = @_;
    });
    ok $redis->wait_all_responses;
    is $redis->wait_all_responses, 0;
}

{
    my $redis = Redis::Cluster::Fast->new(
        startup_nodes => get_startup_nodes,
    );
    $redis->del('pipeline');

    $redis->set('pipeline', 12345, sub {
        my ($result, $error) = @_;
    });
    $redis->get('pipeline', sub {
        my ($result, $error) = @_;
    });
    $redis->get('pipeline', sub {
        my ($result, $error) = @_;
    });
    ok $redis->wait_one_response;
    is $redis->wait_one_response, 0;
}

done_testing;
