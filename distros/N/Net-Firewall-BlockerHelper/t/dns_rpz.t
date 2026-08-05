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

# Stops the scratch named and waits for it to actually exit, as it writes to
# the temp dir on shutdown and File::Temp's cleanup would otherwise race it.
our $live_named_pid;

sub stop_named {
	my $pid = $live_named_pid;
	return if ( !$pid );
	$live_named_pid = undef;
	kill( 'TERM', $pid );
	foreach ( 1 .. 100 ) {
		last if ( !kill( 0, $pid ) );
		select( undef, undef, undef, 0.1 );
	}
} ## end sub stop_named

# make sure the scratch named is not left running no matter how the live
# subtest ends
END { stop_named(); }

# ban/unban run nsupdate adding/removing an rpz-client-ip record
{
	my $fw = Net::Firewall::BlockerHelper->new(
		backend => 'dns_rpz',
		name    => 'r',
		testing => 1,
		options => { zone => 'rpz.example.org', keyfile => '/etc/rpz.key' },
	);
	$fw->init_backend;

	$fw->ban( ban => '1.2.3.4' );
	like( $fw->{test_data},
		qr{update add 32\.4\.3\.2\.1\.rpz-client-ip\.rpz\.example\.org 60 IN CNAME \.},
		'IPv4 ban adds a reversed rpz-client-ip record' );
	like( $fw->{test_data}, qr{\| nsupdate -k '/etc/rpz\.key'}, 'piped into nsupdate with the keyfile' );

	$fw->ban( ban => '2001:db8::1' );
	like( $fw->{test_data},
		qr{update add 128\.1\.zz\.db8\.2001\.rpz-client-ip\.rpz\.example\.org},
		'IPv6 ban uses the RPZ IPv6 encoding with zz' );

	$fw->unban( ban => '1.2.3.4' );
	like( $fw->{test_data},
		qr{update delete 32\.4\.3\.2\.1\.rpz-client-ip\.rpz\.example\.org IN CNAME \.},
		'unban deletes the record' );

	# CIDR bans are not supported by this backend; ban_cidr must set error 29
	my $cidr_blocked = 0;
	eval { $fw->ban_cidr( ban => '1.2.3.0/24' ); };
	if ( $fw->{error} == 29 ) { $cidr_blocked = 1; }
	ok( $cidr_blocked, 'ban_cidr sets error 29 cidrNotSupported' );
}

