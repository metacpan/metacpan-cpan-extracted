#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

BEGIN {
	use_ok('Net::Firewall::BlockerHelper')                    || print "Bail out!\n";
	use_ok('Net::Firewall::BlockerHelper::backends::openwrt') || print "Bail out!\n";
}

sub fw {
	my (%opts) = @_;
	my $fw = Net::Firewall::BlockerHelper->new(
		backend => 'openwrt',
		name    => 'ssh',
		prefix  => 'derp',
		testing => 1,
		%opts,
	);
	$fw->init_backend;
	return $fw;
}

# --- local mode: init builds the ipsets, rules, and ordering -----------------
{
	my $fw = fw( ports => ['22'], protocols => ['tcp'], options => { zone => 'wan' } );

	is_deeply(
		$fw->{test_data}{fail_okay_commands},
		[
			'uci -q delete firewall.derp_ssh_r0',
			'uci -q delete firewall.derp_ssh_r1',
			'uci -q delete firewall.derp_ssh_4',
			'uci -q delete firewall.derp_ssh_6',
		],
		'init clears any stale sections first'
	);

	is_deeply(
		$fw->{test_data}{commands},
		[
			'uci set firewall.derp_ssh_4=ipset',
			'uci set firewall.derp_ssh_4.name=derp_ssh_4',
			'uci set firewall.derp_ssh_4.family=ipv4',
			'uci add_list firewall.derp_ssh_4.match=src_net',
			'uci set firewall.derp_ssh_4.enabled=1',
			'uci set firewall.derp_ssh_6=ipset',
			'uci set firewall.derp_ssh_6.name=derp_ssh_6',
			'uci set firewall.derp_ssh_6.family=ipv6',
			'uci add_list firewall.derp_ssh_6.match=src_net',
			'uci set firewall.derp_ssh_6.enabled=1',
			'uci set firewall.derp_ssh_r0=rule',
			'uci set firewall.derp_ssh_r0.name=derp_ssh_r0',
			'uci set firewall.derp_ssh_r0.family=ipv4',
			'uci set firewall.derp_ssh_r0.src=wan',
			'uci set firewall.derp_ssh_r0.ipset=derp_ssh_4',
			'uci set firewall.derp_ssh_r0.proto=tcp',
			'uci add_list firewall.derp_ssh_r0.dest_port=22',
			'uci set firewall.derp_ssh_r0.target=DROP',
			'uci set firewall.derp_ssh_r1=rule',
			'uci set firewall.derp_ssh_r1.name=derp_ssh_r1',
			'uci set firewall.derp_ssh_r1.family=ipv6',
			'uci set firewall.derp_ssh_r1.src=wan',
			'uci set firewall.derp_ssh_r1.ipset=derp_ssh_6',
			'uci set firewall.derp_ssh_r1.proto=tcp',
			'uci add_list firewall.derp_ssh_r1.dest_port=22',
			'uci set firewall.derp_ssh_r1.target=DROP',
			'uci reorder firewall.derp_ssh_r0=0',
			'uci reorder firewall.derp_ssh_r1=1',
		],
		'init creates the ipsets and rules, then moves the rules to the front'
	);

	is_deeply(
		$fw->{test_data}{commit},
		[
			'uci -q delete firewall.derp_ssh_4.entry',
			'uci -q delete firewall.derp_ssh_6.entry',
			'uci commit firewall',
		],
		'init commits, with no entries to write yet'
	);
	is_deeply( $fw->{test_data}{reload}, ['fw4 reload'], 'init reloads fw4' );

	# bans go straight to the live set with no uci and no commit
	$fw->ban( ban => '1.2.3.4' );
	is_deeply(
		$fw->{test_data},
		["nft add element inet fw4 derp_ssh_4 '{ 1.2.3.4 }'"],
		'IPv4 ban adds an element to the v4 set'
	);
	$fw->ban( ban => 'DEAD::1' );
	is_deeply(
		$fw->{test_data},
		["nft add element inet fw4 derp_ssh_6 '{ dead::1 }'"],
		'IPv6 ban is lowercased and adds to the v6 set'
	);

	$fw->ban( ban => '1.2.3.4' );
	is( $fw->{test_data}, 'already banned', 'double ban short-circuits' );

	# CIDR shares the same sets, as they are interval sets
	$fw->ban_cidr( ban => '10.0.0.0/8' );
	is_deeply(
		$fw->{test_data},
		["nft add element inet fw4 derp_ssh_4 '{ 10.0.0.0/8 }'"],
		'IPv4 CIDR ban adds to the v4 set'
	);
	$fw->ban_cidr( ban => '2001:db8::/32' );
	is_deeply(
		$fw->{test_data},
		["nft add element inet fw4 derp_ssh_6 '{ 2001:db8::/32 }'"],
		'IPv6 CIDR ban adds to the v6 set'
	);

	is_deeply( [ sort( $fw->list ) ],      [ '1.2.3.4',    'dead::1' ],       'list returns the single IP bans' );
	is_deeply( [ sort( $fw->list_cidr ) ], [ '10.0.0.0/8', '2001:db8::/32' ], 'list_cidr returns the range bans' );

	# commit is what writes the ban list into the config
	$fw->commit;
	is_deeply(
		$fw->{test_data}{commit},
		[
			'uci -q delete firewall.derp_ssh_4.entry',
			'uci -q delete firewall.derp_ssh_6.entry',
			'uci add_list firewall.derp_ssh_4.entry=1.2.3.4',
			'uci add_list firewall.derp_ssh_4.entry=10.0.0.0/8',
			'uci add_list firewall.derp_ssh_6.entry=dead::1',
			'uci add_list firewall.derp_ssh_6.entry=2001:db8::/32',
			'uci commit firewall',
		],
		'commit clears both entry lists, then writes the IP and CIDR bans and commits'
	);

	$fw->unban( ban => '1.2.3.4' );
	is_deeply(
		$fw->{test_data},
		["nft delete element inet fw4 derp_ssh_4 '{ 1.2.3.4 }'"],
		'unban deletes the element'
	);
	$fw->unban_cidr( ban => '10.0.0.0/8' );
	is_deeply(
		$fw->{test_data},
		["nft delete element inet fw4 derp_ssh_4 '{ 10.0.0.0/8 }'"],
		'unban_cidr deletes the element'
	);

	is( $fw->check, 1, 'check reports healthy in testing mode' );
	is_deeply(
		$fw->{test_data},
		[
			'uci -q get firewall.derp_ssh_4',
			'uci -q get firewall.derp_ssh_6',
			'uci -q get firewall.derp_ssh_r0',
			'uci -q get firewall.derp_ssh_r1',
			'nft list table inet fw4',
		],
		'check probes the ipset and rule config, then the live table'
	);

	$fw->re_init;
	is_deeply(
		$fw->{test_data},
		[
			"nft add element inet fw4 derp_ssh_6 '{ dead::1 }'",
			"nft add element inet fw4 derp_ssh_6 '{ 2001:db8::/32 }'",
		],
		're_init re-adds the remaining IP and CIDR bans'
	);

	$fw->flush;
	is_deeply(
		$fw->{test_data},
		[ 'nft flush set inet fw4 derp_ssh_4', 'nft flush set inet fw4 derp_ssh_6' ],
		'flush flushes both sets'
	);
	is( scalar( $fw->list ),      0, 'flush emptied the ban list' );
	is( scalar( $fw->list_cidr ), 0, 'flush emptied the CIDR ban list' );

	$fw->teardown;
	is_deeply(
		$fw->{test_data}{fail_okay_commands},
		[
			'uci -q delete firewall.derp_ssh_r0',
			'uci -q delete firewall.derp_ssh_r1',
			'uci -q delete firewall.derp_ssh_4',
			'uci -q delete firewall.derp_ssh_6',
		],
		'teardown removes the rule and ipset sections'
	);
	is_deeply(
		$fw->{test_data}{commit},
		['uci commit firewall'],
		'teardown commits bare, as the sections the entries would go in are gone'
	);
	is_deeply( $fw->{test_data}{reload}, ['fw4 reload'], 'teardown reloads fw4' );
	is_deeply(
		$fw->{test_data}{drop_sets},
		[ 'nft delete set inet fw4 derp_ssh_4', 'nft delete set inet fw4 derp_ssh_6' ],
		'teardown drops the sets after the reload has taken the rules'
	);
}

