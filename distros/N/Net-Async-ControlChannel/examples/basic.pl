#!/usr/bin/env perl
use strict;
use warnings;
use IO::Async::Loop;
use Net::Async::ControlChannel::Server;
use Net::Async::ControlChannel::Client;
use IO::Async::Timer::Periodic;

my $loop = IO::Async::Loop->new;
my $server = Net::Async::ControlChannel::Server->new(
	loop => $loop,
);
$server->subscribe_to_event(
	message => sub {
		my $ev = shift;
		my ($k, $v, $from) = @_;
		warn "Server: Had $k => $v from $from\n";
	},
	connect => sub {
		my $ev = shift;
		my ($remote) = @_;
		warn "Server: Client connects from $remote\n"
	},
	disconnect => sub {
		my $ev = shift;
		my ($remote) = @_;
		warn "Server: Client disconnect from $remote\n"
	}
);
{
	$loop->add(my $timer = IO::Async::Timer::Periodic->new(
		interval => 1,
		on_tick => sub {
			$server->dispatch('timer.tick' => time)
		}
	));
	$timer->start;
}
my $f = $server->start->then(sub {
	my $server = shift;
	my $port = $server->port;
	my $client = Net::Async::ControlChannel::Client->new(
		loop => $loop,
		host => $server->host,
		port => $server->port,
	);
	$client->subscribe_to_event(
		message => sub {
			my $ev = shift;
			my ($k, $v, $from) = @_;
			warn "Client: Had $k => $v\n";
			$client->dispatch('client.reply' => "$k:$v");
		}
	);
	$client->start->on_done(sub {
		my $client = shift;
		$client->dispatch('client.ready' => time);
	});
});
$loop->run;
warn "finished\n";

