use strict;
use warnings;

use Test::More;

use Net::Async::AMQP;
use Net::Async::AMQP::Utils;

{
	my $frame = Net::AMQP::Frame::Method->new(
		channel => 0,
		method_frame => Net::AMQP::Protocol::Connection::Start->new(
			server_properties => {
			},
			mechanisms        => 'AMQPLAIN',
			locale            => 'en_GB',
		),
	);
	like(amqp_frame_info($frame), qr/^Connection::Start/);
}

done_testing;


