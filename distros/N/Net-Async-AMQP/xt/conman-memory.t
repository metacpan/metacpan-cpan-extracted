use strict;
use warnings;
use Test::More;
use Test::Refcount;

use Future::Utils;
use IO::Async::Loop;
use Net::Async::AMQP::ConnectionManager;

BEGIN {
	plan skip_all => 'set NET_ASYNC_AMQP_HOST/USER/PASS/VHOST env vars to test' unless exists $ENV{NET_ASYNC_AMQP_HOST};

	eval {
		require Test::MemoryGrowth;
		Test::MemoryGrowth->import;
		1
	} or plan skip_all => 'needs Test::MemoryGrowth installed'
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
);

note 'test for memory leak';
no_growth {
	$cm->request_channel->then(sub {
		my $ch = shift;
		fail("invalid channel") unless $ch->id;
		Future->needs_all(
			$ch->queue_declare(
				queue => '',
			),
			$ch->exchange_declare(
				exchange => 'test_exchange',
				type     => 'fanout',
			),
		)->then(sub {
			my ($q) = @_;
			$q->bind_exchange(
				channel => $ch,
				exchange => 'test_exchange',
				routing_key => '*',
			)->then(sub {
				$q->listen(
					channel => $ch,
				)
			})->then(sub {
				my ($q, $ctag) = @_;
				$q->cancel(consumer_tag => $ctag)
			})
		}),
	})->get
} 'assign and release channels without leaking memory';

$cm->shutdown->get;

done_testing;

