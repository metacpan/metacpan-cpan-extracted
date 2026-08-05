#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

BEGIN {
	use_ok('Net::Firewall::BlockerHelper') || print "Bail out!\n";
}

# The kill commands are best-effort extras run after a ban. They must be
# recorded rather than executed in testing mode, and must be family correct
# for both IPv4 and IPv6.

# --- ipfw: tcpdrop pipeline per family ----------------------------------------
{
	my $fw = Net::Firewall::BlockerHelper->new(
		backend => 'ipfw',
		name    => 'ssh',
		prefix  => 'kur',
		options => { rule => 150, kill => 1 },
		testing => 1,
	);
	$fw->init_backend;

	$fw->ban( ban => '1.2.3.4' );
	is( $fw->{test_data}[1],
		'sockstat -nc4 -P tcp |sed "s/.*tcp[46]  *//" | sed "s/:/ /g" | grep -wF 1.2.3.4 | xargs -n 4 tcpdrop',
		'ipfw IPv4 kill uses sockstat -nc4 and a plain colon split' );

	$fw->ban( ban => 'dead::1' );
	is( $fw->{test_data}[1],
		'sockstat -nc6 -P tcp |sed "s/.*tcp[46]  *//" | grep -E "(^|[[:space:]])dead::1:[0-9]+([[:space:]]|\$)" | sed "s/%[a-zA-Z0-9]*//g" | sed -E "s/:([0-9]+)([[:space:]]|\$)/ \1\2/g" | xargs -n 4 tcpdrop',
		'ipfw IPv6 kill uses sockstat -nc6, splits only the port colon, and strips scope IDs'
	);
}

# --- pf: kill without ports kills all state for the IP, both families ---------
{
	my $fw = Net::Firewall::BlockerHelper->new(
		backend => 'pf',
		name    => 'ssh',
		prefix  => 'kur',
		options => { kill => 1 },
		testing => 1,
	);
	$fw->init_backend;

	$fw->ban( ban => '1.2.3.4' );
	is_deeply(
		$fw->{test_data},
		[ 'pfctl -a kur/ssh -t kur_ssh -T add 1.2.3.4', 'pfctl -k 1.2.3.4' ],
		'pf IPv4 kill without ports records the ban and the pfctl -k command'
	);
	unlike( $fw->{test_data}[1], qr/tcp|udp/,
		'pfctl -k is not protocol filtered, so UDP states are killed as well' );

	$fw->ban( ban => 'dead::1' );
	is_deeply(
		$fw->{test_data},
		[ 'pfctl -a kur/ssh -t kur_ssh -T add dead::1', 'pfctl -k dead::1' ],
		'pf IPv6 kill without ports also uses pfctl -k'
	);
}

# --- pf: kill with ports matches the family-specific state format -------------
# pf prints IPv4 states as addr:port but IPv6 ones as addr[port]
{
	my $fw = Net::Firewall::BlockerHelper->new(
		backend   => 'pf',
		name      => 'ssh',
		prefix    => 'kur',
		ports     => ['22'],
		protocols => ['tcp'],
		options   => { kill => 1 },
		testing   => 1,
	);
	$fw->init_backend;

	$fw->ban( ban => '1.2.3.4' );
	is( scalar( @{ $fw->{test_data} } ), 2, 'one kill command per port after the ban command' );
	like( $fw->{test_data}[1], qr/^pfctl -s state/,       'the IPv4 kill command inspects pf state' );
	like( $fw->{test_data}[1], qr/grep -wE "\(tcp\)"/,    'the kill is scoped to the blocked protocols' );
	like( $fw->{test_data}[1], qr/":22 "/,                'IPv4 states are matched as addr:port' );
	like( $fw->{test_data}[1], qr/1\\\.2\\\.3\\\.4/,      'the IPv4 IP has its dots escaped for grep' );
	like( $fw->{test_data}[1], qr/pfctl -k id -k $/,      'IPv4 state entries are killed by ID' );
	unlike( $fw->{test_data}[1], qr/udp/, 'blocking only tcp means UDP states are left alone' );

	$fw->ban( ban => 'dead::1' );
	is( $fw->{test_data}[1],
		'pfctl -s state -vv 2> /dev/null | grep -E \'<*->*|id:\'  | paste - - | grep -wE "(tcp)" | grep -F "[22] " | grep -F " dead::1[" | sed  "s/.*[\ \t]id:[\ \t]//" | cut -d " " -f 1 | paste -s - | xargs -n 1 pfctl -k id -k ',
		'pf IPv6 kill matches the addr[port] state format as fixed strings'
	);
}

