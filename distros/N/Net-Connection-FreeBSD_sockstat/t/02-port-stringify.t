#!perl
use 5.006;
use strict;
use warnings;
use Test::More;
use Net::Connection::FreeBSD_sockstat;

# libxo emits the port as an integer and uses zero where the text output uses a
# star, so _port_stringify maps it back to what sockstat actually displays
my @port_tests = (
	[ 0,     '*',   'an integer zero becomes a star' ],
	[ '0',   '*',   'a string zero becomes a star' ],
	[ undef, '*',   'a missing port becomes a star' ],
	[ 22,    22,    'a low port is left alone' ],
	[ 65535, 65535, 'the highest port is left alone' ],
	[ 8000,  8000,  'a high port is left alone' ],
);

foreach my $port_test (@port_tests) {
	my ( $port, $expected, $description ) = @{$port_test};

	is( Net::Connection::FreeBSD_sockstat::_port_stringify($port), $expected, $description );
}

# only a port of zero is special, not anything else that is merely false looking
is( Net::Connection::FreeBSD_sockstat::_port_stringify('00'), '00', 'only a bare zero is treated as a star' );

done_testing();
