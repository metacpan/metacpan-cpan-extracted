#!/usr/bin/env perl 
use strict;
use warnings;
use Future::Utils;
use IO::Async::Loop;
use Net::Async::AMQP::ConnectionManager;

my $loop = IO::Async::Loop->new;

# Set up a connection manager with our MQ server details
my $cm = Net::Async::AMQP::ConnectionManager->new;
$loop->add($cm);
$cm->add(
  host  => 'localhost',
  user  => 'guest',
  pass  => 'guest',
  vhost => '/',
);

my @seen;
(Future::Utils::fmap_void {
	Future->needs_all(
		$cm->request_channel->then(sub {
			my $ch = shift;
			warn "Have channel " . $ch->id . " on " . $ch->amqp . "\n";
			$ch->exchange_declare(
				exchange => 'test_exchange',
				type     => 'fanout',
			)
		})->on_done(sub { warn "Declared exchange\n" }),
		$cm->request_channel->then(sub {
			my $ch = shift;
			warn "Have channel " . $ch->id . " on " . $ch->amqp . "\n";
			$ch->queue_declare(
				queue    => 'test_queue',
			)
		})->on_done(sub { warn "Declared queue\n" }),
	)->then(sub {
		my ($ex, $q) = @_;
		warn "Exchange $ex, queue $q\n";
		$cm->request_channel->then(sub {
			my $ch = shift;
			warn "Have channel " . $ch->id . " on " . $ch->amqp . "\n";
			$q->bind_exchange(
				exchange    => 'test_exchange',
				routing_key => 'somekey',
			)
		})->on_done(sub { warn "Bound\n" }),
	})
} foreach => [1..8], concurrent => 2)->then(sub {
	$cm->shutdown;
})->get;

