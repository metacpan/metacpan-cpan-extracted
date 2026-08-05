#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

BEGIN {
	use_ok('Net::Firewall::BlockerHelper') || print "Bail out!\n";
}

# ban/unban drive the RouterOS REST address-list, split by family
{
	my $fw = Net::Firewall::BlockerHelper->new(
		backend => 'routeros_api',
		name    => 'ssh',
		prefix  => 'kur',
		testing => 1,
		options => { host => '10.0.0.1', user => 'blocker', password => 'pw' },
	);
	$fw->init_backend;

	is( $fw->{test_data}[0]{method}, 'GET', 'init probes with a GET' );
	is( $fw->{test_data}[0]{url},
		'https://10.0.0.1/rest/ip/firewall/address-list?list=kur_ssh',
		'init probes the v4 address-list under the default list name' );

	$fw->ban( ban => '1.2.3.4' );
	is( $fw->{test_data}[0]{method}, 'PUT', 'ban is a PUT' );
	is( $fw->{test_data}[0]{url}, 'https://10.0.0.1/rest/ip/firewall/address-list', 'ban targets the v4 menu' );
	is( $fw->{test_data}[0]{content}, '{"address":"1.2.3.4","list":"kur_ssh"}', 'ban body carries list and address' );

	$fw->ban( ban => 'dead::1' );
	is( $fw->{test_data}[0]{url}, 'https://10.0.0.1/rest/ipv6/firewall/address-list', 'v6 ban targets the ipv6 menu' );

	$fw->unban( ban => '1.2.3.4' );
	is( $fw->{test_data}[0]{method}, 'GET', 'unban first looks the entry up' );
	is( $fw->{test_data}[0]{url},
		'https://10.0.0.1/rest/ip/firewall/address-list?list=kur_ssh&address=1.2.3.4',
		'lookup filters by list and address' );
	is( $fw->{test_data}[1]{method}, 'DELETE', 'unban then deletes' );
	is( $fw->{test_data}[1]{url}, 'https://10.0.0.1/rest/ip/firewall/address-list/<id>', 'delete is by id' );

	# CIDR ban/unban drive the same address-list, keyed off the family of the range
	ok( $fw->{backend_obj}{cidr_supported}, 'the backend reports CIDR support' );

	$fw->ban_cidr( ban => '1.2.3.0/24' );
	is( $fw->{test_data}[0]{method}, 'PUT', 'ban_cidr is a PUT' );
	is( $fw->{test_data}[0]{url}, 'https://10.0.0.1/rest/ip/firewall/address-list', 'ban_cidr targets the v4 menu' );
	is( $fw->{test_data}[0]{content}, '{"address":"1.2.3.0/24","list":"kur_ssh"}',
		'ban_cidr body carries list and CIDR' );

	my @cidr_after_ban = $fw->list_cidr;
	is_deeply( \@cidr_after_ban, ['1.2.3.0/24'], 'list_cidr contains the banned CIDR' );

	$fw->unban_cidr( ban => '1.2.3.0/24' );
	is( $fw->{test_data}[1]{method}, 'DELETE', 'unban_cidr then deletes' );

	my @cidr_after_unban = $fw->list_cidr;
	is_deeply( \@cidr_after_unban, [], 'list_cidr is empty after unban_cidr' );
}

# insecure + http scheme + custom list names
{
	my $fw = Net::Firewall::BlockerHelper->new(
		backend => 'routeros_api',
		name    => 'ssh',
		testing => 1,
		options => {
			host   => 'rb.example:8080',
			user   => 'u',
			password => 'p',
			scheme => 'http',
			list4  => 'banned4',
		},
	);
	$fw->init_backend;
	$fw->ban( ban => '9.9.9.9' );
	is( $fw->{test_data}[0]{url}, 'http://rb.example:8080/rest/ip/firewall/address-list',
		'scheme and host:port honored' );
	is( $fw->{test_data}[0]{content}, '{"address":"9.9.9.9","list":"banned4"}', 'custom list4 name used' );
}

# host/user/password are all required
for my $missing (qw(host user password)) {
	my %opts = ( host => 'h', user => 'u', password => 'p' );
	delete $opts{$missing};
	my $died = 0;
	eval {
		my $fw = Net::Firewall::BlockerHelper->new(
			backend => 'routeros_api', name => 'ssh', testing => 1, options => \%opts,
		);
		$fw->init_backend;
	};
	$died = 1 if ($@);
	ok( $died, "missing $missing is fatal" );
}

# ports are rejected (they belong on the referencing rule)
{
	my $died = 0;
	eval {
		my $fw = Net::Firewall::BlockerHelper->new(
			backend => 'routeros_api', name => 'ssh', testing => 1,
			ports   => ['22'], options => { host => 'h', user => 'u', password => 'p' },
		);
		$fw->init_backend;
	};
	$died = 1 if ($@);
	ok( $died, 'specifying ports is fatal' );
}

done_testing();
