#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

BEGIN {
	if ( $^O ne 'freebsd' ) {
		plan skip_all =>
			'ipfw is FreeBSD specific and protocol resolution relies on FreeBSD /etc/protocols entries such as icmp6';
	}
}

BEGIN {
	use_ok('Net::Firewall::BlockerHelper') || print "Bail out!\n";
}

# The ipfw block-all default must cover both IPv4 and IPv6, and a reject
# ('unreach'/'unreach6') must use the family-appropriate keyword for each
# protocol.

sub rules {
	my (%opts) = @_;
	my $fw = Net::Firewall::BlockerHelper->new(
		backend => 'ipfw',
		name    => 'ssh',
		prefix  => 'kur',
		testing => 1,
		%opts,
	);
	$fw->init_backend;
	return grep { / add / } @{ $fw->{test_data}{commands} };
}

# --- default (no protocols, no ports, deny) -> ip4 to me AND ip6 to me6 -----
# in ipfw 'me' only matches IPv4 addresses and 'me6' only IPv6 ones, so the
# destination keyword must match the family of each rule
{
	my @r = rules( options => { rule => 150 } );
	is( scalar(@r), 2, 'default block-all emits two rules' );
	ok( ( grep { $_ eq 'ipfw add 150 deny ip4 from "table(kur_ssh)" to me' } @r ),
		'default has a deny ip4 rule to me (IPv4)' );
	ok( ( grep { $_ eq 'ipfw add 150 deny ip6 from "table(kur_ssh)" to me6' } @r ),
		'default has a deny ip6 rule to me6 (IPv6)' );
	ok( !( grep { /ip6 from .* to me$/ } @r ), 'the ip6 rule is never pointed at the IPv4-only me keyword' );
}

# --- default + type=unreach -> unreach on IPv4, unreach6 on IPv6 ------------
{
	my @r = rules( options => { rule => 150, type => 'unreach' } );
	ok( ( grep { $_ eq 'ipfw add 150 unreach port ip4 from "table(kur_ssh)" to me' } @r ),
		'reject uses unreach for the IPv4 rule' );
	ok( ( grep { $_ eq 'ipfw add 150 unreach6 port ip6 from "table(kur_ssh)" to me6' } @r ),
		'reject uses unreach6 for the IPv6 rule' );
}

# --- an IPv6 protocol under a reject uses unreach6 (was invalid before) -----
{
	my @r = rules( protocols => ['icmp6'], options => { rule => 150, type => 'unreach' } );
	ok( ( grep { $_ eq 'ipfw add 150 unreach6 port icmp6 from "table(kur_ssh)" to me6' } @r ),
		'icmp6 under reject uses unreach6 and me6' );
	ok( !( grep { /unreach port icmp6/ } @r ),
		'icmp6 is never given the IPv4 unreach keyword' );
}

# --- legacy type=unreach6 still accepted, behaves as a reject --------------
{
	my @r = rules( options => { rule => 150, type => 'unreach6' } );
	ok( ( grep { $_ eq 'ipfw add 150 unreach port ip4 from "table(kur_ssh)" to me' } @r ),
		'type=unreach6 still emits a valid IPv4 rule (treated as reject)' );
	ok( ( grep { $_ eq 'ipfw add 150 unreach6 port ip6 from "table(kur_ssh)" to me6' } @r ),
		'type=unreach6 emits a valid IPv6 rule' );
}

# --- family neutral protocols get one rule per family -----------------------
{
	my @r = rules( protocols => ['tcp'], options => { rule => 150 } );
	is_deeply(
		[@r],
		[
			'ipfw add 150 deny tcp from "table(kur_ssh)" to me',
			'ipfw add 150 deny tcp from "table(kur_ssh)" to me6',
		],
		'explicit tcp + deny emits both a me and a me6 rule'
	);
}

# --- family specific protocols only get the rule for their family -----------
{
	my @r = rules( protocols => ['icmp'], options => { rule => 150 } );
	is_deeply( [@r], ['ipfw add 150 deny icmp from "table(kur_ssh)" to me'],
		'icmp only gets a IPv4 rule to me' );
}

done_testing();
