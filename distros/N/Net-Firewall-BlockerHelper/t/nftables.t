#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

BEGIN {
	use_ok('Net::Firewall::BlockerHelper')                     || print "Bail out!\n";
	use_ok('Net::Firewall::BlockerHelper::backends::nftables') || print "Bail out!\n";
}

sub fw {
	my (%opts) = @_;
	my $fw = Net::Firewall::BlockerHelper->new(
		backend => 'nftables',
		name    => 'ssh',
		prefix  => 'derp',
		testing => 1,
		%opts,
	);
	$fw->init_backend;
	return $fw;
}

# --- init builds the table, chain, sets, and rules ---------------------------
{
	my $fw = fw( ports => ['22'], protocols => ['tcp'] );

	is_deeply(
		$fw->{test_data}{fail_okay_commands},
		["nft 'delete table inet derp_ssh'"],
		'init cleans up a stale table first'
	);
	is_deeply(
		$fw->{test_data}{commands},
		[
			"nft 'add table inet derp_ssh'",
			"nft 'add chain inet derp_ssh derp_ssh { type filter hook input priority -1 ; policy accept ; }'",
			"nft 'add set inet derp_ssh derp_ssh_4 { type ipv4_addr; }'",
			"nft 'add set inet derp_ssh derp_ssh_6 { type ipv6_addr; }'",
			"nft 'add rule inet derp_ssh derp_ssh tcp dport { 22 } ip saddr \@derp_ssh_4 drop'",
			"nft 'add rule inet derp_ssh derp_ssh tcp dport { 22 } ip6 saddr \@derp_ssh_6 drop'",
		],
		'init creates the table, chain, sets, and rules'
	);

	# bans are routed to the right family set
	$fw->ban( ban => '1.2.3.4' );
	is_deeply(
		$fw->{test_data},
		["nft 'add element inet derp_ssh derp_ssh_4 { 1.2.3.4 }'"],
		'IPv4 ban adds to the v4 set'
	);
	$fw->ban( ban => 'dead::1' );
	is_deeply(
		$fw->{test_data},
		["nft 'add element inet derp_ssh derp_ssh_6 { dead::1 }'"],
		'IPv6 ban adds to the v6 set'
	);

	$fw->ban( ban => '1.2.3.4' );
	is( $fw->{test_data}, 'already banned', 'double ban short-circuits' );

	$fw->unban( ban => '1.2.3.4' );
	is( $fw->{test_data}, "nft 'delete element inet derp_ssh derp_ssh_4 { 1.2.3.4 }'", 'unban deletes the element' );

	is( $fw->check, 1, 'check reports healthy in testing mode' );
	is_deeply(
		$fw->{test_data},
		[
			"nft 'list table inet derp_ssh'",
			"nft 'list chain inet derp_ssh derp_ssh' | grep -q '\@derp_ssh_4'",
			"nft 'list chain inet derp_ssh derp_ssh' | grep -q '\@derp_ssh_6'",
		],
		'check probes the table and the rules referencing each set'
	);

	$fw->re_init;
	is_deeply(
		$fw->{test_data},
		["nft 'add element inet derp_ssh derp_ssh_6 { dead::1 }'"],
		're_init re-adds the remaining ban'
	);

	$fw->flush;
	is_deeply(
		$fw->{test_data},
		[ "nft 'flush set inet derp_ssh derp_ssh_4'", "nft 'flush set inet derp_ssh derp_ssh_6'" ],
		'flush flushes both sets'
	);
	is( scalar( $fw->list ), 0, 'flush emptied the ban list' );

	$fw->teardown;
	is_deeply( $fw->{test_data}, ["nft 'delete table inet derp_ssh'"], 'teardown deletes the table' );
}

# --- reject type and icmp family splitting ----------------------------------
{
	my $fw = fw( protocols => [ 'icmp', 'ipv6-icmp' ], options => { type => 'reject' } );
	my @rules = grep { /add rule/ } @{ $fw->{test_data}{commands} };
	is_deeply(
		\@rules,
		[
			"nft 'add rule inet derp_ssh derp_ssh meta l4proto icmp ip saddr \@derp_ssh_4 reject'",
			"nft 'add rule inet derp_ssh derp_ssh meta l4proto ipv6-icmp ip6 saddr \@derp_ssh_6 reject'",
		],
		'icmp goes only to the v4 rule, ipv6-icmp only to the v6 rule, with reject'
	);
}

# --- ports without protocols default to tcp and udp --------------------------
{
	my $fw = fw( ports => [ '22', '143' ] );
	my @rules = grep { /add rule/ } @{ $fw->{test_data}{commands} };
	is_deeply(
		\@rules,
		[
			"nft 'add rule inet derp_ssh derp_ssh tcp dport { 22, 143 } ip saddr \@derp_ssh_4 drop'",
			"nft 'add rule inet derp_ssh derp_ssh udp dport { 22, 143 } ip saddr \@derp_ssh_4 drop'",
			"nft 'add rule inet derp_ssh derp_ssh tcp dport { 22, 143 } ip6 saddr \@derp_ssh_6 drop'",
			"nft 'add rule inet derp_ssh derp_ssh udp dport { 22, 143 } ip6 saddr \@derp_ssh_6 drop'",
		],
		'ports without protocols produce tcp and udp rules per family with all ports'
	);
}

# --- block-all default -------------------------------------------------------
{
	my $fw = fw();
	my @rules = grep { /add rule/ } @{ $fw->{test_data}{commands} };
	is_deeply(
		\@rules,
		[
			"nft 'add rule inet derp_ssh derp_ssh ip saddr \@derp_ssh_4 drop'",
			"nft 'add rule inet derp_ssh derp_ssh ip6 saddr \@derp_ssh_6 drop'",
		],
		'no ports or protocols blocks everything from both sets'
	);
}

# --- option validation --------------------------------------------------------
{
	local $@;
	eval { fw( options => { type => 'derp' } ); };
	ok( $@, 'invalid type errors' );
	eval { fw( options => { priority => 'derp' } ); };
	ok( $@, 'invalid priority errors' );
}

# --- CIDR bans are not supported ---------------------------------------------
{
	my $fw = fw( ports => ['22'], protocols => ['tcp'] );
	is( $fw->{backend_obj}->{cidr_supported}, 0, 'nftables does not support CIDR bans' );

	my $cidr_blocked = 0;
	eval { $fw->ban_cidr( ban => '1.2.3.0/24' ); };
	if ( $fw->{error} == 29 ) { $cidr_blocked = 1; }
	if ( !$cidr_blocked ) { die('ban_cidr did not set error 29 cidrNotSupported'); }
	ok( $cidr_blocked, 'ban_cidr sets error 29 cidrNotSupported' );
}

done_testing();
