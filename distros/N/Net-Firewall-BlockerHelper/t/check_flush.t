#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

BEGIN {
	use_ok('Net::Firewall::BlockerHelper') || print "Bail out!\n";
}

# helper: pull the first command out of test_data whether it is a scalar or arrayref
sub first_cmd {
	my ($td) = @_;
	return ref($td) eq 'ARRAY' ? $td->[0] : $td;
}

# --- dummy: check/flush/stop are deterministic ------------------------------
{
	my $fw = Net::Firewall::BlockerHelper->new(
		backend => 'dummy',
		name    => 'ssh',
		testing => 1,
	);
	$fw->init_backend;
	$fw->ban( ban => '1.2.3.4' );

	is( $fw->check, 1, 'dummy check reports healthy' );
	is( $fw->{test_data}, 'check', 'dummy check set test_data' );

	$fw->flush;
	is( $fw->{test_data}, 'flush', 'dummy flush set test_data' );
	is( scalar( $fw->list ), 0, 'dummy flush emptied the ban list' );

	$fw->stop;
	is( $fw->{test_data}, 'teardown', 'dummy stop aliases teardown' );
}

# --- iptables: check probes the sets, flush flushes them --------------------
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

	is( $fw->check, 1, 'iptables check reports healthy in testing mode' );
	is( first_cmd( $fw->{test_data} ), 'ipset list derp_ssh_4', 'iptables check probes the v4 set' );

	$fw->flush;
	is( first_cmd( $fw->{test_data} ), 'ipset flush derp_ssh_4', 'iptables flush flushes the v4 set' );
	is( scalar( $fw->list ), 0, 'iptables flush emptied the ban list' );
}

# --- ipfw: check probes the table, flush flushes it -------------------------
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

	is( first_cmd( $fw->check && $fw->{test_data} ), 'ipfw table derp_ssh info', 'ipfw check probes the table' );

	$fw->flush;
	is( first_cmd( $fw->{test_data} ), 'ipfw table derp_ssh flush', 'ipfw flush flushes the table' );
	is( scalar( $fw->list ), 0, 'ipfw flush emptied the ban list' );
}

# --- pf: check probes the table, flush flushes it ---------------------------
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

	$fw->check;
	is( first_cmd( $fw->{test_data} ), 'pfctl -a derp/ssh -t derp_ssh -T show', 'pf check probes the table' );

	$fw->flush;
	is( first_cmd( $fw->{test_data} ), 'pfctl -a derp/ssh -t derp_ssh -T flush', 'pf flush flushes the table' );
	is( scalar( $fw->list ), 0, 'pf flush emptied the ban list' );
}

# --- shell: configured check/flush commands ---------------------------------
{
	my $fw = Net::Firewall::BlockerHelper->new(
		backend => 'shell',
		name    => 'derp',
		testing => 1,
		options => {
			init     => 'true',
			teardown => 'true',
			ban      => 'true',
			unban    => 'true',
			check    => 'my-check-cmd',
			flush    => 'my-flush-cmd',
		},
	);
	$fw->init_backend;
	$fw->ban( ban => '1.2.3.4' );

	$fw->check;
	is( $fw->{test_data}, 'my-check-cmd', 'shell check runs the configured check command' );

	$fw->flush;
	is( $fw->{test_data}, 'my-flush-cmd', 'shell flush runs the configured flush command' );
	is( scalar( $fw->list ), 0, 'shell flush emptied the ban list' );
}

# --- shell: no check/flush commands -> healthy + unban-each fallback --------
{
	my $fw = Net::Firewall::BlockerHelper->new(
		backend => 'shell',
		name    => 'derp',
		testing => 1,
		options => {
			init     => 'true',
			teardown => 'true',
			ban      => 'true',
			unban    => 'true',
		},
	);
	$fw->init_backend;
	$fw->ban( ban => '1.2.3.4' );
	$fw->ban( ban => '5.6.7.8' );

	is( $fw->check, 1, 'shell check with no command reports healthy' );

	$fw->flush;
	is( scalar( $fw->list ), 0, 'shell flush without a command falls back to unbanning each' );
}

done_testing();
