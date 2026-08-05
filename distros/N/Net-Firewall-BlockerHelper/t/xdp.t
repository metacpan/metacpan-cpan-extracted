#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

BEGIN {
	use_ok('Net::Firewall::BlockerHelper') || print "Bail out!\n";
}

# init loads xdp-filter per interface; ban/unban add/remove the ip
{
	my $fw = Net::Firewall::BlockerHelper->new(
		backend => 'xdp',
		name    => 'edge',
		testing => 1,
		options => { interfaces => [ 'eth0', 'eth1' ], mode => 'src' },
	);
	$fw->init_backend;

	is( scalar( @{ $fw->{test_data} } ), 2, 'init loads onto both interfaces' );
	like( $fw->{test_data}[0], qr{^xdp-filter load -f ipv4,ipv6 -p allow -m native eth0$},
		'load uses allow policy so only listed ips drop' );

	$fw->ban( ban => '1.2.3.4' );
	is( $fw->{test_data}, 'xdp-filter ip 1.2.3.4 -m src', 'ban adds the ip in src mode' );

	$fw->unban( ban => '1.2.3.4' );
	is( $fw->{test_data}, 'xdp-filter ip 1.2.3.4 -m src -r', 'unban removes the ip with -r' );

	my $cidr_blocked = 0;
	eval { $fw->ban_cidr( ban => '1.2.3.0/24' ); };
	if ( defined( $fw->{error} ) && $fw->{error} == 29 ) { $cidr_blocked = 1; }
	if ( !$cidr_blocked ) {
		die( 'ban_cidr did not set frontend error 29 cidrNotSupported... got ' . ( defined( $fw->{error} ) ? $fw->{error} : 'undef' ) );
	}

	$fw->teardown;
	is_deeply( $fw->{test_data}, [ 'xdp-filter unload eth0', 'xdp-filter unload eth1' ],
		'teardown unloads every interface' );
}

# interfaces is required and must be a non-empty arrayref
{
	my $died = 0;
	eval {
		my $fw = Net::Firewall::BlockerHelper->new(
			backend => 'xdp', name => 'edge', testing => 1, options => { interfaces => [] },
		);
		$fw->init_backend;
	};
	$died = 1 if ($@);
	ok( $died, 'empty interfaces is fatal' );
}

# mode must be src or dst
{
	my $died = 0;
	eval {
		my $fw = Net::Firewall::BlockerHelper->new(
			backend => 'xdp', name => 'edge', testing => 1,
			options => { interfaces => ['eth0'], mode => 'bogus' },
		);
		$fw->init_backend;
	};
	$died = 1 if ($@);
	ok( $died, 'invalid mode is fatal' );
}

done_testing();
