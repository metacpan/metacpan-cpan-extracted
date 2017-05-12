#!/usr/bin/env perl
use strict;
use warnings;

use Net::Async::AMQP;
use IO::Async::Loop;
my $loop = IO::Async::Loop->new;
$loop->add(
	my $mq = Net::Async::AMQP->new(
	)
);
my $true = Net::AMQP::Value->true;
$mq->connect(
	host  => $ENV{NET_ASYNC_AMQP_HOST} // 'localhost',
	user  => 'guest',
	pass  => 'guest',
	vhost => '/',
	client_properties => {
		capabilities => {
			'consumer_cancel_notify' => $true,
			'connection.blocked'     => $true,
		},
	},
)->then(sub {
	shift->open_channel
})->then(sub {
	my ($ch) = shift;
	my $exch_name = 'some_exchange';
	Future->needs_all(
		$ch->queue_declare(
			queue => 'some_queue',
		),
		$ch->exchange_declare(
			type => 'fanout',
			exchange => $exch_name,
			autodelete => 1,
		)
	)->then(sub {
		my ($q) = @_;
		$ch->bus->subscribe_to_event(
			message => sub {
				my ($ev, @details) = @_;
				print "Message received: @details\n";
			}
		);
		$q->bind_exchange(
			channel => $ch,
			exchange => $exch_name
		)->then(sub {
			$q->listen(
				channel => $ch,
				ack =>1,
			)
		})->then(sub {
			my ($q, $ctag) = @_;
			print "Queue $q has ctag $ctag\n";
			$ch->publish(
				exchange => $exch_name,
				routing_key => 'some.rkey.here',
				type => 'some_type',
			)
		})
	})
})->get;

$loop->run;