# the ip trigger and a server line
{
	my $fw = Net::Firewall::BlockerHelper->new(
		backend => 'dns_rpz', name => 'r', testing => 1,
		options => { zone => 'z', keyfile => '/k', trigger => 'ip', server => '10.0.0.1' },
	);
	$fw->init_backend;
	$fw->ban( ban => '1.2.3.4' );
	like( $fw->{test_data}, qr{32\.4\.3\.2\.1\.rpz-ip\.z}, 'trigger ip uses rpz-ip' );
	like( $fw->{test_data}, qr{printf 'server 10\.0\.0\.1\\nzone z}, 'server line prepended' );
}

# zone and keyfile are required
for my $missing (qw(zone keyfile)) {
	my %opts = ( zone => 'z', keyfile => '/k' );
	delete $opts{$missing};
	my $died = 0;
	eval {
		my $fw = Net::Firewall::BlockerHelper->new(
			backend => 'dns_rpz', name => 'r', testing => 1, options => \%opts,
		);
		$fw->init_backend;
	};
	$died = 1 if ($@);
	ok( $died, "missing $missing is fatal" );
}

# an invalid trigger is fatal
{
	my $died = 0;
	eval {
		my $fw = Net::Firewall::BlockerHelper->new(
			backend => 'dns_rpz', name => 'r', testing => 1,
			options => { zone => 'z', keyfile => '/k', trigger => 'nsip' },
		);
		$fw->init_backend;
	};
	$died = 1 if ($@);
	ok( $died, 'an invalid trigger is fatal' );
}

# server, ttl, and nsupdate are embedded in the shell command, so bad values are fatal
for my $bad (
	[ server   => "10.0.0.1' ; reboot ;'" ],
	[ ttl      => '60; reboot' ],
	[ nsupdate => "nsupdate' ; reboot ;'" ],
	)
{
	my $died = 0;
	eval {
		my $fw = Net::Firewall::BlockerHelper->new(
			backend => 'dns_rpz', name => 'r', testing => 1,
			options => { zone => 'z', keyfile => '/k', $bad->[0] => $bad->[1] },
		);
		$fw->init_backend;
	};
	$died = 1 if ($@);
	ok( $died, 'an invalid ' . $bad->[0] . ' is fatal' );
}

# --- live: against a scratch named on a kernel-assigned high port -------------
subtest 'live against a scratch named' => sub {
	my %bin;
	foreach my $item (qw(named tsig-keygen nsupdate dig)) {
		$bin{$item} = find_bin($item);
		plan( skip_all => $item . ' not found' ) if ( !defined( $bin{$item} ) );
	}

	require File::Temp;
	require File::Spec;
	require IO::Socket::INET;

	# apparmor on Ubuntu confines named to its own dirs, /var/cache/bind
	# included, so that is preferred as the base when usable
	my $base = ( -d '/var/cache/bind' && -w '/var/cache/bind' ) ? '/var/cache/bind' : File::Spec->tmpdir;
	my $dir = File::Temp::tempdir( 'nfbh-rpz-XXXXXX', DIR => $base, CLEANUP => 1 );

	# a kernel assigned port, being portable, unlike parsing the likes of ss
	# or netstat for a free one
	my $sock = IO::Socket::INET->new( LocalAddr => '127.0.0.1', LocalPort => 0, Proto => 'udp' );
	plan( skip_all => 'could not get a port' ) if ( !$sock );
	my $port = $sock->sockport;
	close($sock);

	my $key = `'$bin{'tsig-keygen'}' nsupdate-key 2>&1`;
	plan( skip_all => 'tsig-keygen failed... ' . $key ) if ( $? != 0 );
	write_file( "$dir/key.conf", $key );

	write_file( "$dir/rpz.test.db", <<"ZONE" );
\$TTL 60
\@	IN	SOA	ns.rpz.test. root.rpz.test. ( 1 3600 900 604800 60 )
	IN	NS	ns.rpz.test.
ns	IN	A	127.0.0.1
ZONE

	write_file( "$dir/named.conf", <<"CONF" );
options {
	directory "$dir";
	listen-on port $port { 127.0.0.1; };
	listen-on-v6 { none; };
	recursion no;
	pid-file "$dir/named.pid";
};
include "$dir/key.conf";
zone "rpz.test" {
	type primary;
	file "$dir/rpz.test.db";
	allow-update { key "nsupdate-key"; };
};
CONF

	system( $bin{named}, '-c', "$dir/named.conf" );
	plan( skip_all => 'named failed to start' ) if ( $? != 0 );

	my $up = 0;
	foreach ( 1 .. 50 ) {
		my $out = `'$bin{dig}' -p $port \@127.0.0.1 +time=1 +tries=1 SOA rpz.test 2>&1`;
		if ( $? == 0 && $out =~ /rpz\.test/ ) { $up = 1; last; }
		select( undef, undef, undef, 0.2 );
	}
	if ( open( my $pid_fh, '<', "$dir/named.pid" ) ) {
		$live_named_pid = <$pid_fh>;
		chomp($live_named_pid) if ( defined($live_named_pid) );
		close($pid_fh);
	}
	if ( !$up ) {
		stop_named();
		plan( skip_all => 'named never began answering' );
	}

	# the server option is left unset so the wrapper's injected server line,
	# which carries the port, is the one used
	write_file( "$dir/nsupdate-wrapped",
		"#!/bin/sh\n( printf 'server 127.0.0.1 $port\\n' ; cat ) | '$bin{nsupdate}' \"\$@\"\n" );
	chmod( 0755, "$dir/nsupdate-wrapped" );

	my $dig_cname = sub {
		my ($name) = @_;
		my $out = `'$bin{dig}' -p $port \@127.0.0.1 +short CNAME $name 2>&1`;
		chomp($out);
		return $out;
	};

	my $fw = Net::Firewall::BlockerHelper->new(
		backend => 'dns_rpz',
		name    => 'r',
		options => {
			zone     => 'rpz.test',
			keyfile  => "$dir/key.conf",
			nsupdate => "$dir/nsupdate-wrapped",
		},
	);
	$fw->init_backend;

	$fw->ban( ban => '192.0.2.77' );
	is( $dig_cname->('32.77.2.0.192.rpz-client-ip.rpz.test'),
		'.', 'IPv4 ban creates the rpz-client-ip CNAME on the server' );

	$fw->ban( ban => '2001:DB8::77' );
	is( $dig_cname->('128.77.zz.db8.2001.rpz-client-ip.rpz.test'),
		'.', 'IPv6 ban creates the zz encoded record, lowercased' );

	$fw->unban( ban => '192.0.2.77' );
	is( $dig_cname->('32.77.2.0.192.rpz-client-ip.rpz.test'), '', 'unban removes the record' );

	$fw->re_init;
	is( $dig_cname->('128.77.zz.db8.2001.rpz-client-ip.rpz.test'), '.', 're_init re-adds the kept ban' );

	$fw->teardown;
	is( $dig_cname->('128.77.zz.db8.2001.rpz-client-ip.rpz.test'), '', 'teardown removes the records' );
	is( scalar( $fw->list ), 1, 'teardown keeps the ban list' );

	$fw->{backend_obj}->init;
	$fw->re_init;
	$fw->flush;
	is( $dig_cname->('128.77.zz.db8.2001.rpz-client-ip.rpz.test'), '', 'flush removes the records' );
	is( scalar( $fw->list ), 0, 'flush empties the ban list' );

	# the ip trigger writes under rpz-ip instead
	my $fw2 = Net::Firewall::BlockerHelper->new(
		backend => 'dns_rpz',
		name    => 'r',
		options => {
			zone     => 'rpz.test',
			keyfile  => "$dir/key.conf",
			nsupdate => "$dir/nsupdate-wrapped",
			trigger  => 'ip',
		},
	);
	$fw2->init_backend;
	$fw2->ban( ban => '192.0.2.9' );
	is( $dig_cname->('32.9.2.0.192.rpz-ip.rpz.test'), '.', 'the ip trigger creates a rpz-ip record' );
	$fw2->teardown;

	stop_named();
};

done_testing();
