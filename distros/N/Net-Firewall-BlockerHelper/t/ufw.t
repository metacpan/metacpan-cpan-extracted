#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

BEGIN {
	use_ok('Net::Firewall::BlockerHelper')                || print "Bail out!\n";
	use_ok('Net::Firewall::BlockerHelper::backends::ufw') || print "Bail out!\n";
}

my $status_cmd = 'ufw status | grep -qiE "^Status:[[:space:]]*active"';

# --- ports + tcp -------------------------------------------------------------
{
	my $fw = Net::Firewall::BlockerHelper->new(
		backend   => 'ufw',
		name      => 'ssh',
		ports     => [ '22', '143' ],
		protocols => ['tcp'],
		testing   => 1,
	);
	$fw->init_backend;
	is_deeply( $fw->{test_data}, { commands => [$status_cmd] }, 'init verifies ufw is enabled' );

	$fw->ban( ban => '1.2.3.4' );
	is_deeply(
		$fw->{test_data},
		['ufw prepend deny proto tcp from 1.2.3.4 to any port 22,143'],
		'ban prepends a per-IP rule with the ports'
	);

	$fw->ban( ban => '1.2.3.4' );
	is( $fw->{test_data}, 'already banned', 'double ban short-circuits' );

	is( $fw->check, 1, 'check reports healthy in testing mode' );
	is_deeply( $fw->{test_data}, [$status_cmd], 'check verifies ufw is enabled' );

	ok( $fw->{backend_obj}->{cidr_supported}, 'the ufw backend supports CIDR bans' );

	$fw->ban_cidr( ban => '1.2.3.0/24' );
	is_deeply(
		$fw->{test_data},
		['ufw prepend deny proto tcp from 1.2.3.0/24 to any port 22,143'],
		'ban_cidr prepends a per-range rule with the ports'
	);

	$fw->unban_cidr( ban => '1.2.3.0/24' );
	is_deeply(
		$fw->{test_data},
		['ufw delete deny proto tcp from 1.2.3.0/24 to any port 22,143'],
		'unban_cidr deletes the per-range rule'
	);

	$fw->ban( ban => 'dead::1' );
	$fw->re_init;
	is_deeply(
		[ sort @{ $fw->{test_data} } ],
		[
			'ufw prepend deny proto tcp from 1.2.3.4 to any port 22,143',
			'ufw prepend deny proto tcp from dead::1 to any port 22,143',
		],
		're_init re-adds the rules for every banned IP'
	);

	$fw->unban( ban => 'dead::1' );
	is_deeply(
		$fw->{test_data},
		['ufw delete deny proto tcp from dead::1 to any port 22,143'],
		'unban deletes the per-IP rule'
	);

	$fw->teardown;
	is_deeply(
		$fw->{test_data},
		['ufw delete deny proto tcp from 1.2.3.4 to any port 22,143'],
		'teardown deletes the rules for all banned IPs'
	);
	is( scalar( $fw->list ), 1, 'teardown keeps the ban list for re_init' );

	# re-arm the same backend object so the kept ban list is exercised
	$fw->{backend_obj}->init;
	$fw->flush;
	is( scalar( $fw->list ), 0, 'flush empties the ban list' );
}

# --- block-all, ports-only, and reject ---------------------------------------
{
	my $fw = Net::Firewall::BlockerHelper->new(
		backend => 'ufw',
		name    => 'ssh',
		testing => 1,
	);
	$fw->init_backend;
	$fw->ban( ban => '1.2.3.4' );
	is_deeply( $fw->{test_data}, ['ufw prepend deny from 1.2.3.4 to any'], 'no ports or protocols blocks the whole IP' );
}
{
	my $fw = Net::Firewall::BlockerHelper->new(
		backend => 'ufw',
		name    => 'ssh',
		ports   => ['22'],
		options => { type => 'reject' },
		testing => 1,
	);
	$fw->init_backend;
	$fw->ban( ban => '1.2.3.4' );
	is_deeply(
		$fw->{test_data},
		[
			'ufw prepend reject proto tcp from 1.2.3.4 to any port 22',
			'ufw prepend reject proto udp from 1.2.3.4 to any port 22',
		],
		'ports without protocols defaults to tcp and udp, honoring reject'
	);
}

# --- kill options --------------------------------------------------------------
{
	my $fw = Net::Firewall::BlockerHelper->new(
		backend => 'ufw',
		name    => 'ssh',
		options => { kill => 'ss' },
		testing => 1,
	);
	$fw->init_backend;
	$fw->ban( ban => '1.2.3.4' );
	is( $fw->{test_data}[-1], 'ss -K -tu dst "[1.2.3.4]"', 'kill=ss runs ss -K -tu after the ban' );
}
{
	my $fw = Net::Firewall::BlockerHelper->new(
		backend => 'ufw',
		name    => 'ssh',
		options => { kill => 'conntrack' },
		testing => 1,
	);
	$fw->init_backend;
	$fw->ban( ban => '1.2.3.4' );
	is( $fw->{test_data}[-1], 'conntrack -D -s 1.2.3.4', 'kill=conntrack runs conntrack after the ban' );
}

# --- validation, on the backend directly as that is where these are checked ------
{
	local $@;
	eval { Net::Firewall::BlockerHelper::backends::ufw->new( name => 'ssh', protocols => ['sctp'] ); };
	ok( $@, 'a protocol ufw does not understand errors' );
	is( $Error::Helper::error, 5, 'an unsupported protocol raises error 5' );

	eval { Net::Firewall::BlockerHelper::backends::ufw->new( name => 'ssh', options => { kill => 'derp' } ); };
	ok( $@, 'an invalid kill mode errors' );
}

done_testing();
