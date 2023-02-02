package Test::RedisClusterImage;
use warnings;
use strict;
use Mouse;
use namespace::autoclean;
use Test::Docker::Image::Utility qw(docker);

extends 'Test::Docker::Image';

my $pid = $$;

sub DESTROY {
    my $self = shift;
    if ($pid == $$) {
        docker($_, $self->container_id)
            for qw/kill rm/;
    }
}

1;
