#!/usr/bin/perl

use strict;
use warnings;

use Sys::Virt;
use Time::HiRes qw(time);

my $addr = @ARGV ? shift @ARGV : "";

my $hv = Sys::Virt->new(address => $addr, readonly => 1);

my $interval = @ARGV ? shift @ARGV : 1;
my $iterations = @ARGV ? shift @ARGV : 1;

my $nodeinfo = $hv->get_node_info();

my $ncpus = $nodeinfo->{cpus};

my @cpuTime;
my $then;

for (my $c = 0 ; $c < $ncpus ; $c++) {
    printf "CPU %3d ", $c;
}
print "\n";

for (my $i = 0 ; $i < $iterations ; $i++) {
    sleep $interval if $i;

    my $now = time;

    for (my $c = 0 ; $c < $ncpus ; $c++) {
	my $info = $hv->get_node_cpu_stats($c);

	my $used = $info->{kernel} + $info->{user};
	if (exists $cpuTime[$c]) {
	    my $cpudelta = $used - $cpuTime[$c];
	    my $timedelta = ($now - $then) * 1000*1000*1000;
	    my $util = $cpudelta * 100 / $timedelta;

	    printf "%03.02f%% ", $util;
	}
	$cpuTime[$c] = $used;
    }
    print "\n";

    $then = $now;
}

my ($totcpus, $onlinemask, $nonline) = $hv->get_node_cpu_map();

printf "CPUs total %d, online %d\n", $totcpus, $nonline;

my @bits = split(//, unpack("b*", $onlinemask));
for (my $i = 0 ; $i < $totcpus ; $i++) {
    printf "  %d: %d\n", $i, $bits[$i];
}