# --- pf: blocking only udp kills only udp states -------------------------------
{
	my $fw = Net::Firewall::BlockerHelper->new(
		backend   => 'pf',
		name      => 'dns',
		prefix    => 'kur',
		ports     => ['53'],
		protocols => ['udp'],
		options   => { kill => 1 },
		testing   => 1,
	);
	$fw->init_backend;
	$fw->ban( ban => '1.2.3.4' );
	like( $fw->{test_data}[1], qr/grep -wE "\(udp\)"/, 'pf udp-only kill is scoped to udp' );
	like( $fw->{test_data}[1], qr/":53 "/,             'pf udp-only kill keeps the port scoping' );
	unlike( $fw->{test_data}[1], qr/tcp/, 'pf udp-only kill never touches tcp states' );
}
{
	my $fw = Net::Firewall::BlockerHelper->new(
		backend   => 'pf',
		name      => 'dns',
		prefix    => 'kur',
		protocols => ['udp'],
		options   => { kill => 1 },
		testing   => 1,
	);
	$fw->init_backend;
	$fw->ban( ban => '1.2.3.4' );
	is( $fw->{test_data}[1],
		'pfctl -s state -vv 2> /dev/null | grep -E \'<*->*|id:\'  | paste - - | grep -wE "(udp)" | grep -E "[[ ]1\\.2\\.3\\.4]*:" | sed  "s/.*[\ \t]id:[\ \t]//" | cut -d " " -f 1 | paste -s - | xargs -n 1 pfctl -k id -k ',
		'pf udp-only without ports kills udp states via the state table rather than pfctl -k'
	);
}

# --- iptables/firewalld/nftables: conntrack needs -f ipv6 for IPv6 IPs --------
foreach my $backend ( 'iptables', 'firewalld', 'nftables' ) {
	my $fw = Net::Firewall::BlockerHelper->new(
		backend => $backend,
		name    => 'ssh',
		prefix  => 'kur',
		options => { kill => 1 },
		testing => 1,
	);
	$fw->init_backend;

	$fw->ban( ban => '1.2.3.4' );
	is( $fw->{test_data}[1], 'conntrack -D -s 1.2.3.4', $backend . ': IPv4 conntrack kill uses the default family' );
	unlike( $fw->{test_data}[1], qr/-p |--proto/,
		$backend . ': conntrack kill is not protocol filtered, so UDP entries are dropped as well' );

	$fw->ban( ban => 'dead::1' );
	is( $fw->{test_data}[1],
		'conntrack -f ipv6 -D -s dead::1',
		$backend . ': IPv6 conntrack kill specifies the ipv6 family' );
}

# --- conntrack kills are scoped to the blocked protocols -----------------------
foreach my $backend ( 'iptables', 'firewalld', 'nftables' ) {
	my $fw = Net::Firewall::BlockerHelper->new(
		backend   => $backend,
		name      => 'dns',
		prefix    => 'kur',
		ports     => ['53'],
		protocols => ['udp'],
		options   => { kill => 1 },
		testing   => 1,
	);
	$fw->init_backend;

	$fw->ban( ban => '1.2.3.4' );
	is( scalar( @{ $fw->{test_data} } ), 2, $backend . ': udp-only produces one scoped kill command' );
	is( $fw->{test_data}[1], 'conntrack -D -p udp -s 1.2.3.4', $backend . ': udp-only kill is scoped via -p udp' );

	$fw->ban( ban => 'dead::1' );
	is( $fw->{test_data}[1],
		'conntrack -f ipv6 -D -p udp -s dead::1',
		$backend . ': udp-only IPv6 kill is scoped and family correct' );
}
{
	my $fw = Net::Firewall::BlockerHelper->new(
		backend   => 'iptables',
		name      => 'ssh',
		prefix    => 'kur',
		protocols => [ 'tcp', 'udp' ],
		options   => { kill => 1 },
		testing   => 1,
	);
	$fw->init_backend;
	$fw->ban( ban => '1.2.3.4' );
	is_deeply(
		[ @{ $fw->{test_data} }[ 1, 2 ] ],
		[ 'conntrack -D -p tcp -s 1.2.3.4', 'conntrack -D -p udp -s 1.2.3.4' ],
		'blocking tcp and udp produces one scoped kill command per protocol'
	);
}
{
	# ports without protocols means tcp and udp are being blocked
	my $fw = Net::Firewall::BlockerHelper->new(
		backend => 'iptables',
		name    => 'ssh',
		prefix  => 'kur',
		ports   => ['22'],
		options => { kill => 1 },
		testing => 1,
	);
	$fw->init_backend;
	$fw->ban( ban => '1.2.3.4' );
	is_deeply(
		[ @{ $fw->{test_data} }[ 1, 2 ] ],
		[ 'conntrack -D -p tcp -s 1.2.3.4', 'conntrack -D -p udp -s 1.2.3.4' ],
		'ports without protocols scopes the kill to tcp and udp'
	);
}

