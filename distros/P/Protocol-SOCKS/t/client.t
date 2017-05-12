use strict;
use warnings;

use Test::More;
use Protocol::SOCKS::Client;

{ # Server with no auth, single TCP connect request
	my @pending;
	my $cli = new_ok('Protocol::SOCKS::Client', [
		version => 5,
		writer => sub {
			return fail('unexpected write') unless @pending;
			is(shift(), shift(@pending), "had expected item");
		}
	]);
	can_ok($cli, qw(version init on_read write));

	ok(!$cli->auth->is_ready, 'auth not yet done');
	push @pending, "\x05\x01\x00";
	$cli->init;
	ok(!$cli->auth->is_ready, 'auth still not yet done');

	{
		$cli->on_read(\(my $buf = "\x05\x00"));
		ok($cli->auth->is_ready, 'auth is now done');
	}
	{
		push @pending, "\x05\x01\x00\x01\x01\x02\x03\x04\x02\x0a";
		my $f = $cli->connect(
			1, '1.2.3.4', 522
		);
		ok(!$f->is_ready, 'connection not yet complete');
		$cli->on_read(\(my $buf = "\x05\x00\x00\x01\x00\x00\x00\x00\x00\x00"));
		ok($f->is_ready, 'connection complete');
	}
}

done_testing;
