#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

BEGIN {
	use_ok('Net::Firewall::BlockerHelper') || print "Bail out!\n";
}

# The backend checks must verify more than just the table/set existing. If the
# rules are removed externally while the table survives, check must report
# unhealthy or self-heal will never fire and bans will land in a table that no
# rule references.

# --- ipfw: check probes the table AND the rule number ------------------------
{
	my $fw = Net::Firewall::BlockerHelper->new(
		backend   => 'ipfw',
		name      => 'ssh',
		prefix    => 'derp',
		ports     => ['22'],
		protocols => ['tcp'],
		options   => { rule => 150 },
		testing   => 1,
	);
	$fw->init_backend;

	is( $fw->check, 1, 'ipfw check reports healthy in testing mode' );
	is_deeply(
		$fw->{test_data},
		[ 'ipfw table derp_ssh info', 'ipfw list 150' ],
		'ipfw check probes both the table and the rule number'
	);
}

# --- pf: check probes the table AND the anchor rules -------------------------
{
	my $fw = Net::Firewall::BlockerHelper->new(
		backend   => 'pf',
		name      => 'ssh',
		prefix    => 'derp',
		ports     => ['22'],
		protocols => ['tcp'],
		testing   => 1,
	);
	$fw->init_backend;

	is( $fw->check, 1, 'pf check reports healthy in testing mode' );
	is_deeply(
		$fw->{test_data},
		[ 'pfctl -a derp/ssh -t derp_ssh -T show', 'pfctl -a derp/ssh -sr' ],
		'pf check probes both the table and the anchor rules'
	);
}

# --- iptables: check probes sets, INPUT jumps, AND every block rule ----------
{
	my $fw = Net::Firewall::BlockerHelper->new(
		backend   => 'iptables',
		name      => 'ssh',
		prefix    => 'derp',
		ports     => ['22'],
		protocols => ['tcp'],
		testing   => 1,
	);
	$fw->init_backend;

	is( $fw->check, 1, 'iptables check reports healthy in testing mode' );
	is_deeply(
		$fw->{test_data},
		[
			'ipset list derp_ssh_4',
			'ipset list derp_ssh_6',
			'iptables -C INPUT -j derp_ssh',
			'ip6tables -C INPUT -j derp_ssh',
			'iptables -C derp_ssh -m set --match-set derp_ssh_4 src -p tcp -m multiport --dports 22 -j DROP',
			'ip6tables -C derp_ssh -m set --match-set derp_ssh_6 src -p tcp -m multiport --dports 22 -j DROP',
		],
		'iptables check probes the sets, the INPUT jumps, and each block rule'
	);
}

done_testing();