# --- the inverse: blocking only tcp kills only tcp and leaves udp alone ---------
foreach my $backend ( 'iptables', 'firewalld', 'nftables' ) {
	my $fw = Net::Firewall::BlockerHelper->new(
		backend   => $backend,
		name      => 'ssh',
		prefix    => 'kur',
		ports     => ['22'],
		protocols => ['tcp'],
		options   => { kill => 1 },
		testing   => 1,
	);
	$fw->init_backend;

	$fw->ban( ban => '1.2.3.4' );
	is( scalar( @{ $fw->{test_data} } ), 2, $backend . ': tcp-only produces one scoped kill command' );
	is( $fw->{test_data}[1], 'conntrack -D -p tcp -s 1.2.3.4', $backend . ': tcp-only kill is scoped via -p tcp' );
	unlike( $fw->{test_data}[1], qr/udp/, $backend . ': tcp-only kill never touches udp entries' );

	$fw->ban( ban => 'dead::1' );
	is( $fw->{test_data}[1],
		'conntrack -f ipv6 -D -p tcp -s dead::1',
		$backend . ': tcp-only IPv6 kill is scoped and family correct' );
}
{
	my $fw = Net::Firewall::BlockerHelper->new(
		backend   => 'ufw',
		name      => 'ssh',
		protocols => ['tcp'],
		options   => { kill => 'conntrack' },
		testing   => 1,
	);
	$fw->init_backend;
	$fw->ban( ban => '1.2.3.4' );
	is( $fw->{test_data}[-1], 'conntrack -D -p tcp -s 1.2.3.4', 'ufw conntrack kill for tcp-only is scoped via -p tcp' );
}
{
	my $fw = Net::Firewall::BlockerHelper->new(
		backend   => 'pf',
		name      => 'ssh',
		prefix    => 'kur',
		protocols => ['tcp'],
		options   => { kill => 1 },
		testing   => 1,
	);
	$fw->init_backend;
	$fw->ban( ban => '1.2.3.4' );
	is( $fw->{test_data}[1],
		'pfctl -s state -vv 2> /dev/null | grep -E \'<*->*|id:\'  | paste - - | grep -wE "(tcp)" | grep -E "[[ ]1\\.2\\.3\\.4]*:" | sed  "s/.*[\ \t]id:[\ \t]//" | cut -d " " -f 1 | paste -s - | xargs -n 1 pfctl -k id -k ',
		'pf tcp-only without ports kills tcp states via the state table, leaving udp states alone'
	);
	unlike( $fw->{test_data}[1], qr/udp/, 'pf tcp-only kill never touches udp states' );
}
{
	my $fw = Net::Firewall::BlockerHelper->new(
		backend   => 'ipfw',
		name      => 'ssh',
		prefix    => 'kur',
		protocols => ['tcp'],
		options   => { rule => 150, kill => 1 },
		testing   => 1,
	);
	$fw->init_backend;
	$fw->ban( ban => '1.2.3.4' );
	is( scalar( @{ $fw->{test_data} } ), 2, 'ipfw tcp-only runs exactly one kill command' );
	like( $fw->{test_data}[1], qr/tcpdrop$/, 'ipfw tcp-only kill runs tcpdrop' );
	unlike( $fw->{test_data}[1], qr/udp/, 'ipfw tcp-only kill never touches udp' );
}

