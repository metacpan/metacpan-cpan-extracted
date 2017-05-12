use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Net::Async::AMQP;
use IO::Async::Loop;

my $loop = IO::Async::Loop->new;

subtest 'spec handling' => sub {
	ok(-r $Net::Async::AMQP::XML_SPEC, 'spec is readable');
	ok($Net::Async::AMQP::SPEC_LOADED, 'spec was loaded');
	can_ok('Net::AMQP::Protocol::Connection::Open', 'new');
	can_ok('Net::AMQP::Frame', 'new');
	done_testing;
};

subtest 'header' => sub {
	my $header = Net::Async::AMQP->header_bytes;
	my ($amqp, $id, $major, $minor, $patch) = unpack 'A4C1C1C1C1', $header;
	is($amqp, 'AMQP', 'header bytes start with AMQP');
	is($id, 0, 'protocol ID 0');
	my $ver = join '.', $major, $minor, $patch;
	cmp_ok(version->parse('0.9.1'), '<=', version->parse($ver), 'header requests at least 0.9.1');
};

subtest 'channel IDs' => sub {
	# The full number of channels can take a while to process the tests, so first we check
	# that we have the right number in the 'constant':
	is(Net::Async::AMQP->MAX_CHANNELS, 65535, 'max channels matches AMQP 0.9.1 spec');

	# ... then we replace it with something more amenable to testing
	for my $case (sub {
		no warnings 'redefine';
		note "Override MAX_CHANNELS to 100";
		local *Net::Async::AMQP::MAX_CHANNELS = sub { 100 };
		my $mq = Net::Async::AMQP->new;
		shift->($mq)
	}, sub {
		note "Set max_channels to 100";
		my $mq = Net::Async::AMQP->new(
			max_channels => 100
		);
		shift->($mq)
	}) {
		$case->(sub {
			my ($mq) = @_;
			$loop->add($mq);
			my $max = $mq->max_channels || $mq->MAX_CHANNELS;
			my %idmap = map {; $mq->create_channel->id => 1 } 1..$max;
			is(keys(%idmap), $max, 'assign all available channels');
			is($mq->next_channel, undef, 'undef after running out of channels');
			# ok($mq->channel_by_id(1)->bus->invoke_event(close => 123, 'closing'), 'can close a channel');
			ok($mq->channel_closed(3), 'can close a channel');
			is($mq->next_channel, 3, 'have a valid channel ID again after closing');
			is($mq->next_channel, undef, 'and undef after running out again');
			is(exception {
				$mq->channel_closed($_) for 5..8;
			}, undef, 'close more channels');
			is($mq->create_channel->id, 5, 'reopen channel 5');
			is($mq->create_channel->id, 6, 'reopen channel 6');
			is($mq->create_channel->id, 7, 'reopen channel 7');
			is($mq->create_channel->id, 8, 'reopen channel 8');
			like(exception {
				$mq->create_channel->id
			}, qr/No channel available/, 'and ->create_channel gives an exception after running out again');
		});
	}
	done_testing;
};

done_testing;

