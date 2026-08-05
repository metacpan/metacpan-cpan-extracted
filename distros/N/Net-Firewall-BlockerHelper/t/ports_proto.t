#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

BEGIN {
	use_ok('Net::Firewall::BlockerHelper') || print "Bail out!\n";
}

# Ports must only ever be attached to port-capable protocols (tcp/udp/sctp).
# When ports are given without protocols the backends default to tcp/udp
# rather than a protocol that cannot carry a port.

# --- ipfw: ports but no protocols -> tcp + udp, both with the port ----------
{
	my $fw = Net::Firewall::BlockerHelper->new(
		backend => 'ipfw',
		name    => 'ssh',
		prefix  => 'kur',
		ports   => ['22'],
		options => { rule => 150 },
		testing => 1,
	);
	$fw->init_backend;
	my @rules = grep { /add / } @{ $fw->{test_data}{commands} };
	is( scalar(@rules), 4, 'ipfw ports-only produces four rules, one per family per protocol' );
	ok( ( grep { $_ eq 'ipfw add 150 deny tcp from "table(kur_ssh)" to me 22' } @rules ),
		'ipfw ports-only has a IPv4 tcp rule with the port' );
	ok( ( grep { $_ eq 'ipfw add 150 deny tcp from "table(kur_ssh)" to me6 22' } @rules ),
		'ipfw ports-only has a IPv6 tcp rule with the port' );
	ok( ( grep { $_ eq 'ipfw add 150 deny udp from "table(kur_ssh)" to me 22' } @rules ),
		'ipfw ports-only has a IPv4 udp rule with the port' );
	ok( ( grep { $_ eq 'ipfw add 150 deny udp from "table(kur_ssh)" to me6 22' } @rules ),
		'ipfw ports-only has a IPv6 udp rule with the port' );
	ok( !( grep { /deny ip / } @rules ), 'ipfw ports-only does not emit an ip rule' );
}

# --- ipfw: explicit tcp + icmp + ports -> icmp rule has no port -------------
{
	my $fw = Net::Firewall::BlockerHelper->new(
		backend   => 'ipfw',
		name      => 'ssh',
		prefix    => 'kur',
		protocols => [ 'tcp', 'icmp' ],
		ports     => ['22'],
		options   => { rule => 150 },
		testing   => 1,
	);
	$fw->init_backend;
	my @rules = grep { /add / } @{ $fw->{test_data}{commands} };
	ok( ( grep { $_ eq 'ipfw add 150 deny tcp from "table(kur_ssh)" to me 22' } @rules ),
		'ipfw tcp rule keeps the port' );
	ok( ( grep { $_ eq 'ipfw add 150 deny tcp from "table(kur_ssh)" to me6 22' } @rules ),
		'ipfw tcp also gets a IPv6 rule with the port' );
	ok( ( grep { $_ eq 'ipfw add 150 deny icmp from "table(kur_ssh)" to me' } @rules ),
		'ipfw icmp rule is emitted without a port' );
	ok( !( grep { /icmp from .* to me6/ } @rules ), 'ipfw icmp gets no IPv6 rule' );
}

# --- pf: ports but no protocols -> tcp/udp only, no icmp lines --------------
{
	my $fw = Net::Firewall::BlockerHelper->new(
		backend => 'pf',
		name    => 'ssh',
		prefix  => 'kur',
		ports   => [ '22', '143' ],
		testing => 1,
	);
	$fw->init_backend;
	my $rules = $fw->{test_data}{commands}[1];
	like( $rules, qr/proto tcp from <kur_ssh> to any port 22/, 'pf ports-only has a tcp port rule' );
	like( $rules, qr/proto udp from <kur_ssh> to any port 143/, 'pf ports-only has a udp port rule' );
	unlike( $rules, qr/proto icmp/,  'pf ports-only emits no icmp rule' );
	unlike( $rules, qr/proto icmp6/, 'pf ports-only emits no icmp6 rule' );
}

