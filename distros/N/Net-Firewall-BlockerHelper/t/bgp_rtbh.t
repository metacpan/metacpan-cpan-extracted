#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

BEGIN {
	use_ok('Net::Firewall::BlockerHelper') || print "Bail out!\n";
}

# Locates the passed command portably, scanning PATH plus the usual bin,
# sbin, and libexec dirs in case of a sparse PATH or a daemon packaged under
# libexec.
sub find_bin {
	my ($name) = @_;
	require Config;
	my @dirs = split( /\Q$Config::Config{path_sep}\E/, defined( $ENV{PATH} ) ? $ENV{PATH} : '' );
	push( @dirs,
		'/usr/bin',     '/bin',  '/usr/local/bin',  '/usr/sbin',
		'/sbin',        '/usr/local/sbin', '/usr/libexec', '/usr/local/libexec' );
	foreach my $dir (@dirs) {
		next if ( !defined($dir) || $dir eq '' );
		my $path = $dir . '/' . $name;
		return $path if ( -f $path && -x $path );
	}
	return undef;
} ## end sub find_bin

sub write_file {
	my ( $path, $content ) = @_;
	open( my $fh, '>', $path ) or die( 'could not write "' . $path . '"... ' . $! );
	print( $fh $content );
	close($fh);
}

# a kernel assigned TCP port, being portable, unlike parsing the likes of ss
# or netstat for a free one
sub free_port {
	require IO::Socket::INET;
	my $sock = IO::Socket::INET->new(
		LocalAddr => '127.0.0.1',
		LocalPort => 0,
		Proto     => 'tcp',
		Listen    => 1
	);
	return undef if ( !$sock );
	my $port = $sock->sockport;
	close($sock);
	return $port;
} ## end sub free_port

# make sure the scratch gobgpd pair is not left running no matter how the
# live subtest ends
our @live_gobgpd_pids;

sub stop_gobgpds {
	my @pids = @live_gobgpd_pids;
	@live_gobgpd_pids = ();
	foreach my $pid (@pids) {
		kill( 'TERM', $pid );
	}
	foreach my $pid (@pids) {
		foreach ( 1 .. 100 ) {
			last if ( waitpid( $pid, 1 ) != 0 || !kill( 0, $pid ) );
			select( undef, undef, undef, 0.1 );
		}
	}
} ## end sub stop_gobgpds

END { stop_gobgpds(); }

# announce/withdraw blackhole routes, family-correct next-hop and mask
{
	my $fw = Net::Firewall::BlockerHelper->new(
		backend => 'bgp_rtbh',
		name    => 'rtbh',
		testing => 1,
		options => { next_hop => '192.0.2.1', next_hop6 => '100::1' },
	);
	$fw->init_backend;

	$fw->ban( ban => '1.2.3.4' );
	is( $fw->{test_data},
		"exabgpcli 'announce route 1.2.3.4/32 next-hop 192.0.2.1 community [65535:666]'",
		'IPv4 ban announces a /32 with the default BLACKHOLE community' );

	$fw->ban( ban => 'dead::1' );
	is( $fw->{test_data},
		"exabgpcli 'announce route dead::1/128 next-hop 100::1 community [65535:666]'",
		'IPv6 ban announces a /128 with the v6 next-hop' );

	$fw->unban( ban => '1.2.3.4' );
	is( $fw->{test_data},
		"exabgpcli 'withdraw route 1.2.3.4/32 next-hop 192.0.2.1 community [65535:666]'",
		'unban withdraws the same route' );

	# re-banning is a no-op
	$fw->ban( ban => 'dead::1' );
	is( $fw->{test_data}, 'already banned', 're-banning reports already banned' );

	is_deeply( [ $fw->list ], ['dead::1'], 'list reflects the remaining ban' );

	ok( $fw->{backend_obj}->{cidr_supported}, 'backend reports cidr_supported' );

	$fw->ban_cidr( ban => '1.2.3.0/24' );
	is( $fw->{test_data},
		"exabgpcli 'announce route 1.2.3.0/24 next-hop 192.0.2.1 community [65535:666]'",
		'IPv4 CIDR ban announces the range verbatim with the default BLACKHOLE community' );

	$fw->ban_cidr( ban => 'dead::/64' );
	is( $fw->{test_data},
		"exabgpcli 'announce route dead::/64 next-hop 100::1 community [65535:666]'",
		'IPv6 CIDR ban announces the range with the v6 next-hop' );

	is_deeply( [ sort $fw->list_cidr ], [ '1.2.3.0/24', 'dead::/64' ], 'list_cidr holds both CIDR bans' );

	$fw->unban_cidr( ban => '1.2.3.0/24' );
	is( $fw->{test_data},
		"exabgpcli 'withdraw route 1.2.3.0/24 next-hop 192.0.2.1 community [65535:666]'",
		'CIDR unban withdraws the same range' );

	is_deeply( [ sort $fw->list_cidr ], ['dead::/64'], 'list_cidr drops the unbanned CIDR' );
}

