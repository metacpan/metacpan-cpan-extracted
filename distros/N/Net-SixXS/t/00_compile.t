use v5.010;
use strict;
use warnings;

use Test::More 0.98;

my $have_anyevent;
BEGIN {
	eval {
		require AnyEvent::Handle;
		require AnyEvent::Socket;
		$have_anyevent = 1;
	};
}

use_ok $_ for qw(
    Net::SixXS
    Net::SixXS::Data::Tunnel
    Net::SixXS::TIC::Client
    Net::SixXS::TIC::Server
    Net::SixXS::TIC::Server::Inetd
);

SKIP:
{
	skip 'AnyEvent not installed', 1 unless $have_anyevent;
	use_ok 'Net::SixXS::TIC::Server::AnyEvent';
}

done_testing;

