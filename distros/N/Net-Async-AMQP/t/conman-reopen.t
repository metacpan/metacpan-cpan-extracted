use strict;
use warnings;
use Test::More;
use Test::Fatal;
use Test::Future;

use Future::Utils qw(fmap0);
use IO::Async::Loop;
use Net::Async::AMQP::ConnectionManager;

plan skip_all => 'set NET_ASYNC_AMQP_HOST/USER/PASS/VHOST env vars to test' unless exists $ENV{NET_ASYNC_AMQP_HOST};

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
	max_channels => 1,
);

{
	like(exception {
		$cm->request_channel(
			confirm_mode => 1,
		)->then(sub {
			my ($ch) = @_;
			Future->needs_all(
				$ch->queue_declare(
					queue => '',
				),
				$ch->exchange_declare(
					exchange => 'test_channel_spam',
					type     => 'topic',
					auto_delete => 1,
				),
			)->then(sub {
				my ($q) = @_;
				$q->delete(
					channel => $ch
				)->then(sub {
					# This should fail and thus throw an exception on ->get
					$q->bind_exchange(
						channel => $ch,
						exchange => 'test_channel_spam',
						routing_key => 'abc'
					)
				})
			})
		})->get;
	}, qr/NOT_FOUND/, 'have channel exception when binding to deleted queue');
	is(exception {
		is(
			$cm->request_channel(
				confirm_mode => 1,
			)->get->id,
			1,
			'have channel 1'
		);
	}, undef, 'no exception when we reopen the channel');
}

$cm->shutdown->get;

done_testing;

