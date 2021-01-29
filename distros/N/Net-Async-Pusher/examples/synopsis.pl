#!/usr/bin/env perl
use strict;
use warnings;
use feature qw(say);
# For more details, enable this
# use Log::Any::Adapter qw(Stdout);
use IO::Async::Loop;
use Net::Async::Pusher;
my $loop = IO::Async::Loop->new;
$loop->add(
	my $pusher = Net::Async::Pusher->new
);
say "Connecting to pusher.com via websocket...";
my $sub = $pusher->connect(
	key => 'de504dc5763aeef9ff52'
)->then(sub {
	my ($conn) = @_;
	say "Connection established. Opening channel.";
	$conn->open_channel('live_trades')
})->then(sub {
	my ($ch) = @_;
	say "Have channel, setting up event handler for 'trade' event.";
	$ch->subscribe(trade => sub {
		my ($ev, $data) = @_;
		say "New trade - price " . $data->{price} . ", amount " . $data->{amount};
	});
})->get;
say "Subscribed and waiting for events...";
$loop->run;
$sub->()->get;