# --- iptables: sctp is port-capable, icmp gets no port ----------------------
{
	my $fw = Net::Firewall::BlockerHelper->new(
		backend   => 'iptables',
		name      => 'ssh',
		prefix    => 'kur',
		protocols => [ 'sctp', 'icmp' ],
		ports     => ['22'],
		testing   => 1,
	);
	$fw->init_backend;
	my @rules = grep { / -A kur_ssh / } @{ $fw->{test_data}{commands} };
	ok( ( grep { $_ eq 'iptables -A kur_ssh -m set --match-set kur_ssh_4 src -p sctp -m multiport --dports 22 -j DROP' }
			@rules ),
		'iptables sctp rule keeps the port'
	);
	ok( ( grep { $_ eq 'iptables -A kur_ssh -m set --match-set kur_ssh_4 src -p icmp -j DROP' } @rules ),
		'iptables icmp rule is emitted without a port' );
}

# --- iptables: IPv6 icmp aliases never land in the v4 table, and vice versa --
{
	my $fw = Net::Firewall::BlockerHelper->new(
		backend   => 'iptables',
		name      => 'ssh',
		prefix    => 'kur',
		protocols => [ 'ipv6-icmp', 'icmp' ],
		testing   => 1,
	);
	$fw->init_backend;
	my @rules = grep { / -A kur_ssh / } @{ $fw->{test_data}{commands} };
	ok( !( grep { /^iptables .*-p ipv6-icmp/ } @rules ),  'ipv6-icmp is not given to iptables (v4)' );
	ok( ( grep { /^ip6tables .*-p ipv6-icmp/ } @rules ),  'ipv6-icmp is given to ip6tables' );
	ok( ( grep { /^iptables .*-p icmp -j/ } @rules ),     'icmp is given to iptables (v4)' );
	ok( !( grep { /^ip6tables .*-p icmp -j/ } @rules ),   'icmp is not given to ip6tables' );
}

# --- iptables: reject type uses the family-correct reject-with --------------
{
	my $fw = Net::Firewall::BlockerHelper->new(
		backend   => 'iptables',
		name      => 'ssh',
		prefix    => 'kur',
		protocols => ['tcp'],
		ports     => ['22'],
		options   => { type => 'reject' },
		testing   => 1,
	);
	$fw->init_backend;
	my @rules = grep { / -A kur_ssh / } @{ $fw->{test_data}{commands} };
	ok( ( grep { /^iptables .*-j REJECT --reject-with icmp-port-unreachable$/ } @rules ),
		'iptables reject uses icmp-port-unreachable for IPv4' );
	ok( ( grep { /^ip6tables .*-j REJECT --reject-with icmp6-port-unreachable$/ } @rules ),
		'ip6tables reject uses icmp6-port-unreachable for IPv6' );
	ok( !( grep { /-j DROP/ } @rules ), 'no DROP rules are emitted under reject' );
}

# --- pf: no ports or protocols -> the tcp/udp/icmp/icmp6 default -------------
{
	my $fw = Net::Firewall::BlockerHelper->new(
		backend => 'pf',
		name    => 'ssh',
		prefix  => 'kur',
		testing => 1,
	);
	$fw->init_backend;
	my $rules = $fw->{test_data}{commands}[1];
	foreach my $proto ( 'tcp', 'udp', 'icmp', 'icmp6' ) {
		like( $rules, qr/block drop quick proto $proto from <kur_ssh> to any\n/,
			'pf block-all default has a ' . $proto . ' rule without a port' );
	}
	unlike( $rules, qr/port/, 'pf block-all default emits no port matches' );
}

# --- pf: explicit tcp + icmp + ports -> icmp line has no port ---------------
{
	my $fw = Net::Firewall::BlockerHelper->new(
		backend   => 'pf',
		name      => 'ssh',
		prefix    => 'kur',
		protocols => [ 'tcp', 'icmp' ],
		ports     => ['22'],
		testing   => 1,
	);
	$fw->init_backend;
	my $rules = $fw->{test_data}{commands}[1];
	like( $rules, qr/proto tcp from <kur_ssh> to any port 22/, 'pf tcp rule keeps the port' );
	like( $rules, qr/proto icmp from <kur_ssh> to any\n/, 'pf icmp rule has no port' );
	unlike( $rules, qr/proto icmp from <kur_ssh> to any port/, 'pf icmp rule is not given a port' );
}

done_testing();
