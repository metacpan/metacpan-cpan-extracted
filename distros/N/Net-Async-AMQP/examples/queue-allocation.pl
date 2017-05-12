#!/usr/bin/env perl
use strict;
use warnings;

use Net::Async::AMQP::ConnectionManager;
use IO::Async::Loop;
use Future::Utils qw(fmap0);
use Variable::Disposition qw(retain_future);

my $loop = IO::Async::Loop->new;
$loop->add(
	my $mq = Net::Async::AMQP::ConnectionManager->new
);
my $true = Net::AMQP::Value->true;
$mq->add(
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
);
$mq->request_channel->then(sub {
	my ($ch) = shift;
	$ch->queue_declare(
		queue => '',
	)->then(sub {
		my ($q) = @_;
		(fmap0 {
			$ch->publish(
				exchange => '',
				routing_key => $q->queue_name,
				type => shift,
			)
		} foreach => [1..1000], concurrent => 4)->then(sub {
			Future->needs_all(
				map {
					my $id = $_;
					$mq->request_channel(
						prefetch_count => 2
					)->then(sub {
						my ($ch) = shift;
						$q->consumer(
							channel => $ch,
							ack => 1,
							on_message => sub {
								my %args = @_;
								print "$id Message $args{type} received\n";
								retain_future(
									$loop->delay_future(
										after => 0.5
									)->then(sub {
										$ch->reject(
											delivery_tag => $args{delivery_tag},
											requeue => 1
										);
									})
								)
							}
						)
					})
				} 1..10
			)
		})
	})
})->get;
$loop->run;

