use strict;
use warnings;
use Test::More;
use Test::Refcount;
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
	max_channels => 73,
);

{ # Exchange-to-exchange binding
	my $thing = 'aa00001';
	my $countdown = 1000;
	(fmap0 {
		my ($item) = @_;
		Future->wait_any(
			$loop->timeout_future(after => 5)->on_fail(sub {
				fail("handler for $item timed out");
			}),
			$cm->request_channel(
				confirm_mode => 1,
			)->then(sub {
				my ($ch) = @_;
				eval {
					$ch->bus->subscribe_to_event(
						close => sub {
							note "Channel closed - @_";
							eval { shift->unsubscribe; } # don't care if we weren't already subscribed
						}
					);
					my $delivery = $loop->new_future->set_label("delivery for $item");
					my @ev;
					my $rkey = ($thing++ . '-' . $item);
					Future->needs_all(
						$delivery,
						Future->needs_all(
							$ch->queue_declare(
								queue => '',
							),
							$ch->exchange_declare(
								exchange => 'test_channel_spam',
								type     => 'topic',
								auto_delete => 1,
							),
						)->set_label("wait for queue and exchange declare on $item")->then(sub {
							my ($q) = @_;
							my $expect_fail;
							my $f = Future->done;
							unless($item % 3) {
								$expect_fail = 1;
								$f = $q->delete(
									channel => $ch
								)->on_done(sub { pass('deleted ' . $q->queue_name); })
								 ->on_fail(sub { fail('could not delete ' . $q->queue_name); })
							} 
							Future->needs_all(
								$q->bind_exchange(
									channel => $ch,
									exchange => 'test_channel_spam',
									routing_key => $rkey,
								)->on_cancel(sub { note "$item bind exchange cancelled" })
								 ->on_fail(sub {
									ok($expect_fail, "$item expected this one to fail");
								})->on_done(sub {
									ok(!$expect_fail, "$item expected bind to succeed");
								}),
								$f
							)
						})->then(sub {
							my ($q) = @_;
							$q->listen(
								channel => $ch,
							)
						})->then(sub {
							my ($q, $ctag) = @_;
							note $item . ' ctag is ' . $ctag;
							my $id = $ch->id;
							$ch->bus->subscribe_to_event(
								message => sub {
									my ($ev, $type, $payload, $ctag, $dtag, $rkey) = @_;
									note "Had message: $type, $payload on $id rkey $rkey with delivery $delivery";
									$delivery->done($type => $payload);
									$ev->unsubscribe;
								}
							);
							$ch->publish(
								exchange    => 'test_channel_spam',
								routing_key => $rkey,
								type        => 'some_type',
								payload     => 'test message for item ' . $item,
							)->transform(done => sub { $q })
						})->then(sub {
							my ($q) = @_;
							Future->wait_any(
								$loop->timeout_future(after => 10),
								$delivery
							)
						})->then(sub {
							ok($delivery->is_ready, $item . ' delivery ready');
							ok(!$delivery->failure, $item . ' did not fail');
							is_deeply([ $delivery->get ], [ 'some_type' => 'test message for item ' . $item ], $item . ' had expected type and content');
							Future->done;
						})->on_fail(sub { note "so we failed... @_"; })
					)
				} or do {
					fail("Exception - $@");
					Future->done
				}
			})->else_done->on_ready(sub { note 'ready for ' . $item })
		)
	} concurrent => 64, generate => sub {
		return unless $countdown;
		note "next is $countdown";
		$countdown--
	})->get;
}

note "Shutting down";
$cm->shutdown->get;

done_testing;