# custom community, mask, and extra attributes
{
	my $fw = Net::Firewall::BlockerHelper->new(
		backend => 'bgp_rtbh',
		name    => 'rtbh',
		testing => 1,
		options => {
			exabgpcli_cmd => '/usr/bin/exabgpcli',
			community     => '64500:100',
			next_hop      => '10.0.0.1',
			mask4         => 24,
			extra         => 'local-preference 50',
		},
	);
	$fw->init_backend;
	$fw->ban( ban => '203.0.113.0' );
	is( $fw->{test_data},
		"/usr/bin/exabgpcli 'announce route 203.0.113.0/24 next-hop 10.0.0.1 community [64500:100] local-preference 50'",
		'options drive command, community, mask, and extra attributes' );
}

# gobgp driver emits gobgp global rib syntax
{
	my $fw = Net::Firewall::BlockerHelper->new(
		backend => 'bgp_rtbh',
		name    => 'rtbh',
		testing => 1,
		options => { driver => 'gobgp', next_hop => '10.0.0.1' },
	);
	$fw->init_backend;

	$fw->ban( ban => '1.2.3.4' );
	is( $fw->{test_data},
		'gobgp global rib add 1.2.3.4/32 nexthop 10.0.0.1 community 65535:666 -a ipv4',
		'gobgp IPv4 ban adds to the global rib with the community' );

	$fw->ban( ban => 'dead::1' );
	is( $fw->{test_data},
		'gobgp global rib add dead::1/128 nexthop 100::1 community 65535:666 -a ipv6',
		'gobgp IPv6 ban uses the ipv6 afi and v6 next-hop' );

	$fw->unban( ban => '1.2.3.4' );
	is( $fw->{test_data}, 'gobgp global rib del 1.2.3.4/32 -a ipv4',
		'gobgp withdraw matches on prefix and afi only' );

	is( $fw->check ? $fw->{test_data} : 'x', 'gobgp neighbor', 'gobgp check uses gobgp neighbor' );
}

# an invalid driver is fatal
{
	my $died = 0;
	eval {
		my $fw = Net::Firewall::BlockerHelper->new(
			backend => 'bgp_rtbh', name => 'rtbh', testing => 1, options => { driver => 'bird' },
		);
		$fw->init_backend;
	};
	$died = 1 if ($@);
	ok( $died, 'invalid driver is fatal' );
}

# teardown withdraws all announced routes
{
	my $fw = Net::Firewall::BlockerHelper->new(
		backend => 'bgp_rtbh', name => 'rtbh', testing => 1, options => {},
	);
	$fw->init_backend;
	$fw->ban( ban => '1.1.1.1' );
	$fw->ban( ban => '2.2.2.2' );
	$fw->teardown;
	is_deeply(
		[ sort @{ $fw->{test_data} } ],
		[
			"exabgpcli 'withdraw route 1.1.1.1/32 next-hop 192.0.2.1 community [65535:666]'",
			"exabgpcli 'withdraw route 2.2.2.2/32 next-hop 192.0.2.1 community [65535:666]'",
		],
		'teardown withdraws every announced route'
	);
}

