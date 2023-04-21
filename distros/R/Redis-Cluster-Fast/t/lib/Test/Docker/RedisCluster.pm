package Test::Docker::RedisCluster;
use strict;
use warnings FATAL => 'all';

use Exporter qw/import/;
use IO::CaptureOutput qw/capture_exec/;
use Redis::Cluster::Fast;
use Scope::Guard;
use Sub::Retry;

our @EXPORT_OK = qw/get_startup_nodes/;

use constant {
    REDIS_CLUSTER_INITIAL_PORT => 9000,
    REDIS_CLUSTER_PORTS => [ 9000, 9001, 9002, 9003, 9004, 9005 ],
    REDIS_VERSION => '6.0.5',
    TEST_DOCKER_CONTAINER_NAME => 'test_for_perl_redis_cluster_fast',
};

require Test::More;
Test::More::plan skip_all =>
    'Skip tests using local Docker / Redis Cluster because AUTHOR_TESTING is not set' unless $ENV{AUTHOR_TESTING};

my $pid = $$;

sub _debug_warn {
    my $msg = shift;
    chomp $msg;
    if ($ENV{DEBUG_TEST_DOCKER_IMAGE}) {
        warn sprintf("[%s] %s", __PACKAGE__, $msg);
    }
}

sub _capture_exec {
    _debug_warn(join(' ', @_));
    capture_exec(@_);
}

sub _skip_tests {
    my $string = shift;
    chomp $string;
    my $message = join " ",
        "Failed to create a docker container.",
        "You can set a TEST_REDIS_CLUSTER_STARTUP_NODES environment to specify redis cluster nodes manually.",
        "(e.g. TEST_REDIS_CLUSTER_STARTUP_NODES=localhost:9000,localhost:9001,localhost:9002 )";
    Test::More::plan skip_all =>
        sprintf "[%s] %s ERR: %s", __PACKAGE__, $message, $string;
}

sub _get_container_ports {
    my $ports = REDIS_CLUSTER_PORTS;
    [ map { "$_:$_" } @$ports ];
}

sub _start_redis_cluster {
    my $initial_port = "INITIAL_PORT=" . REDIS_CLUSTER_INITIAL_PORT;

    my $container_ports = _get_container_ports;
    my @ports = map { ('-p', $_) } @$container_ports;

    my $image_tag = "grokzen/redis-cluster:" . REDIS_VERSION;

    my ($container_id, $stderr, $exit_code);
    retry(2, 0,
        sub {
            ($container_id, $stderr, $exit_code) = _capture_exec(
                qw/docker run -e BIND_ADDRESS=0.0.0.0 -d -t/,
                '--name', TEST_DOCKER_CONTAINER_NAME,
                '-e', $initial_port,
                @ports,
                $image_tag,
            );
            chomp $container_id;
        },
        sub {
            if ($stderr =~ /is already in use by container "([a-z|0-9]*)"./) {
                _capture_exec(qw/docker kill/, $1);
                _capture_exec(qw/docker rm/, $1);
                return 1;
            }
            if ($stderr) {
                _skip_tests($stderr);
                return 1;
            }
            return 0;
        }
    );

    _skip_tests("container_id undefined")
        unless defined $container_id;
    return $container_id;
}

sub get_startup_nodes {
    if (my $nodes = $ENV{TEST_REDIS_CLUSTER_STARTUP_NODES}) {
        return [ split(/,/, $nodes) ];
    } else {
        my $ports = REDIS_CLUSTER_PORTS;
        return [ map { "localhost:$_" } @$ports ];
    }
}

my $guard;
unless ($ENV{TEST_REDIS_CLUSTER_STARTUP_NODES}) {
    my $running_container_id = _start_redis_cluster;

    my $redis;
    retry(100, 0.2, sub {
        $redis = Redis::Cluster::Fast->new(
            startup_nodes => get_startup_nodes,
        );
    }, sub {
        my $err = $@;
        return 1 if $err;

        eval {
            my $info = $redis->cluster_info();
            return 0 if $info =~ /^cluster_state:ok/;
        };
        1;
    });

    $guard = Scope::Guard->new(sub {
        if ($pid == $$ && !$ENV{TEST_REDIS_CLUSTER_STARTUP_NODES}) {
            _capture_exec('docker', $_, $running_container_id)
                for qw/kill rm/;
        }
    });

    # avoid CLUSTERDOWN
    sleep 2;
}

END { undef $guard };
1;