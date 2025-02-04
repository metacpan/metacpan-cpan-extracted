use strict;
use warnings FATAL => 'all';
use feature qw/say/;
use lib ".";
use lib "./_build/lib";
use lib "./blib/arch";
use lib "./blib/lib";
use lib './xt/lib';

use Time::HiRes qw/gettimeofday tv_interval/;
use Redis::Cluster::Fast;
use Redis::ClusterRider;

my $nodes_str = $ENV{REDIS_NODES};
my $nodes = [
    split(/,/, $nodes_str)
];

my $xs = Redis::Cluster::Fast->new(
    startup_nodes => $nodes,
    route_use_slots => 1,
);

my $pp = Redis::ClusterRider->new(
    startup_nodes => $nodes,
);

my $loop = 100000;

######
# set
######
sleep 1;
for my $num (1 .. $loop) {
    my $start_time = [ gettimeofday ];

    $xs->set('1' . $num, 123);

    my $elapsed_time = tv_interval($start_time);
    printf "set_xs,%.10f\n", $elapsed_time * 1000;
}
sleep 1;
for my $num (1 .. $loop) {
    my $start_time = [ gettimeofday ];

    $xs->set('2' . $num, 123, sub {});
    $xs->run_event_loop;

    my $elapsed_time = tv_interval($start_time);
    printf "set_xs_pipeline,%.10f\n", $elapsed_time * 1000;
}
sleep 1;
for my $num (1 .. $loop) {
    my $start_time = [ gettimeofday ];

    $xs->set('3' . $num, 123, sub {});
    $xs->run_event_loop if $num % 100 == 0;

    my $elapsed_time = tv_interval($start_time);
    printf "set_xs_pipeline_batched_100,%.10f\n", $elapsed_time * 1000;
}
sleep 1;
for my $num (1 .. $loop) {
    my $start_time = [ gettimeofday ];

    $pp->set('4' . $num, 123);

    my $elapsed_time = tv_interval($start_time);
    printf "set_pp,%.10f\n", $elapsed_time * 1000;
}

######
# get
######
sleep 1;
for my $num (1 .. $loop) {
    my $start_time = [ gettimeofday ];

    $xs->get('1' . $num);

    my $elapsed_time = tv_interval($start_time);
    printf "get_xs,%.10f\n", $elapsed_time * 1000;
}
sleep 1;
for my $num (1 .. $loop) {
    my $start_time = [ gettimeofday ];

    $xs->get('2' . $num, sub {});
    $xs->run_event_loop;

    my $elapsed_time = tv_interval($start_time);
    printf "get_xs_pipeline,%.10f\n", $elapsed_time * 1000;
}
sleep 1;
for my $num (1 .. $loop) {
    my $start_time = [ gettimeofday ];

    $xs->get('3' . $num, sub {});
    $xs->run_event_loop if $num % 100 == 0;

    my $elapsed_time = tv_interval($start_time);
    printf "get_xs_pipeline_batched_100,%.10f\n", $elapsed_time * 1000;
}
sleep 1;
for my $num (1 .. $loop) {
    my $start_time = [ gettimeofday ];

    $pp->get('4' . $num);

    my $elapsed_time = tv_interval($start_time);
    printf "get_pp,%.10f\n", $elapsed_time * 1000;
}

__END__