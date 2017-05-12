use strict;
use warnings;
use Test::More;
use Test::Refcount;
use Test::Fatal;
use Test::Future;

use Future::Utils;
use IO::Async::Loop;
use Net::Async::AMQP::ConnectionManager;

plan skip_all => 'set NET_ASYNC_AMQP_HOST/USER/PASS/VHOST env vars to test' unless exists $ENV{NET_ASYNC_AMQP_HOST};

# Override this to split into smaller frames
{
	no warnings 'redefine';
	*Net::Async::AMQP::MAX_FRAME_SIZE = sub() { 8192 };
}

my $loop = IO::Async::Loop->new;

# Set up a connection manager with our MQ server details
$loop->add(
	my $cm = Net::Async::AMQP::ConnectionManager->new
);
$cm->add(
	host  => $ENV{NET_ASYNC_AMQP_HOST},
	user  => $ENV{NET_ASYNC_AMQP_USER},
	pass  => $ENV{NET_ASYNC_AMQP_PASS},
	vhost => $ENV{NET_ASYNC_AMQP_VHOST},
	max_channels => 16,
);

{ # Exchange-to-exchange binding
	my $expected_payload = join '', 'aa0'..'zz9';
	$cm->request_channel(
		confirm_mode => 1,
	)->then(sub {
		my ($ch) = @_;
		my $delivery = $loop->new_future;
		note 'Declaring queue and two exchanges';
		Future->needs_all(
			$ch->queue_declare(
				queue => '',
			),
			$ch->exchange_declare(
				exchange => 'test_delivery',
				type     => 'fanout',
			),
		)->then(sub {
			my ($q) = @_;
			note 'Binding queue and exchanges';
			Future->needs_all(
				$q->bind_exchange(
					channel => $ch,
					exchange => 'test_delivery',
					routing_key => '#',
				),
			)
		})->then(sub {
			my ($q) = @_;
			note 'Starting queue consumer';
			$q->listen(
				channel => $ch,
			)
		})->then(sub {
			my ($q, $ctag) = @_;
			note 'ctag is ' . $ctag;
			$ch->bus->subscribe_to_event(
				message => sub {
					my ($ev, $type, $payload, $ctag) = @_;
					note "Message was received";
					$delivery->done($type => $payload);
				}
			);
			$ch->publish(
				exchange    => 'test_delivery',
				routing_key => 'xxx',
				type        => 'some_type',
				payload     => $expected_payload,
			)->transform(done => sub { $q })
		})->then(sub {
			my ($q) = @_;
			note 'Published message';
			Future->wait_any(
				$loop->timeout_future(after => 20),
				$delivery
			)
		})->then(sub {
			ok($delivery->is_ready, 'delivery ready');
			ok(!$delivery->failure, 'did not fail');
			is_deeply([ $delivery->get ], [ 'some_type' => $expected_payload ], 'had expected type and content');
			Future->wrap;
		})
	})->get
}

$cm->shutdown->get;

done_testing;