# frr driver injects blackhole static routes via vtysh
{
	my $fw = Net::Firewall::BlockerHelper->new(
		backend => 'bgp_rtbh', name => 'rtbh', testing => 1, options => { driver => 'frr' },
	);
	$fw->init_backend;
	$fw->ban( ban => '1.2.3.4' );
	is( $fw->{test_data}, "vtysh -c 'configure terminal' -c 'ip route 1.2.3.4/32 blackhole'",
		'frr ban adds an IPv4 blackhole route' );
	$fw->ban( ban => 'dead::1' );
	is( $fw->{test_data}, "vtysh -c 'configure terminal' -c 'ipv6 route dead::1/128 blackhole'",
		'frr ban adds an IPv6 blackhole route' );
	$fw->unban( ban => '1.2.3.4' );
	is( $fw->{test_data}, "vtysh -c 'configure terminal' -c 'no ip route 1.2.3.4/32 blackhole'",
		'frr unban removes the route' );
}

# flowspec announce type (exabgp and gobgp)
{
	my $fw = Net::Firewall::BlockerHelper->new(
		backend => 'bgp_rtbh', name => 'rtbh', testing => 1,
		options => { driver => 'exabgp', announce_type => 'flowspec' },
	);
	$fw->init_backend;
	$fw->ban( ban => '1.2.3.4' );
	is( $fw->{test_data}, "exabgpcli 'announce flow route { match { source 1.2.3.4/32; } then { discard; } }'",
		'exabgp flowspec announces a discard flow' );

	my $g = Net::Firewall::BlockerHelper->new(
		backend => 'bgp_rtbh', name => 'rtbh', testing => 1,
		options => { driver => 'gobgp', announce_type => 'flowspec' },
	);
	$g->init_backend;
	$g->ban( ban => 'dead::1' );
	is( $g->{test_data}, 'gobgp global rib add -a ipv6-flowspec match source dead::1/128 then discard',
		'gobgp flowspec uses the ipv6-flowspec afi' );
}

# flowspec is not allowed with the frr driver
{
	my $died = 0;
	eval {
		my $fw = Net::Firewall::BlockerHelper->new(
			backend => 'bgp_rtbh', name => 'rtbh', testing => 1,
			options => { driver => 'frr', announce_type => 'flowspec' },
		);
		$fw->init_backend;
	};
	$died = 1 if ($@);
	ok( $died, 'frr + flowspec is fatal' );
}

