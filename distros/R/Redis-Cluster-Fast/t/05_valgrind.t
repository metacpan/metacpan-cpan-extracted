use strict;
use warnings FATAL => 'all';
use lib './t/lib';

BEGIN {
    use Test::More;
    plan skip_all =>
        'Skip tests using local Docker / Redis Cluster / Valgrind because AUTOMATED_TESTING is not set' unless $ENV{AUTOMATED_TESTING};
};

eval {
    use Test::Valgrind (extra_supps => [ './t/lib/memcheck-extra.supp' ]);
};
plan skip_all => 'Test::Valgrind is required to test your distribution with valgrind' if $@;

use Test::Docker::RedisCluster qw/get_startup_nodes/; # Valgrind check this module too
use Redis::Cluster::Fast;

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

done_testing;
