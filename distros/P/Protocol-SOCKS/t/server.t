use strict;
use warnings;

use Test::More;
use Protocol::SOCKS::Server;

{ # Server with no auth, single TCP connect request
	my @pending;
	my $srv = new_ok('Protocol::SOCKS::Server', [
		version => 5,
		writer => sub {
			return fail('unexpected write') unless @pending;
			is(shift(), shift(@pending), "had expected item");
		}
	]);
	can_ok($srv, qw(version auth on_read write));

	ok(!$srv->init->is_ready, 'not yet done init');
	{ # Initial no-auth handshake
		push @pending, "\x05\x00";
		$srv->on_read(\(my $buf = "\x05\x01\x00"));
	}
	ok($srv->init->is_ready, 'init is done');
}

{ # Verify invalid auth
	my @pending;
	my $srv = new_ok('Protocol::SOCKS::Server', [
		version => 5,
		writer => sub {
			return fail('unexpected write') unless @pending;
			is(shift(), shift(@pending), "had expected item");
		}
	]);

	{ # Initial no-auth handshake
		push @pending, "\x05\xFF";
		$srv->on_read(\(my $buf = "\x05\x01\x39"));
	}
}

done_testing;

