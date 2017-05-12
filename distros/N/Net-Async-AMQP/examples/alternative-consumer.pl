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
	$ch->queue_declare(
		queue => '',
	)->then(sub {
		my ($q) = @_;
		my $msg = $loop->new_future;
		$q->consumer(
			channel => $ch,
			ack => 0,
			on_message => sub {
				my ($ev, @details) = @_;
				print "Message received: @details\n";
				$msg->done;
			}
		)->then(sub {
			my ($q, $ctag) = @_;
			print "Queue $q has ctag $ctag\n";
			$ch->publish(
				exchange => '',
				routing_key => $q->queue_name,
				type => 'some_type',
			)
		})->then(sub {
			Future->wait_any(
				$loop->timeout_future(after => 10),
				$msg
			)
		})
	})
})->get;


