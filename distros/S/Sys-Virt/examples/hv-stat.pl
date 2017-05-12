#!/usr/bin/perl

use strict;
use warnings;

use Sys::Virt;
use Sys::Virt::Domain;
use Time::HiRes qw(time);

my $addr = @ARGV ? shift @ARGV : "";

my $hv = Sys::Virt->new(address => $addr, readonly => 1);

my $interval = @ARGV ? shift @ARGV : 1;
my $iterations = @ARGV ? shift @ARGV : 1;

my %states = (
  &Sys::Virt::Domain::STATE_NOSTATE => "nostate",
  &Sys::Virt::Domain::STATE_RUNNING => "running",
  &Sys::Virt::Domain::STATE_BLOCKED => "blocked",
  &Sys::Virt::Domain::STATE_PAUSED => "paused",
  &Sys::Virt::Domain::STATE_SHUTDOWN => "shutdown",
  &Sys::Virt::Domain::STATE_SHUTOFF => "shutoff",
  &Sys::Virt::Domain::STATE_CRASHED => "crashed",
  &Sys::Virt::Domain::STATE_RUNNING => "running",

);

my %cpuTime;
my $sample;
for (my $i = 0 ; $i < $iterations ; $i++) {
    sleep $interval if $i;

    my $now = time;

    my @domains = $hv->list_domains;

    my @stats;
    if (!($i % 10)) {
      printf " %-4s %-15s %-8s %-6s %-4s\n", "ID", "Name", "State", "CPU", "Memory";
    }
    foreach my $domain (sort { $a->get_id <=> $b->get_id } @domains) {
	my $uuid = $domain->get_uuid_string;

	my $info = $domain->get_info;

	my $cpudelta = exists $cpuTime{$uuid} ? $info->{cpuTime} - $cpuTime{$uuid} : 0;
	my $timedelta = defined $sample ? ($now - $sample)*1000*1000*1000 :0;

	$cpuTime{$uuid} = $info->{cpuTime};

	my $util = $timedelta > 0 ? $cpudelta * 100 / $timedelta : 0;

	printf " %-4d %-15s %-8s %-6s %-4dMB \n", $domain->get_id, $domain->get_name, $states{$info->{state}}, (sprintf "%d%%",$util), ($info->{memory}/1024);
    }

    $sample = $now;

    print "\n";
}