# --- no ports and no protocols means proto all, not the fw4 tcp/udp default --
{
	my $fw    = fw();
	my @rules = grep { /\.proto=/ } @{ $fw->{test_data}{commands} };
	is_deeply(
		\@rules,
		[ 'uci set firewall.derp_ssh_r0.proto=all', 'uci set firewall.derp_ssh_r1.proto=all' ],
		'blocking everything writes proto all explicitly'
	);

	my @src = grep { /\.src=/ } @{ $fw->{test_data}{commands} };
	is_deeply(
		\@src,
		[ "uci set 'firewall.derp_ssh_r0.src=*'", "uci set 'firewall.derp_ssh_r1.src=*'" ],
		'the default zone is every zone, quoted so the shell does not glob it'
	);
}

# --- ports without protocols default to tcp and udp per family ---------------
{
	my $fw    = fw( ports => [ '22', '143' ] );
	my @rules = grep { /\.proto=|\.dest_port=|\.family=/ } @{ $fw->{test_data}{commands} };
	is_deeply(
		\@rules,
		[
			'uci set firewall.derp_ssh_4.family=ipv4',
			'uci set firewall.derp_ssh_6.family=ipv6',
			'uci set firewall.derp_ssh_r0.family=ipv4',
			'uci set firewall.derp_ssh_r0.proto=tcp',
			'uci add_list firewall.derp_ssh_r0.dest_port=22',
			'uci add_list firewall.derp_ssh_r0.dest_port=143',
			'uci set firewall.derp_ssh_r1.family=ipv4',
			'uci set firewall.derp_ssh_r1.proto=udp',
			'uci add_list firewall.derp_ssh_r1.dest_port=22',
			'uci add_list firewall.derp_ssh_r1.dest_port=143',
			'uci set firewall.derp_ssh_r2.family=ipv6',
			'uci set firewall.derp_ssh_r2.proto=tcp',
			'uci add_list firewall.derp_ssh_r2.dest_port=22',
			'uci add_list firewall.derp_ssh_r2.dest_port=143',
			'uci set firewall.derp_ssh_r3.family=ipv6',
			'uci set firewall.derp_ssh_r3.proto=udp',
			'uci add_list firewall.derp_ssh_r3.dest_port=22',
			'uci add_list firewall.derp_ssh_r3.dest_port=143',
		],
		'ports with no protocols produce tcp and udp rules per family'
	);
}

