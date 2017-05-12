#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 3;
use Test::MockModule;

my $redis_m = Test::MockModule->new("Redis");
$redis_m->mock("new", sub {
	my $class = shift;
	my $self = {@_};
	return bless($self, $class);
});

BEGIN {
    use_ok('ResourcePool::Resource::Redis')
        or BAIL_OUT("Unable to import ResourcePool::Resource::Redis");
};

{
    my $redis_server = "127.0.0.1:6379";
    my $resource = ResourcePool::Resource::Redis->new(
        'server' => $redis_server,
    );
    isa_ok($resource, "ResourcePool::Resource::Redis");
    my $redis = $resource->get_plain_resource();
    isa_ok($redis, "Redis");
}

