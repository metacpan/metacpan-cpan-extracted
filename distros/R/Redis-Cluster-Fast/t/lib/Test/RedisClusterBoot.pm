package Test::RedisClusterBoot;
use warnings;
use strict;
use Mouse;
use namespace::autoclean;

use IO::CaptureOutput qw/capture_exec/;
use Sub::Retry;
use Test::RedisCluster qw/REDIS_CLUSTER_INITIAL_PORT/;

extends 'Test::Docker::Image::Boot';

use constant TEST_DOCKER_CONTAINER_NAME => 'test_for_perl_redis_cluster_fast';

sub _die {
    my $string = shift;
    chomp $string;
    die sprintf "[%s] %s", __PACKAGE__, $string;
}

sub docker_run {
    my ($self, $ports, $image_tag) = @_;

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
            _die("unknown error $stderr") if $stderr;
            return 0;
        }
    );

    _die("cannot run test docker container")
        unless defined $container_id;
    return $container_id;
}

1;
