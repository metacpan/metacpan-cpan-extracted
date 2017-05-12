#!/usr/bin/env perl
use strict;
use warnings;
use feature qw(say);

use IO::Async::Loop;
use Net::Async::Statsd::Server;
use List::Util qw(sum min max);

my $loop = IO::Async::Loop->new;
my $srv = Net::Async::Statsd::Server->new(
	port => 8125,
);
$loop->add($srv);
$srv->listening->get;
say "Server port is " . $srv->port;

my %timing;
my %count;
for(qw(count gauge timing)) {
	my $type = $_;
	$srv->bus->subscribe_to_event(
		$type => sub {
			my ($ev, $k, $v) = @_;
			if($type eq 'count') {
				++$count{$k};
				say "$type - $k = " . $count{$k};
			} elsif($type eq 'timing') {
				unshift @{$timing{$type} ||= []}, $v;
				splice @{$timing{$type}}, 50;
				printf "%s - %s = %s (%d/%d/%d)\n", $type, $k, $v, min(@{$timing{$type}}), sum(@{$timing{$type}})/@{$timing{$type}}, max(@{$timing{$type}});
			} else {
				say "$type - $k = $v";
			}
		}
	);
}
$loop->run;

