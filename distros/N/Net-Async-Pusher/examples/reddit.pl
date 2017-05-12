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
	key => '50ed18dd967b455393ed'
)->then(sub {
	my ($conn) = @_;
	say "Connection established. Opening channel.";
	$conn->open_channel('askreddit')
})->then(sub {
	my ($ch) = @_;
	say "Subscribing to new story posts";
	$ch->subscribe('new-listing' => sub {
		my ($ev, $data) = @_;
		printf "[%s] %s\n", map $data->{$_}, qw(title url);
	});
})->get;
say "Subscribed and waiting for events...";
$loop->run;
$sub->()->get;

