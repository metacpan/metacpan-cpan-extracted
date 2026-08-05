#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

BEGIN {
	use_ok('Net::Firewall::BlockerHelper') || print "Bail out!\n";
}

# The iptables backend gains two xtables-addons targets, tarpit and delude.
# Both are TCP only, so no matter how they are configured they must only ever
# emit "-p tcp" rules and must never hand udp/icmp/etc to the target.

# grab just the chain-populating rules from an inited backend's test data
sub rules_for {
	my (%args) = @_;
	my $fw = Net::Firewall::BlockerHelper->new(
		backend => 'iptables',
		name    => 'ssh',
		prefix  => 'derp',
		testing => 1,
		%args,
	);
	$fw->init_backend;
	# filter chain rules only, not the raw table notrack rules
	return grep { / -A derp_ssh / && !/ -t raw / } @{ $fw->{test_data}{commands} };
}

# --- tarpit, nothing else configured -> one -p tcp TARPIT rule per family ----
{
	my @rules = rules_for( options => { type => 'tarpit' } );
	is( scalar(@rules), 2, 'tarpit with no ports/protos is one rule per family' );
	ok( ( grep { $_ eq 'iptables -A derp_ssh -m set --match-set derp_ssh_4 src -p tcp -j TARPIT' } @rules ),
		'tarpit emits an IPv4 -p tcp TARPIT rule' );
	ok( ( grep { $_ eq 'ip6tables -A derp_ssh -m set --match-set derp_ssh_6 src -p tcp -j TARPIT' } @rules ),
		'tarpit emits an IPv6 -p tcp TARPIT rule' );
	ok( !( grep { / -j TARPIT$/ && $_ !~ /-p tcp/ } @rules ), 'tarpit never emits a rule without -p tcp' );
}

# --- tarpit honeypot mode appends --honeypot ---------------------------------
{
	my @rules = rules_for( options => { type => 'tarpit', tarpit_mode => 'honeypot' }, ports => ['22'] );
	ok( ( grep { $_ eq 'iptables -A derp_ssh -m set --match-set derp_ssh_4 src -p tcp -m multiport --dports 22 -j TARPIT --honeypot' } @rules ),
		'tarpit honeypot mode appends --honeypot with the port' );
}

# --- tarpit/delude are tcp only: udp in the mix is dropped -------------------
{
	my @rules = rules_for( options => { type => 'delude' }, protocols => [ 'tcp', 'udp' ], ports => ['80'] );
	ok( ( grep { $_ eq 'iptables -A derp_ssh -m set --match-set derp_ssh_4 src -p tcp -m multiport --dports 80 -j DELUDE' } @rules ),
		'delude keeps the tcp rule' );
	ok( !( grep { /-p udp/ } @rules ), 'delude drops the udp rule entirely' );
	# xtables-addons provides no IPv6 DELUDE target, so v6 falls back to DROP
	# so banned IPv6 IPs are still blocked
	ok( ( grep { $_ eq 'ip6tables -A derp_ssh -m set --match-set derp_ssh_6 src -p tcp -m multiport --dports 80 -j DROP' } @rules ),
		'delude gives the IPv6 rule a DROP fallback' );
	ok( !( grep { /^ip6tables.*DELUDE/ } @rules ), 'delude never emits an ip6tables DELUDE rule' );
}

# --- the delude v6 DROP fallback gets no notrack rule ------------------------
{
	my $fw = Net::Firewall::BlockerHelper->new(
		backend => 'iptables',
		name    => 'ssh',
		prefix  => 'derp',
		testing => 1,
		options => { type => 'delude' },
	);
	$fw->init_backend;
	my @notrack = grep { / -t raw / && /CT --notrack/ } @{ $fw->{test_data}{commands} };
	is( scalar(@notrack), 1, 'delude has only the IPv4 notrack rule' );
	ok( !( grep { /^ip6tables/ } @notrack ), 'the DROP fallback is not exempted from conntrack' );
}

# --- ports without protocols default to tcp only (not tcp+udp) ---------------
{
	my @rules = rules_for( options => { type => 'tarpit' }, ports => ['22'] );
	ok( !( grep { /-p udp/ } @rules ), 'tarpit ports-only does not fall back to udp' );
	is( scalar( grep { /-p tcp/ } @rules ), 2, 'tarpit ports-only is tcp per family' );
}

# --- tarpit/delude add raw-table CT --notrack rules matching the block rules -
{
	my $fw = Net::Firewall::BlockerHelper->new(
		backend => 'iptables',
		name    => 'ssh',
		prefix  => 'derp',
		ports   => ['22'],
		testing => 1,
		options => { type => 'tarpit' },
	);
	$fw->init_backend;

	my @cmds     = @{ $fw->{test_data}{commands} };
	my @notrack  = grep { / -t raw / && /CT --notrack/ } @cmds;
	is( scalar(@notrack), 2, 'one notrack rule per family' );
	ok(
		(
			grep {
				$_ eq
					'iptables -t raw -A derp_ssh -m set --match-set derp_ssh_4 src -p tcp -m multiport --dports 22 -j CT --notrack'
			} @notrack
		),
		'the notrack rule matches the same src set, tcp, and dports as the block rule'
	);
	ok( ( grep { $_ eq 'iptables -t raw -A PREROUTING -j derp_ssh' } @cmds ), 'raw chain jumped from PREROUTING' );

	# the raw chain must be torn down before the ipsets it references
	$fw->teardown;
	my @td      = @{ $fw->{test_data} };
	my ($raw_x) = grep { $td[$_] eq 'iptables -t raw -X derp_ssh' } 0 .. $#td;
	my ($destroy) = grep { $td[$_] eq 'ipset destroy derp_ssh_4' } 0 .. $#td;
	ok( defined($raw_x) && defined($destroy) && $raw_x < $destroy,
		'raw chain removed before the ipsets are destroyed' );

	# and the same ordering holds for init's stale state cleanup, so re_init
	# can recover from a teardown that died part way through
	$fw->{backend_obj}->init;
	my @fo = @{ $fw->{test_data}{fail_okay_commands} };
	my ($fo_raw_x) = grep { $fo[$_] eq 'iptables -t raw -X derp_ssh' } 0 .. $#fo;
	my ($fo_destroy) = grep { $fo[$_] eq 'ipset destroy derp_ssh_4' } 0 .. $#fo;
	ok( defined($fo_raw_x) && defined($fo_destroy) && $fo_raw_x < $fo_destroy,
		'init stale cleanup also removes the raw chain before destroying the ipsets' );
}

# --- plain drop/reject add NO raw rules -------------------------------------
{
	my $fw = Net::Firewall::BlockerHelper->new(
		backend => 'iptables', name => 'ssh', prefix => 'derp', testing => 1,
		options => { type => 'drop' },
	);
	$fw->init_backend;
	ok( !( grep { / -t raw / } @{ $fw->{test_data}{commands} } ), 'drop emits no raw table rules' );
}

# --- an unknown type is rejected --------------------------------------------
{
	my $died = 0;
	eval {
		my $fw = Net::Firewall::BlockerHelper->new(
			backend => 'iptables',
			name    => 'ssh',
			testing => 1,
			options => { type => 'bogus' },
		);
		$fw->init_backend;
	};
	$died = 1 if ($@);
	ok( $died, 'an invalid type dies' );
}

done_testing();
