#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

BEGIN {
	use_ok('Net::Firewall::BlockerHelper') || print "Bail out!\n";
}

sub fw {
	my (%opts) = @_;
	my $fw = Net::Firewall::BlockerHelper->new(
		backend   => $opts{backend},
		name      => 'ssh',
		prefix    => 'kur',
		ports     => ['22'],
		protocols => ['tcp'],
		testing   => 1,
		( $opts{backend} eq 'ipfw' ? ( options => { rule => 150 } ) : () ),
	);
	$fw->init_backend;
	return $fw;
}

# helper: pull the first command out of test_data whether it is a scalar or arrayref
sub first_cmd {
	my ($td) = @_;
	return ref($td) eq 'ARRAY' ? $td->[0] : $td;
}

# --- duplicate bans and unbans of unbanned IPs short-circuit -----------------
foreach my $backend ( 'ipfw', 'pf', 'iptables' ) {
	my $fw = fw( backend => $backend );

	$fw->ban( ban => '1.2.3.4' );
	$fw->ban( ban => '1.2.3.4' );
	is( $fw->{test_data}, 'already banned', $backend . ': double ban short-circuits with already banned' );
	is( scalar( $fw->list ), 1, $backend . ': double ban results in one entry' );

	$fw->unban( ban => '5.6.7.8' );
	is( $fw->{test_data}, 'not banned', $backend . ': unban of unbanned IP short-circuits with not banned' );
	is( scalar( $fw->list ), 1, $backend . ': unban of unbanned IP does not change the ban list' );
}

# --- IPv6 bans are routed correctly per backend ------------------------------
{
	my $fw = fw( backend => 'ipfw' );
	$fw->ban( ban => 'dead::1' );
	is( first_cmd( $fw->{test_data} ), 'ipfw table kur_ssh add dead::1', 'ipfw accepts an IPv6 ban' );
}
{
	my $fw = fw( backend => 'pf' );
	$fw->ban( ban => 'dead::1' );
	is( first_cmd( $fw->{test_data} ), 'pfctl -a kur/ssh -t kur_ssh -T add dead::1', 'pf accepts an IPv6 ban' );
}
{
	my $fw = fw( backend => 'iptables' );
	$fw->ban( ban => 'dead::1' );
	is( first_cmd( $fw->{test_data} ), 'ipset add kur_ssh_6 dead::1', 'iptables routes an IPv6 ban to the inet6 set' );
	$fw->ban( ban => '1.2.3.4' );
	is( first_cmd( $fw->{test_data} ), 'ipset add kur_ssh_4 1.2.3.4', 'iptables routes an IPv4 ban to the inet set' );
}

# --- IPv6 IPs are case-normalized so DEAD::1 and dead::1 are the same ban ----
foreach my $backend ( 'ipfw', 'pf', 'iptables' ) {
	my $fw = fw( backend => $backend );

	$fw->ban( ban => 'DEAD::1' );
	like( first_cmd( $fw->{test_data} ), qr/dead::1$/, $backend . ': uppercase IPv6 ban is lowercased in the command' );

	$fw->ban( ban => 'dead::1' );
	is( $fw->{test_data}, 'already banned', $backend . ': same IPv6 IP in lowercase is seen as already banned' );

	my @banned = $fw->list;
	is_deeply( \@banned, ['dead::1'], $backend . ': list returns the lowercased IPv6 IP' );

	$fw->unban( ban => 'DeAd::1' );
	like( first_cmd( $fw->{test_data} ), qr/dead::1$/, $backend . ': mixed-case IPv6 unban is lowercased and matches' );
	is( scalar( $fw->list ), 0, $backend . ': mixed-case IPv6 unban actually removed the ban' );
}

done_testing();