# --- live: gobgp driver against a pair of local gobgpd instances --------------
# Instance A is the one the backend drives; instance B plays the upstream
# router, so announcements are verified as actually having propagated over a
# real BGP session, carried over kernel-assigned localhost ports.
subtest 'live against a scratch gobgpd pair' => sub {
	my %bin;
	foreach my $item (qw(gobgpd gobgp)) {
		$bin{$item} = find_bin($item);
		plan( skip_all => $item . ' not found' ) if ( !defined( $bin{$item} ) );
	}

	require File::Temp;
	my $dir = File::Temp::tempdir( 'nfbh-bgp-XXXXXX', TMPDIR => 1, CLEANUP => 1 );

	my $bgp_a = free_port();
	my $bgp_b = free_port();
	my $api_a = free_port();
	my $api_b = free_port();
	plan( skip_all => 'could not get ports' )
		if ( !defined($bgp_a) || !defined($bgp_b) || !defined($api_a) || !defined($api_b) );

	my $mkconf = sub {
		my ( $file, $as, $router_id, $port, $peer_as, $peer_port ) = @_;
		my $afis = '';
		foreach my $afi (qw(ipv4-unicast ipv6-unicast ipv4-flowspec ipv6-flowspec)) {
			$afis
				.= "  [[neighbors.afi-safis]]\n    [neighbors.afi-safis.config]\n      afi-safi-name = \""
				. $afi . "\"\n";
		}
		write_file( $file, <<"CONF" );
[global.config]
  as = $as
  router-id = "$router_id"
  port = $port
[[neighbors]]
  [neighbors.config]
    neighbor-address = "127.0.0.1"
    peer-as = $peer_as
  [neighbors.transport.config]
    remote-port = $peer_port
  [neighbors.timers.config]
    connect-retry = 1
$afis
CONF
	};
	$mkconf->( "$dir/a.toml", 64512, '192.0.2.11', $bgp_a, 64513, $bgp_b );
	$mkconf->( "$dir/b.toml", 64513, '192.0.2.12', $bgp_b, 64512, $bgp_a );

	# gobgpd runs in the foreground, so fork/exec keeps the pids for cleanup
	foreach my $side ( 'a', 'b' ) {
		my $api = $side eq 'a' ? $api_a : $api_b;
		my $pid = fork();
		plan( skip_all => 'fork failed' ) if ( !defined($pid) );
		if ( !$pid ) {
			open( STDOUT, '>', "$dir/$side.log" );
			open( STDERR, '>&', \*STDOUT );
			exec( $bin{gobgpd}, '-f', "$dir/$side.toml", '--api-hosts', '127.0.0.1:' . $api, '-l', 'warn' )
				or exit(1);
		}
		push( @live_gobgpd_pids, $pid );
	}

	# wait for the session to establish
	my $up = 0;
	foreach ( 1 .. 120 ) {
		my $out = scalar(`'$bin{gobgp}' -p $api_a neighbor 2>&1`);
		if ( defined($out) && $out =~ /Establ/ ) { $up = 1; last; }
		select( undef, undef, undef, 0.5 );
	}
	if ( !$up ) {
		stop_gobgpds();
		plan( skip_all => 'the gobgpd pair never established a session' );
	}

	# the backend drives instance A via a wrapper carrying A's api port
	write_file( "$dir/gobgp-a", "#!/bin/sh\nexec '$bin{gobgp}' -p $api_a \"\$@\"\n" );
	chmod( 0755, "$dir/gobgp-a" );

	# polls the upstream instance B's rib until the regex matches (or, with
	# gone, until it stops matching), covering propagation delay
	my $rib_b = sub {
		my ( $afi, $regex, $gone ) = @_;
		foreach ( 1 .. 20 ) {
			my $out = scalar(`'$bin{gobgp}' -p $api_b global rib -a $afi 2>&1`);
			$out = '' if ( !defined($out) );
			my $matched = ( $out =~ $regex ) ? 1 : 0;
			return 1 if ( $gone ? !$matched : $matched );
			select( undef, undef, undef, 0.25 );
		}
		return 0;
	};

	my $fw = Net::Firewall::BlockerHelper->new(
		backend => 'bgp_rtbh',
		name    => 'rtbh',
		options => { driver => 'gobgp', gobgp_cmd => "$dir/gobgp-a" },
	);
	$fw->init_backend;

	is( $fw->check, 1, 'check is healthy with the daemon up' );

	$fw->ban( ban => '192.0.2.77' );
	ok( $rib_b->( 'ipv4', qr{192\.0\.2\.77/32} ), 'the /32 announcement reached the upstream instance' );
	ok( $rib_b->( 'ipv4', qr{blackhole|65535:666} ), 'it carries the BLACKHOLE community' );
	ok( $rib_b->( 'ipv4', qr{192\.0\.2\.1} ),        'it carries the configured next-hop' );

	$fw->ban( ban => '2001:DB8::77' );
	ok( $rib_b->( 'ipv6', qr{2001:db8::77/128} ), 'the v6 /128, lowercased, reached the upstream instance' );

	$fw->ban_cidr( ban => '203.0.113.0/24' );
	ok( $rib_b->( 'ipv4', qr{203\.0\.113\.0/24} ), 'the CIDR announcement reached the upstream instance' );

	$fw->unban( ban => '192.0.2.77' );
	ok( $rib_b->( 'ipv4', qr{192\.0\.2\.77/32}, 1 ), 'unban withdraws the /32' );

	$fw->unban_cidr( ban => '203.0.113.0/24' );
	ok( $rib_b->( 'ipv4', qr{203\.0\.113\.0/24}, 1 ), 'unban_cidr withdraws the CIDR' );

	$fw->re_init;
	ok( $rib_b->( 'ipv6', qr{2001:db8::77/128} ), 're_init re-announces the kept ban' );

	$fw->teardown;
	ok( $rib_b->( 'ipv6', qr{2001:db8::77/128}, 1 ), 'teardown withdraws everything' );
	is( scalar( $fw->list ), 1, 'teardown keeps the ban list' );

	# flowspec announce_type
	my $fw2 = Net::Firewall::BlockerHelper->new(
		backend => 'bgp_rtbh',
		name    => 'rtbh',
		options => { driver => 'gobgp', gobgp_cmd => "$dir/gobgp-a", announce_type => 'flowspec' },
	);
	$fw2->init_backend;
	$fw2->ban( ban => '192.0.2.88' );
	ok( $rib_b->( 'ipv4-flowspec', qr{192\.0\.2\.88/32} ), 'the v4 flowspec rule reached the upstream instance' );
	$fw2->ban( ban => '2001:db8::88' );
	ok( $rib_b->( 'ipv6-flowspec', qr{2001:db8::88/128} ), 'the v6 flowspec rule reached the upstream instance' );
	$fw2->flush;
	ok( $rib_b->( 'ipv4-flowspec', qr{192\.0\.2\.88}, 1 ), 'flush withdraws the flowspec rules' );

	# check has to notice the daemon being gone
	stop_gobgpds();
	is( $fw->check, 0, 'check is unhealthy with the daemon gone' );
};

