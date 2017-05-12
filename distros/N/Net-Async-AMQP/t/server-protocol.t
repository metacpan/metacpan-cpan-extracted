use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::HexString;
use Net::Async::AMQP;
use Net::Async::AMQP::Server::Protocol;

{
	my $proto = new_ok('Net::Async::AMQP::Server::Protocol');
	like(exception {
		$proto->on_read(
			\(my $data = 'GET / HTTP/1.1'),
			0
		)
	}, qr/Invalid header received/, 'exception on invalid header');
}

{
	my @expected;
	my $proto = new_ok(
		'Net::Async::AMQP::Server::Protocol' => [
			write => sub {
				my $data = shift;
				my $next = shift @expected or return fail('unexpected data for write');
				is_hexstr($data, $next, 'next frame write matches') or note join '', map sprintf('\\x%02x', ord $_), split //, $data;
			},
		]
	);
	my $data = 'AM';
	is($proto->on_read(
		\$data,
		0
	), 0, 'partial header');
	$data .= 'QP';
	is($proto->on_read(
		\$data,
		0
	), 0, 'partial header');
	$data .= "\x00\x00\x09\x01";
	push @expected, "\x01\x00\x00\x00\x00\x00\x1a\x00\x0a\x00\x0a\x00\x00\x00\x00\x00\x00\x00\x00\x00\x08\x41\x4d\x51\x50\x4c\x41\x49\x4e\x00\x00\x00\x00\xce";
	ok(my $code = $proto->on_read(
		\$data,
		0
	), 'remaining header');
	isa_ok($code, 'CODE');
	is(exception {
		$code = $code->($proto, \$data, 0)
	}, undef, 'startup callback');
	isa_ok($code, 'CODE');
	is($data, '', 'buffer is now empty');

	my $step = sub {
		is(exception {
			$code = $code->($proto, \$data, 0)
		}, undef, 'read frames');
	};
	$step->();
}

done_testing;

