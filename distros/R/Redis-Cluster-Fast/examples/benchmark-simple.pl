use strict;
use warnings FATAL => 'all';
use lib './xt/lib';
use Benchmark;
use Redis::Cluster::Fast;
use Redis::ClusterRider;
use Test::More; # for Test::RedisCluster
use Test::Docker::RedisCluster qw/get_startup_nodes/;

print "Redis::Cluster::Fast is " . $Redis::Cluster::Fast::VERSION . "\n";
print "Redis::ClusterRider is " . $Redis::ClusterRider::VERSION . "\n";

my $nodes = get_startup_nodes;

my $xs = Redis::Cluster::Fast->new(
    startup_nodes => $nodes,
);

my $pp = Redis::ClusterRider->new(
    startup_nodes => $nodes,
);

my $cc = 0;
my $dd = 0;

my $loop = 100000;
print "### mset ###\n";
Benchmark::cmpthese($loop, {
    "Redis::ClusterRider" => sub {
        $cc++;
        $pp->mset("{pp$cc}atest", $cc, "{pp$cc}btest", $cc, "{pp$cc}ctest", $cc);
    },
    "Redis::Cluster::Fast" => sub {
        $dd++;
        $xs->mset("{xs$dd}atest", $dd, "{xs$dd}btest", $dd, "{xs$dd}ctest", $dd);
    },
});

$cc = 0;
$dd = 0;

print "### mget ###\n";
Benchmark::cmpthese($loop, {
    "Redis::ClusterRider" => sub {
        $cc++;
        $pp->mget("{pp$cc}atest", "{pp$cc}btest", "{pp$cc}ctest");
    },
    "Redis::Cluster::Fast" => sub {
        $dd++;
        $xs->mget("{xs$dd}atest", "{xs$dd}btest", "{xs$dd}ctest");
    },
});

print "### incr ###\n";
Benchmark::cmpthese(-2, {
    "Redis::ClusterRider" => sub {
        $pp->incr("incr_1");
    },
    "Redis::Cluster::Fast" => sub {
        $xs->incr("incr_2");
    },
});

print "### new and ping ###\n";
Benchmark::cmpthese(-2, {
    "Redis::ClusterRider" => sub {
        my $tmp = Redis::ClusterRider->new(
            startup_nodes => $nodes,
        );
        $tmp->ping;
    },
    "Redis::Cluster::Fast" => sub {
        my $tmp = Redis::Cluster::Fast->new(
            startup_nodes => $nodes,
        );
        $tmp->ping;
    },
});

is 1, 1;
done_testing;
__END__
% AUTHOR_TESTING=1 perl ./examples/benchmark-simple.pl
Redis::Cluster::Fast is 0.084
Redis::ClusterRider is 0.26
### mset ###
                        Rate  Redis::ClusterRider Redis::Cluster::Fast
Redis::ClusterRider  13245/s                   --                 -34%
Redis::Cluster::Fast 20080/s                  52%                   --
### mget ###
                        Rate  Redis::ClusterRider Redis::Cluster::Fast
Redis::ClusterRider  14641/s                   --                 -40%
Redis::Cluster::Fast 24510/s                  67%                   --
### incr ###
                        Rate  Redis::ClusterRider Redis::Cluster::Fast
Redis::ClusterRider  18367/s                   --                 -44%
Redis::Cluster::Fast 32879/s                  79%                   --
### new and ping ###
                       Rate  Redis::ClusterRider Redis::Cluster::Fast
Redis::ClusterRider   146/s                   --                 -96%
Redis::Cluster::Fast 3941/s                2598%                   --
ok 1
1..1
