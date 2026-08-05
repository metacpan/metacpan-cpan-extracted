#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

BEGIN {
	use_ok('Net::Firewall::BlockerHelper') || print "Bail out!\n";
}

# ban/unban drive the OPNsense alias_util API via LWP::UserAgent
{
	my $fw = Net::Firewall::BlockerHelper->new(
		backend => 'opnsense',
		name    => 'bl',
		prefix  => 'kur',
		testing => 1,
		options => { host => 'fw.example:8443', key => 'K', secret => 'S', insecure => 1 },
	);
	$fw->init_backend;

	is( $fw->{test_data}[0]{method}, 'GET', 'init verifies the alias with a GET' );
	is( $fw->{test_data}[0]{url},
		'https://fw.example:8443/api/firewall/alias_util/list/kur_bl',
		'init lists the alias' );

	$fw->ban( ban => '1.2.3.4' );
	is( $fw->{test_data}[0]{method}, 'POST', 'ban POSTs' );
	is( $fw->{test_data}[0]{url},
		'https://fw.example:8443/api/firewall/alias_util/add/kur_bl',
		'ban posts to alias_util/add' );
	is( $fw->{test_data}[0]{content}, '{"address":"1.2.3.4"}', 'ban body carries the ip' );

	$fw->ban( ban => 'DEAD::1' );
	is( $fw->{test_data}[0]{content}, '{"address":"dead::1"}', 'IPv6 bans are lowercased' );

	$fw->unban( ban => '1.2.3.4' );
	is( $fw->{test_data}[0]{url},
		'https://fw.example:8443/api/firewall/alias_util/delete/kur_bl',
		'unban posts to alias_util/delete' );
	is( $fw->{test_data}[0]{content}, '{"address":"1.2.3.4"}', 'unban body carries the ip' );

	$fw->flush;
	is( $fw->{test_data}[0]{url},
		'https://fw.example:8443/api/firewall/alias_util/flush/kur_bl',
		'flush posts to alias_util/flush' );

	# CIDR support
	ok( $fw->{backend_obj}{cidr_supported}, 'cidr is supported' );
	$fw->ban_cidr( ban => '1.2.3.0/24' );
	is( $fw->{test_data}[0]{url},
		'https://fw.example:8443/api/firewall/alias_util/add/kur_bl',
		'ban_cidr posts to alias_util/add' );
	is( $fw->{test_data}[0]{content}, '{"address":"1.2.3.0/24"}', 'ban_cidr body carries the range' );
	my %listed = map { $_ => 1 } $fw->{backend_obj}->list_cidr;
	ok( $listed{'1.2.3.0/24'}, 'list_cidr contains the banned CIDR' );
	$fw->unban_cidr( ban => '1.2.3.0/24' );
	%listed = map { $_ => 1 } $fw->{backend_obj}->list_cidr;
	ok( !$listed{'1.2.3.0/24'}, 'list_cidr no longer contains the CIDR after unban_cidr' );
}

# the scheme option drives the URL
{
	my $fw = Net::Firewall::BlockerHelper->new(
		backend => 'opnsense',
		name    => 'bl',
		testing => 1,
		options => { host => 'h', key => 'k', secret => 's', scheme => 'http' },
	);
	$fw->init_backend;
	like( $fw->{test_data}[0]{url}, qr{^http://h/}, 'scheme http is used when set' );
}

# a non-int timeout is fatal
{
	my $died = 0;
	eval {
		my $fw = Net::Firewall::BlockerHelper->new(
			backend => 'opnsense', name => 'bl', testing => 1,
			options => { host => 'h', key => 'k', secret => 's', timeout => 'soon' },
		);
		$fw->init_backend;
	};
	$died = 1 if ($@);
	ok( $died, 'a non-int timeout is fatal' );
}

# host/key/secret are all required
for my $missing (qw(host key secret)) {
	my %opts = ( host => 'h', key => 'k', secret => 's' );
	delete $opts{$missing};
	my $died = 0;
	eval {
		my $fw = Net::Firewall::BlockerHelper->new(
			backend => 'opnsense', name => 'bl', testing => 1, options => \%opts,
		);
		$fw->init_backend;
	};
	$died = 1 if ($@);
	ok( $died, "missing $missing is fatal" );
}

done_testing();