# --- live: exabgp driver against a scratch gobgpd -----------------------------
# exabgp holds the session and is driven over its named pipe cli; a passive
# gobgpd plays the upstream router the announcements are verified on. All of
# it lives on kernel-assigned localhost ports and under a temp dir, exabgp
# finding the pipes there via --root.
subtest 'live exabgp driver against a scratch gobgpd' => sub {
	my %bin;
	foreach my $item (qw(exabgp exabgpcli gobgpd gobgp)) {
		$bin{$item} = find_bin($item);
		plan( skip_all => $item . ' not found' ) if ( !defined( $bin{$item} ) );
	}

	require File::Temp;
	require POSIX;
	my $dir = File::Temp::tempdir( 'nfbh-exabgp-XXXXXX', TMPDIR => 1, CLEANUP => 1 );

	my $bgp_b = free_port();
	my $api_b = free_port();
	plan( skip_all => 'could not get ports' ) if ( !defined($bgp_b) || !defined($api_b) );

	# the named pipes exabgpcli talks to exabgp over, found via --root
	mkdir("$dir/run");
	if ( !POSIX::mkfifo( "$dir/run/exabgp.in", 0600 ) || !POSIX::mkfifo( "$dir/run/exabgp.out", 0600 ) ) {
		plan( skip_all => 'could not create the cli fifos... ' . $! );
	}

	# keep exabgp from trying to switch to its default user when run as root
	my $user = getpwuid($<);
	write_file( "$dir/exabgp.env", <<"ENV" );
[exabgp.daemon]
user = '$user'
daemonize = false

[exabgp.log]
all = false
ENV

	write_file( "$dir/exabgp.conf", <<"CONF" );
neighbor 127.0.0.1 {
	router-id 192.0.2.13;
	local-address 127.0.0.1;
	local-as 64514;
	peer-as 64513;
	connect $bgp_b;

	family {
		ipv4 unicast;
		ipv6 unicast;
		ipv4 flow;
		ipv6 flow;
	}
}
CONF

	# the passive upstream gobgpd the announcements are verified on
	my $afis = '';
	foreach my $afi (qw(ipv4-unicast ipv6-unicast ipv4-flowspec ipv6-flowspec)) {
		$afis
			.= "  [[neighbors.afi-safis]]\n    [neighbors.afi-safis.config]\n      afi-safi-name = \""
			. $afi . "\"\n";
	}
	write_file( "$dir/b.toml", <<"CONF" );
[global.config]
  as = 64513
  router-id = "192.0.2.12"
  port = $bgp_b
[[neighbors]]
  [neighbors.config]
    neighbor-address = "127.0.0.1"
    peer-as = 64514
  [neighbors.transport.config]
    passive-mode = true
$afis
CONF

	foreach my $side ( [ 'b', [ $bin{gobgpd}, '-f', "$dir/b.toml", '--api-hosts', '127.0.0.1:' . $api_b, '-l', 'warn' ] ],
		[ 'exabgp', [ $bin{exabgp}, '--root', $dir, '--env', "$dir/exabgp.env", "$dir/exabgp.conf" ] ] )
	{
		my $pid = fork();
		plan( skip_all => 'fork failed' ) if ( !defined($pid) );
		if ( !$pid ) {
			open( STDOUT, '>', "$dir/" . $side->[0] . '.log' );
			open( STDERR, '>&', \*STDOUT );
			open( STDIN, '<', '/dev/null' );
			exec( @{ $side->[1] } ) or exit(1);
		}
		push( @live_gobgpd_pids, $pid );
	}

	# wait for the session to establish
	my $up = 0;
	foreach ( 1 .. 120 ) {
		my $out = scalar(`'$bin{gobgp}' -p $api_b neighbor 2>&1`);
		if ( defined($out) && $out =~ /Establ/ ) { $up = 1; last; }
		select( undef, undef, undef, 0.5 );
	}
	if ( !$up ) {
		stop_gobgpds();
		plan( skip_all => 'exabgp and gobgpd never established a session' );
	}

	# the backend drives exabgp via a wrapper carrying the root and env
	write_file( "$dir/exabgpcli-wrapped",
		"#!/bin/sh\nexec '$bin{exabgpcli}' --root '$dir' --env '$dir/exabgp.env' \"\$@\"\n" );
	chmod( 0755, "$dir/exabgpcli-wrapped" );

	my $rib_b = sub {
		my ( $afi, $regex, $gone ) = @_;
		foreach ( 1 .. 20 ) {
			my $out = scalar(`'$bin{gobgp}' -p $api_b global rib -a $afi 2>&1`);
			$out = '' if ( !defined($out) );
			my $matched = ( $out =~ $regex ) ? 1 : 0;
			return 1 if ( $gone ? !$matched : $matched );
			select( undef, undef, undef, 0.25 );
		}
		return 0;
	};

	my $fw = Net::Firewall::BlockerHelper->new(
		backend => 'bgp_rtbh',
		name    => 'rtbh',
		options => { driver => 'exabgp', exabgpcli_cmd => "$dir/exabgpcli-wrapped" },
	);
	$fw->init_backend;

	is( $fw->check, 1, 'check is healthy with exabgp up' );

	$fw->ban( ban => '192.0.2.77' );
	ok( $rib_b->( 'ipv4', qr{192\.0\.2\.77/32} ), 'the /32 announcement reached the upstream instance' );
	ok( $rib_b->( 'ipv4', qr{blackhole|65535:666} ), 'it carries the BLACKHOLE community' );

	$fw->ban( ban => '2001:DB8::77' );
	ok( $rib_b->( 'ipv6', qr{2001:db8::77/128} ), 'the v6 /128, lowercased, reached the upstream instance' );

	$fw->ban_cidr( ban => '203.0.113.0/24' );
	ok( $rib_b->( 'ipv4', qr{203\.0\.113\.0/24} ), 'the CIDR announcement reached the upstream instance' );

	$fw->unban( ban => '192.0.2.77' );
	ok( $rib_b->( 'ipv4', qr{192\.0\.2\.77/32}, 1 ), 'unban withdraws the /32' );

	$fw->re_init;
	ok( $rib_b->( 'ipv6', qr{2001:db8::77/128} ), 're_init re-announces the kept bans' );

	$fw->teardown;
	ok( $rib_b->( 'ipv6', qr{2001:db8::77/128}, 1 ) && $rib_b->( 'ipv4', qr{203\.0\.113\.0/24}, 1 ),
		'teardown withdraws everything' );

	# flowspec announce_type; the braces of the flow syntax are shell syntax,
	# so this also proves the command survives the shell intact
	my $fw2 = Net::Firewall::BlockerHelper->new(
		backend => 'bgp_rtbh',
		name    => 'rtbh',
		options =>
			{ driver => 'exabgp', exabgpcli_cmd => "$dir/exabgpcli-wrapped", announce_type => 'flowspec' },
	);
	$fw2->init_backend;
	$fw2->ban( ban => '192.0.2.88' );
	ok( $rib_b->( 'ipv4-flowspec', qr{192\.0\.2\.88/32} ), 'the v4 flowspec rule reached the upstream instance' );
	$fw2->ban( ban => '2001:db8::88' );
	ok( $rib_b->( 'ipv6-flowspec', qr{2001:db8::88/128} ), 'the v6 flowspec rule reached the upstream instance' );
	$fw2->flush;
	ok( $rib_b->( 'ipv4-flowspec', qr{192\.0\.2\.88}, 1 ), 'flush withdraws the flowspec rules' );

	# check has to notice exabgp being gone; the fifos are removed as well so
	# exabgpcli fails fast rather than sitting on a reader-less pipe
	stop_gobgpds();
	unlink( "$dir/run/exabgp.in", "$dir/run/exabgp.out" );
	is( $fw->check, 0, 'check is unhealthy with exabgp gone' );
};

done_testing();
