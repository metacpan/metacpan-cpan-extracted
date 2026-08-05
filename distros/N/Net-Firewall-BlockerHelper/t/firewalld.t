#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

BEGIN {
	use_ok('Net::Firewall::BlockerHelper')                      || print "Bail out!\n";
	use_ok('Net::Firewall::BlockerHelper::backends::firewalld') || print "Bail out!\n";
}

my $rule4 = '-m set --match-set derp_ssh_4 src -p tcp -m multiport --dports 22 -j DROP';
my $rule6 = '-m set --match-set derp_ssh_6 src -p tcp -m multiport --dports 22 -j DROP';

my $fw = Net::Firewall::BlockerHelper->new(
	backend   => 'firewalld',
	name      => 'ssh',
	prefix    => 'derp',
	ports     => ['22'],
	protocols => ['tcp'],
	testing   => 1,
);
$fw->init_backend;

is_deeply(
	$fw->{test_data}{fail_okay_commands},
	[
		'firewall-cmd --direct --remove-rule ipv4 filter INPUT_direct 0 ' . $rule4,
		'firewall-cmd --direct --remove-rule ipv6 filter INPUT_direct 0 ' . $rule6,
		'ipset destroy derp_ssh_4',
		'ipset destroy derp_ssh_6',
	],
	'init cleans up stale rules and sets first'
);
is_deeply(
	$fw->{test_data}{commands},
	[
		'ipset create derp_ssh_4 hash:ip family inet',
		'ipset create derp_ssh_6 hash:ip family inet6',
		'firewall-cmd --direct --add-rule ipv4 filter INPUT_direct 0 ' . $rule4,
		'firewall-cmd --direct --add-rule ipv6 filter INPUT_direct 0 ' . $rule6,
	],
	'init creates the sets and adds the direct rules'
);

$fw->ban( ban => '1.2.3.4' );
is_deeply( $fw->{test_data}, ['ipset add derp_ssh_4 1.2.3.4'], 'IPv4 ban adds to the v4 set' );

$fw->ban( ban => 'dead::1' );
is_deeply( $fw->{test_data}, ['ipset add derp_ssh_6 dead::1'], 'IPv6 ban adds to the v6 set' );

$fw->ban( ban => '1.2.3.4' );
is( $fw->{test_data}, 'already banned', 'double ban short-circuits' );

$fw->unban( ban => '1.2.3.4' );
is( $fw->{test_data}, 'ipset del derp_ssh_4 1.2.3.4', 'unban removes from the set' );

is( $fw->check, 1, 'check reports healthy in testing mode' );
is_deeply(
	$fw->{test_data},
	[
		'firewall-cmd --state',
		'ipset list derp_ssh_4',
		'ipset list derp_ssh_6',
		'firewall-cmd --direct --query-rule ipv4 filter INPUT_direct 0 ' . $rule4,
		'firewall-cmd --direct --query-rule ipv6 filter INPUT_direct 0 ' . $rule6,
	],
	'check probes the daemon state, the sets, and each direct rule'
);

$fw->re_init;
is_deeply( $fw->{test_data}, ['ipset add derp_ssh_6 dead::1'], 're_init re-adds the remaining ban' );

$fw->flush;
is_deeply( $fw->{test_data}, [ 'ipset flush derp_ssh_4', 'ipset flush derp_ssh_6' ], 'flush flushes both sets' );
is( scalar( $fw->list ), 0, 'flush emptied the ban list' );

$fw->teardown;
is_deeply(
	$fw->{test_data},
	[
		'firewall-cmd --direct --remove-rule ipv4 filter INPUT_direct 0 ' . $rule4,
		'firewall-cmd --direct --remove-rule ipv6 filter INPUT_direct 0 ' . $rule6,
		'ipset destroy derp_ssh_4',
		'ipset destroy derp_ssh_6',
	],
	'teardown removes the rules before destroying the sets'
);

# --- kill option and custom chain --------------------------------------------
{
	my $fw2 = Net::Firewall::BlockerHelper->new(
		backend => 'firewalld',
		name    => 'ssh',
		prefix  => 'derp',
		options => { kill => 1, chain => 'IN_public_deny' },
		testing => 1,
	);
	$fw2->init_backend;
	like(
		$fw2->{test_data}{commands}[2],
		qr/--add-rule ipv4 filter IN_public_deny 0 /,
		'custom chain is used for the rules'
	);
	$fw2->ban( ban => '1.2.3.4' );
	is_deeply(
		$fw2->{test_data},
		[ 'ipset add derp_ssh_4 1.2.3.4', 'conntrack -D -s 1.2.3.4' ],
		'kill option runs conntrack after the ban'
	);
}

# --- option validation --------------------------------------------------------
{
	local $@;
	eval {
		Net::Firewall::BlockerHelper->new(
			backend => 'firewalld',
			name    => 'ssh',
			options => { type => 'derp' },
			testing => 1,
		)->init_backend;
	};
	ok( $@, 'invalid type errors' );
	eval {
		Net::Firewall::BlockerHelper->new(
			backend => 'firewalld',
			name    => 'ssh',
			options => { chain => 'bad chain' },
			testing => 1,
		)->init_backend;
	};
	ok( $@, 'invalid chain errors' );
}

# --- CIDR bans are not supported ---------------------------------------------
{
	my $cidr_blocked = 0;
	eval { $fw->ban_cidr( ban => '1.2.3.0/24' ); };
	if ( $fw->{error} == 29 ) { $cidr_blocked = 1; }
	ok( $cidr_blocked, 'ban_cidr sets error 29 cidrNotSupported' );
}

done_testing();
