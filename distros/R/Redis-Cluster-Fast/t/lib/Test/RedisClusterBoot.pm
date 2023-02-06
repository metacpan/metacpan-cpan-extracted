package Test::RedisClusterBoot;
use warnings;
use strict;
use Mouse;

use IO::CaptureOutput qw/capture_exec/;
use Sub::Retry;
use Test::RedisCluster qw/REDIS_CLUSTER_INITIAL_PORT/;

extends 'Test::Docker::Image::Boot';

use constant TEST_DOCKER_CONTAINER_NAME => 'test_for_perl_redis_cluster_fast';

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

sub docker_run {
    my ($self, $ports, $image_tag) = @_;
    require Test::More;

    my ($container_id, $stderr, $exit_code);
    retry(2, 0,
        sub {
            my $initial_port = REDIS_CLUSTER_INITIAL_PORT;
            ($container_id, $stderr, $exit_code) =
                capture_exec(qw/docker run -e BIND_ADDRESS=0.0.0.0 -d -t/,
                    '--name', TEST_DOCKER_CONTAINER_NAME,
                    '-e', "INITIAL_PORT=$initial_port",
                    @$ports, $image_tag);
            chomp $container_id;
        },
        sub {
            if ($stderr =~ /is already in use by container "([a-z|0-9]*)"./) {
                capture_exec(qw/docker kill/, $1);
                capture_exec(qw/docker rm/, $1);
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

no Mouse;
1;
