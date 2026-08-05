#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

BEGIN {
	use_ok('Net::Firewall::BlockerHelper') || print "Bail out!\n";
}

# Teardown ordering matters: iptables must remove the INPUT jump before
# flushing and deleting the chain, and the chain before destroying the sets.
# re_init must re-add every currently banned IP after rebuilding.

# --- iptables ---------------------------------------------------------------
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
	$fw->ban( ban => '1.2.3.4' );
	$fw->ban( ban => 'dead::1' );

	$fw->re_init;
	is_deeply(
		[ sort @{ $fw->{test_data} } ],
		[ 'ipset add derp_ssh_4 1.2.3.4', 'ipset add derp_ssh_6 dead::1' ],
		'iptables re_init re-adds every banned IP to the correct set'
	);

	$fw->teardown;
	is_deeply(
		$fw->{test_data},
		[
			'iptables -D INPUT -j derp_ssh',
			'ip6tables -D INPUT -j derp_ssh',
			'iptables -F derp_ssh',
			'ip6tables -F derp_ssh',
			'iptables -X derp_ssh',
			'ip6tables -X derp_ssh',
			'ipset destroy derp_ssh_4',
			'ipset destroy derp_ssh_6',
		],
		'iptables teardown removes the jump, then the chain, then the sets'
	);
}

# --- ipfw --------------------------------------------------------------------
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
	$fw->ban( ban => '1.2.3.4' );
	$fw->ban( ban => '5.6.7.8' );

	$fw->re_init;
	is_deeply(
		[ sort @{ $fw->{test_data} } ],
		[ 'ipfw table derp_ssh add 1.2.3.4', 'ipfw table derp_ssh add 5.6.7.8' ],
		'ipfw re_init re-adds every banned IP to the table'
	);

	$fw->teardown;
	is_deeply(
		$fw->{test_data},
		[ 'ipfw table derp_ssh destroy', 'ipfw delete 150' ],
		'ipfw teardown destroys the table and deletes the rule'
	);
}

# --- pf ----------------------------------------------------------------------
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
	$fw->ban( ban => '1.2.3.4' );
	$fw->ban( ban => 'dead::1' );

	$fw->re_init;
	is_deeply(
		[ sort @{ $fw->{test_data} } ],
		[ 'pfctl -a derp/ssh -t derp_ssh -T add 1.2.3.4', 'pfctl -a derp/ssh -t derp_ssh -T add dead::1' ],
		'pf re_init re-adds every banned IP to the table'
	);

	$fw->teardown;
	is_deeply(
		$fw->{test_data},
		[
			'pfctl -a derp/ssh -t derp_ssh -T flush',
			'pfctl -a derp/ssh -t derp_ssh -T kill',
			'pfctl -a derp/ssh -F rules',
		],
		'pf teardown flushes and kills the table, then flushes the anchor rules'
	);
}

done_testing();
