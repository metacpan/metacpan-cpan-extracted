package Test::RedisClusterImage;
use warnings;
use strict;
use Mouse;
use Test::Docker::Image::Utility qw(docker);

extends 'Test::Docker::Image';

my $pid = $$;

sub DESTROY {
    my $self = shift;
    if ($pid == $$ && !$ENV{TEST_REDIS_CLUSTER_STARTUP_NODES}) {
        docker($_, $self->container_id)
            for qw/kill rm/;
    }
}

no Mouse;
1;