# --- ipfw: tcpdrop only runs when tcp is being blocked --------------------------
{
	my $fw = Net::Firewall::BlockerHelper->new(
		backend   => 'ipfw',
		name      => 'dns',
		prefix    => 'kur',
		ports     => ['53'],
		protocols => ['udp'],
		options   => { rule => 150, kill => 1 },
		testing   => 1,
	);
	$fw->init_backend;
	$fw->ban( ban => '1.2.3.4' );
	is( scalar( @{ $fw->{test_data} } ), 1, 'ipfw udp-only kill runs no tcpdrop, as there is nothing it could kill' );
}
{
	my $fw = Net::Firewall::BlockerHelper->new(
		backend   => 'ipfw',
		name      => 'ssh',
		prefix    => 'kur',
		protocols => [ 'tcp', 'udp' ],
		options   => { rule => 150, kill => 1 },
		testing   => 1,
	);
	$fw->init_backend;
	$fw->ban( ban => '1.2.3.4' );
	like( $fw->{test_data}[1], qr/tcpdrop$/, 'ipfw runs tcpdrop when tcp is among the blocked protocols' );
}

# --- ufw: both kill modes are scoped to the blocked protocols -------------------
{
	my $fw = Net::Firewall::BlockerHelper->new(
		backend   => 'ufw',
		name      => 'dns',
		ports     => ['53'],
		protocols => ['udp'],
		options   => { kill => 'ss' },
		testing   => 1,
	);
	$fw->init_backend;
	$fw->ban( ban => '1.2.3.4' );
	is( $fw->{test_data}[-1], 'ss -K -u dst "[1.2.3.4]"', 'ufw ss kill for udp-only uses -u' );
}
{
	my $fw = Net::Firewall::BlockerHelper->new(
		backend   => 'ufw',
		name      => 'ssh',
		protocols => ['tcp'],
		options   => { kill => 'ss' },
		testing   => 1,
	);
	$fw->init_backend;
	$fw->ban( ban => '1.2.3.4' );
	is( $fw->{test_data}[-1], 'ss -K -t dst "[1.2.3.4]"', 'ufw ss kill for tcp-only uses -t' );
}
{
	# gre is blockable by ufw but not killable by ss, so no ss command at all
	my $fw = Net::Firewall::BlockerHelper->new(
		backend   => 'ufw',
		name      => 'gre',
		protocols => ['gre'],
		options   => { kill => 'ss' },
		testing   => 1,
	);
	$fw->init_backend;
	$fw->ban( ban => '1.2.3.4' );
	is( scalar( @{ $fw->{test_data} } ), 1, 'ufw ss kill emits nothing when neither tcp nor udp is blocked' );
}
{
	my $fw = Net::Firewall::BlockerHelper->new(
		backend   => 'ufw',
		name      => 'dns',
		protocols => ['udp'],
		options   => { kill => 'conntrack' },
		testing   => 1,
	);
	$fw->init_backend;
	$fw->ban( ban => '1.2.3.4' );
	is( $fw->{test_data}[-1], 'conntrack -D -p udp -s 1.2.3.4', 'ufw conntrack kill for udp-only is scoped via -p udp' );
}

# --- ufw: both kill modes are family correct ----------------------------------
{
	my $fw = Net::Firewall::BlockerHelper->new(
		backend => 'ufw',
		name    => 'ssh',
		options => { kill => 'conntrack' },
		testing => 1,
	);
	$fw->init_backend;
	$fw->ban( ban => '1.2.3.4' );
	is( $fw->{test_data}[-1], 'conntrack -D -s 1.2.3.4', 'ufw IPv4 conntrack kill uses the default family' );
	$fw->ban( ban => 'dead::1' );
	is( $fw->{test_data}[-1], 'conntrack -f ipv6 -D -s dead::1', 'ufw IPv6 conntrack kill specifies the family' );
}
{
	my $fw = Net::Firewall::BlockerHelper->new(
		backend => 'ufw',
		name    => 'ssh',
		options => { kill => 'ss' },
		testing => 1,
	);
	$fw->init_backend;
	$fw->ban( ban => '1.2.3.4' );
	is( $fw->{test_data}[-1], 'ss -K -tu dst "[1.2.3.4]"',
		'ufw IPv4 ss kill brackets the IP and covers both TCP and UDP via -tu' );
	$fw->ban( ban => 'dead::1' );
	is( $fw->{test_data}[-1], 'ss -K -tu dst "[dead::1]"',
		'ufw IPv6 ss kill brackets the IP and covers both TCP and UDP via -tu' );
}

done_testing();
