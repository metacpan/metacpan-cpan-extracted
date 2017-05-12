use strict;
use warnings;

use Test::More;
use Test::HexString;
use Test::Fatal;

use Protocol::SOCKS::Client;

subtest 'request without auth' => sub {
	my $proto = new_ok('Protocol::SOCKS::Client');
	is_hexstr($proto->init_packet, "\x05\x01\x00", "init packet with single auth method");
	ok(!$proto->auth->is_ready, 'auth not ready yet');
	my $data = "\x05\x00";
	is(exception {
		$proto->on_read(\$data)
	}, undef, 'read data with no exception');
	is($data, '', 'full packet removed');
	ok($proto->auth->is_ready, 'auth now ready');
	is($proto->auth->get, 0,  'have correct auth');

	done_testing;
};

done_testing;

