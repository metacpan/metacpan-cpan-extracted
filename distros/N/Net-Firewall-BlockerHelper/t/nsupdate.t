#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

BEGIN {
	use_ok('Net::Firewall::BlockerHelper')                     || print "Bail out!\n";
	use_ok('Net::Firewall::BlockerHelper::backends::nsupdate') || print "Bail out!\n";
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

my $fw = Net::Firewall::BlockerHelper->new(
	backend => 'nsupdate',
	name    => 'ssh',
	options => { domain => 'rbl.foo.bar', keyfile => '/etc/nsupdate.key' },
	testing => 1,
);
$fw->init_backend;
is( $fw->{test_data}, 'inited', 'init needs no commands in testing mode' );

$fw->ban( ban => '1.2.3.4' );
is_deeply(
	$fw->{test_data},
	[
		      "printf 'prereq nxrrset 4.3.2.1.rbl.foo.bar TXT\\n"
			. 'update add 4.3.2.1.rbl.foo.bar 60 IN TXT "banned"' . "\\n"
			. "send\\n' | nsupdate -k '/etc/nsupdate.key'"
	],
	'ban adds a TXT record at the reversed-octet name'
);

$fw->ban( ban => '1.2.3.4' );
is( $fw->{test_data}, 'already banned', 'double ban short-circuits' );

$fw->unban( ban => '1.2.3.4' );
is( $fw->{test_data},
	"printf 'update delete 4.3.2.1.rbl.foo.bar TXT\\nsend\\n' | nsupdate -k '/etc/nsupdate.key'",
	'unban deletes the TXT record' );

my $cidr_blocked = 0;
eval { $fw->ban_cidr( ban => '1.2.3.0/24' ); };
if ( defined( $fw->{error} ) && $fw->{error} == 29 ) { $cidr_blocked = 1; }
if ( !$cidr_blocked ) {
	die( 'ban_cidr did not set frontend error 29 cidrNotSupported... got ' . ( defined( $fw->{error} ) ? $fw->{error} : 'undef' ) );
}

is( $fw->check, 1, 'check always reports healthy' );

$fw->ban( ban => '5.6.7.8' );
$fw->re_init;
like( $fw->{test_data}[0], qr/8\.7\.6\.5\.rbl\.foo\.bar/, 're_init re-adds the remaining ban' );

$fw->teardown;
like( $fw->{test_data}[0], qr/^printf 'update delete 8\.7\.6\.5\.rbl\.foo\.bar TXT/, 'teardown deletes the records' );
is( scalar( $fw->list ), 1, 'teardown keeps the ban list for re_init' );

# re-arm the same backend object so the kept ban list is exercised
$fw->{backend_obj}->init;
$fw->flush;
is( scalar( $fw->list ), 0, 'flush empties the ban list' );

# --- IPv6 is rejected --------------------------------------------------------------
{
	my $fw2 = Net::Firewall::BlockerHelper->new(
		backend => 'nsupdate',
		name    => 'ssh',
		options => { domain => 'rbl.foo.bar', keyfile => '/etc/nsupdate.key' },
		testing => 1,
	);
	$fw2->init_backend;
	local $@;
	eval { $fw2->ban( ban => 'dead::1' ); };
	ok( $@, 'banning an IPv6 IP errors' );
	is( $fw2->error, 13, 'the frontend wraps it as banFailed' );
}

# --- options ------------------------------------------------------------------------
{
	my $fw2 = Net::Firewall::BlockerHelper->new(
		backend => 'nsupdate',
		name    => 'ssh',
		options => {
			domain   => 'rbl.foo.bar',
			keyfile  => '/etc/nsupdate.key',
			ttl      => 300,
			rdata    => 'go away',
			nsupdate => '/usr/local/bin/nsupdate',
		},
		testing => 1,
	);
	$fw2->init_backend;
	$fw2->ban( ban => '1.2.3.4' );
	like( $fw2->{test_data}[0], qr/300 IN TXT "go away"/,        'ttl and rdata options are used' );
	like( $fw2->{test_data}[0], qr/\| \/usr\/local\/bin\/nsupdate /, 'the nsupdate option is used' );
}

# --- validation, on the backend directly as that is where these are checked ---------
{
	local $@;
	eval { Net::Firewall::BlockerHelper::backends::nsupdate->new( name => 'ssh', options => { keyfile => '/etc/k' } ); };
	ok( $@, 'a missing domain errors' );
	is( $Error::Helper::error, 28, 'missing domain raises error 28' );

	eval {
		Net::Firewall::BlockerHelper::backends::nsupdate->new(
			name    => 'ssh',
			options => { domain => 'rbl.foo.bar', keyfile => "/etc/bad'file" }
		);
	};
	ok( $@, 'a keyfile with a single quote errors' );

	eval {
		Net::Firewall::BlockerHelper::backends::nsupdate->new(
			name    => 'ssh',
			ports   => ['22'],
			options => { domain => 'rbl.foo.bar', keyfile => '/etc/k' }
		);
	};
	ok( $@, 'ports error as unsupported' );
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
	my $dir = File::Temp::tempdir( 'nfbh-nsupdate-XXXXXX', DIR => $base, CLEANUP => 1 );

	# a kernel assigned port, being portable, unlike parsing the likes of ss
	# or netstat for a free one
	my $sock = IO::Socket::INET->new( LocalAddr => '127.0.0.1', LocalPort => 0, Proto => 'udp' );
	plan( skip_all => 'could not get a port' ) if ( !$sock );
	my $port = $sock->sockport;
	close($sock);

	my $key = `'$bin{'tsig-keygen'}' nsupdate-key 2>&1`;
	plan( skip_all => 'tsig-keygen failed... ' . $key ) if ( $? != 0 );
	write_file( "$dir/key.conf", $key );

	write_file( "$dir/rbl.test.db", <<"ZONE" );
\$TTL 60
\@	IN	SOA	ns.rbl.test. root.rbl.test. ( 1 3600 900 604800 60 )
	IN	NS	ns.rbl.test.
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
zone "rbl.test" {
	type primary;
	file "$dir/rbl.test.db";
	allow-update { key "nsupdate-key"; };
};
CONF

	system( $bin{named}, '-c', "$dir/named.conf" );
	plan( skip_all => 'named failed to start' ) if ( $? != 0 );

	my $up = 0;
	foreach ( 1 .. 50 ) {
		my $out = `'$bin{dig}' -p $port \@127.0.0.1 +time=1 +tries=1 SOA rbl.test 2>&1`;
		if ( $? == 0 && $out =~ /rbl\.test/ ) { $up = 1; last; }
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

	# the backend never emits a server statement, so a wrapper points
	# nsupdate at the scratch server
	write_file( "$dir/nsupdate-wrapped",
		"#!/bin/sh\n( printf 'server 127.0.0.1 $port\\n' ; cat ) | '$bin{nsupdate}' \"\$@\"\n" );
	chmod( 0755, "$dir/nsupdate-wrapped" );

	my $dig_txt = sub {
		my ($name) = @_;
		my $out = `'$bin{dig}' -p $port \@127.0.0.1 +short TXT $name 2>&1`;
		chomp($out);
		return $out;
	};

	my $fw = Net::Firewall::BlockerHelper->new(
		backend => 'nsupdate',
		name    => 'ssh',
		options => {
			domain   => 'rbl.test',
			keyfile  => "$dir/key.conf",
			nsupdate => "$dir/nsupdate-wrapped",
		},
	);
	$fw->init_backend;

	$fw->ban( ban => '192.0.2.77' );
	is( $dig_txt->('77.2.0.192.rbl.test'), '"banned"', 'ban creates the TXT record on the server' );

	$fw->ban( ban => '198.51.100.9' );
	is( $dig_txt->('9.100.51.198.rbl.test'), '"banned"', 'a second ban creates its record' );

	$fw->unban( ban => '192.0.2.77' );
	is( $dig_txt->('77.2.0.192.rbl.test'), '', 'unban removes the record' );

	$fw->re_init;
	is( $dig_txt->('9.100.51.198.rbl.test'), '"banned"', 're_init re-adds the kept ban' );

	$fw->teardown;
	is( $dig_txt->('9.100.51.198.rbl.test'), '', 'teardown removes the records' );
	is( scalar( $fw->list ), 1, 'teardown keeps the ban list' );

	$fw->{backend_obj}->init;
	$fw->re_init;
	is( $dig_txt->('9.100.51.198.rbl.test'), '"banned"', 're-armed re_init restores the record' );
	$fw->flush;
	is( $dig_txt->('9.100.51.198.rbl.test'), '', 'flush removes the records' );
	is( scalar( $fw->list ), 0, 'flush empties the ban list' );

	stop_named();
};

done_testing();
