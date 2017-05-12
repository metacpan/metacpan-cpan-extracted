use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Net::Async::AMQP;
use IO::Async::Loop;

plan skip_all => 'set NET_ASYNC_AMQP_HOST/USER/PASS/VHOST env vars to test' unless exists $ENV{NET_ASYNC_AMQP_HOST};

my $loop = IO::Async::Loop->new;
$loop->add(
	my $mq = Net::Async::AMQP->new
);
my $true = Net::AMQP::Value->true;
my %seen;
my %expected;
my $expect = sub {
	my $txt = shift;
	die 'already have ' . $txt if $expected{$txt}++;
	$txt
};
my %unexpected;
my $unexpect = sub {
	my $txt = shift;
	die 'already have ' . $txt if $unexpected{$txt}++;
	$txt
};
$mq->connect(
	host  => $ENV{NET_ASYNC_AMQP_HOST},
	user  => $ENV{NET_ASYNC_AMQP_USER},
	pass  => $ENV{NET_ASYNC_AMQP_PASS},
	vhost => $ENV{NET_ASYNC_AMQP_VHOST},
	client_properties => {
		capabilities => {
			'consumer_cancel_notify' => $true,
			'connection.blocked'     => $true,
		},
	},
)->then(sub {
	Future->needs_all(
		map $mq->open_channel, 1..2
	)
})->then(sub {
	my ($pub, $sub) = @_;
	$sub->queue_declare(
		queue => '',
		auto_delete => 1,
	)->then(sub {
		my ($q) = @_;
		note "Declared queue name " . $q->queue_name;
		$q->consumer(
			channel => $sub,
			on_message => sub {
				my %args = @_;
				my $payload = $args{payload};
				fail('already seen this one: ' . $payload) if $seen{$payload}++;
			},
			on_cancel => sub {
				note('have cancel')
			}
		)->transform(
			done => sub {
				note "Consumer name " . $_[1];
				$q->queue_name
			}
		)
	})->then(sub {
		my ($target) = @_;
		note 'sending normal';
		Future->needs_all(
			map $pub->publish(
				exchange => '',
				routing_key => $target,
				payload => $expect->('normal ' . $_),
			), 1..10
		)->then(sub {
			$pub->confirm_mode
		})->then(sub {
			note 'sending confirmed';
			Future->needs_all(
				map $pub->publish(
					exchange => '',
					routing_key => $target,
					payload => $expect->('confirmed ' . $_),
				), 1..10
			)
		})->then(sub {
			note 'sending mandatory';
			Future->needs_all(
				map $pub->publish(
					exchange => '',
					mandatory => 1,
					# immediate => 1,
					routing_key => $target . '-not-found',
					payload => $unexpect->('mandatory misdirected ' . $_),
				)->then(sub {
					Future->fail('not expecting this to succeed')
				}, sub {
					Future->done
				}), 1..10
			)
		})
	})
})->get;
note "had a total of " . (keys %seen) . " messages";
for(sort keys %seen) {
	ok(delete $expected{$_}, 'was expecting ' . $_);
	ok(!delete $unexpected{$_}, 'was not expecting ' . $_);
}
fail('wanted ' . $_ . ' but did not receive it') for sort keys %expected;
done_testing;

