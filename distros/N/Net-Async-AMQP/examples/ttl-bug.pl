#!/usr/bin/env perl
use strict;
use warnings;

# TTL to set for the queue (seconds)
use constant QUEUE_TTL => 10;
# How long to wait before starting a consumer (seconds)
use constant CONSUMER_DELAY => 3;

use Net::Async::AMQP;
use IO::Async::Loop;

my $loop = IO::Async::Loop->new;
$loop->add(
	my $mq = Net::Async::AMQP->new(
	)
);
my $true = Net::AMQP::Value->true;
my %msg;
$mq->connect(
	host  => $ENV{NET_ASYNC_AMQP_HOST} // 'localhost',
	user  => 'guest',
	pass  => 'guest',
	vhost => '/',
)->then(sub {
	shift->open_channel
})->then(sub {
	my ($ch) = shift;
	$ch->queue_declare(
		queue => '',
		arguments => {
			'x-message-ttl' => QUEUE_TTL * 1000
		}
	)->then(sub {
		my ($q) = @_;
		$msg{no_consumer} = $loop->new_future;
		$ch->publish(
			exchange => '',
			routing_key => $q->queue_name,
			type => 'no_consumer',
		)->then(sub {
			$loop->delay_future(after => CONSUMER_DELAY)
		})->then(sub {
			$q->consumer(
				channel => $ch,
				ack => 0,
				on_message => sub {
					my ($ev, $type, %details) = @_;
					print "$type message received\n";
					$msg{$type}->done;
				}
			)
		})->then(sub {
			my ($q, $ctag) = @_;
			print "Queue $q has ctag $ctag\n";
			$msg{active_consumer} = $loop->new_future;
			$ch->publish(
				exchange => '',
				routing_key => $q->queue_name,
				type => 'active_consumer',
			)
		})->then(sub {
			Future->wait_any(
				$loop->timeout_future(after => 60),
				Future->needs_all(values %msg)
			)
		})
	})
})->get;