# --- reject type and icmp family splitting -----------------------------------
{
	my $fw = fw( protocols => [ 'icmp', 'ipv6-icmp' ], options => { type => 'reject' } );
	my @rules = grep { /\.proto=|\.target=|\.ipset=/ } @{ $fw->{test_data}{commands} };
	is_deeply(
		\@rules,
		[
			'uci set firewall.derp_ssh_r0.ipset=derp_ssh_4',
			'uci set firewall.derp_ssh_r0.proto=icmp',
			'uci set firewall.derp_ssh_r0.target=REJECT',
			'uci set firewall.derp_ssh_r1.ipset=derp_ssh_6',
			'uci set firewall.derp_ssh_r1.proto=ipv6-icmp',
			'uci set firewall.derp_ssh_r1.target=REJECT',
		],
		'icmp goes only to the v4 rule, ipv6-icmp only to the v6 rule, with reject'
	);
}

# --- reorder can be turned off -----------------------------------------------
{
	my $fw = fw( options => { reorder => 0 } );
	my @reorder = grep { /reorder/ } @{ $fw->{test_data}{commands} };
	is_deeply( \@reorder, [], 'reorder 0 leaves the config ordering alone' );
}

# --- kill scopes conntrack to the configured protocols -----------------------
{
	my $fw = fw( protocols => ['tcp'], options => { kill => 1 } );
	$fw->ban( ban => '1.2.3.4' );
	is_deeply(
		$fw->{test_data},
		[ "nft add element inet fw4 derp_ssh_4 '{ 1.2.3.4 }'", 'conntrack -D -p tcp -s 1.2.3.4' ],
		'kill drops the conntrack entries for the blocked protocol'
	);
}

# --- remote mode renders ubus JSON-RPC calls instead of commands -------------
{
	my $fw = fw(
		ports     => ['22'],
		protocols => ['tcp'],
		options   => {
			zone     => 'wan',
			host     => '192.0.2.1',
			user     => 'blocker',
			password => 'hunter2',
		},
	);

	is_deeply(
		$fw->{test_data}{commands}[0],
		{
			object => 'uci',
			method => 'add',
			params => {
				config => 'firewall',
				type   => 'ipset',
				name   => 'derp_ssh_4',
				values => {
					name    => 'derp_ssh_4',
					family  => 'ipv4',
					match   => ['src_net'],
					enabled => '1',
				},
			},
		},
		'a section becomes one uci.add carrying all of its values'
	);

	is_deeply(
		$fw->{test_data}{commands}[2],
		{
			object => 'uci',
			method => 'add',
			params => {
				config => 'firewall',
				type   => 'rule',
				name   => 'derp_ssh_r0',
				values => {
					name      => 'derp_ssh_r0',
					family    => 'ipv4',
					src       => 'wan',
					ipset     => 'derp_ssh_4',
					proto     => 'tcp',
					dest_port => ['22'],
					target    => 'DROP',
				},
			},
		},
		'a rule section carries its port list as an array'
	);

	is_deeply(
		$fw->{test_data}{commands}[4],
		{
			object => 'uci',
			method => 'order',
			params => { config => 'firewall', sections => [ 'derp_ssh_r0', 'derp_ssh_r1' ] },
		},
		'reorder becomes a single uci.order'
	);

	is_deeply(
		$fw->{test_data}{reload},
		[ { object => 'file', method => 'exec', params => { command => 'fw4', params => ['reload'] } } ],
		'commands run through file.exec'
	);

	$fw->ban( ban => '1.2.3.4' );
	is_deeply(
		$fw->{test_data},
		[
			{
				object => 'file',
				method => 'exec',
				params => {
					command => 'nft',
					params  => [ 'add', 'element', 'inet', 'fw4', 'derp_ssh_4', '{ 1.2.3.4 }' ],
				},
			}
		],
		'a ban is an nft exec with the element as one parameter'
	);

	$fw->commit;
	is_deeply(
		$fw->{test_data}{commit},
		[
			{
				object => 'uci',
				method => 'delete',
				params => { config => 'firewall', section => 'derp_ssh_4', option => 'entry' },
			},
			{
				object => 'uci',
				method => 'delete',
				params => { config => 'firewall', section => 'derp_ssh_6', option => 'entry' },
			},
			{
				object => 'uci',
				method => 'set',
				params => { config => 'firewall', section => 'derp_ssh_4', values => { entry => ['1.2.3.4'] } },
			},
			{ object => 'uci', method => 'commit', params => { config => 'firewall' } },
		],
		'commit clears both lists then sets only the non-empty one, as ubus rejects an empty array'
	);
}

# --- remote mode requires a password -----------------------------------------
{
	local $@;
	eval {
		Net::Firewall::BlockerHelper::backends::openwrt->new(
			name    => 'ssh',
			options => { host => '192.0.2.1' },
		);
	};
	ok( $@, 'host without a password errors' );
	is( $Error::Helper::errorFlag, 'noPassword', 'the flag raised is noPassword' );
}

# --- the frontend commit is gated on the backend implementing it -------------
{
	my $fw = Net::Firewall::BlockerHelper->new(
		backend => 'nftables',
		name    => 'ssh',
		prefix  => 'derp',
		testing => 1,
	);
	$fw->init_backend;

	local $@;
	eval { $fw->commit; };
	ok( $@, 'commit on a backend without one errors' );
	is( $Error::Helper::errorFlag, 'commitNotSupported', 'the flag raised is commitNotSupported' );
}

done_testing();
