#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

BEGIN {
	use_ok('Net::Firewall::BlockerHelper') || print "Bail out!\n";
}

# ban renders the full membership to the address-list object via PUT
{
	my $fw = Net::Firewall::BlockerHelper->new(
		backend => 'f5_bigip',
		name    => 'ssh',
		prefix  => 'kur',
		testing => 1,
		options => { host => 'h', user => 'u', password => 'p' },
	);
	$fw->init_backend;

	is( $fw->{test_data}[0]{method}, 'GET', 'init probes the object with a GET' );
	is( $fw->{test_data}[0]{url},
		'https://h/mgmt/tm/security/firewall/address-list/~Common~kur_ssh',
		'init fetches the address-list object at ~Common~kur_ssh' );

	$fw->ban( ban => '1.2.3.4' );
	is( scalar( @{ $fw->{test_data} } ), 1, 'ban is a single request' );
	is( $fw->{test_data}[0]{method}, 'PUT', 'ban PUTs the rendered membership' );
	is( $fw->{test_data}[0]{url},
		'https://h/mgmt/tm/security/firewall/address-list/~Common~kur_ssh',
		'ban PUTs to the address-list object' );
	is( $fw->{test_data}[0]{content}, '{"addresses":[{"name":"1.2.3.4"}]}',
		'ban content lists the single IP as an address entry' );

	$fw->ban( ban => '5.6.7.8' );
	is( $fw->{test_data}[0]{url},
		'https://h/mgmt/tm/security/firewall/address-list/~Common~kur_ssh',
		'second ban still PUTs to the address-list object' );
	is( $fw->{test_data}[0]{content},
		'{"addresses":[{"name":"1.2.3.4"},{"name":"5.6.7.8"}]}',
		'ban content lists both IPs sorted as address entries' );

	$fw->unban( ban => '1.2.3.4' );
	is( $fw->{test_data}[0]{method}, 'PUT', 'unban PUTs the rendered membership' );
	is( $fw->{test_data}[0]{content}, '{"addresses":[{"name":"5.6.7.8"}]}',
		'unban content drops the unbanned IP' );

	ok( $fw->{backend_obj}{cidr_supported}, 'the f5_bigip backend supports CIDR bans' );

	$fw->ban_cidr( ban => '1.2.3.0/24' );
	is( $fw->{test_data}[0]{method}, 'PUT', 'ban_cidr PUTs the rendered membership' );
	is( $fw->{test_data}[0]{content},
		'{"addresses":[{"name":"1.2.3.0/24"},{"name":"5.6.7.8"}]}',
		'ban_cidr content lists the CIDR range as an address entry' );

	my @cidrs = $fw->list_cidr;
	is_deeply( [ sort @cidrs ], ['1.2.3.0/24'], 'list_cidr contains the banned CIDR range' );

	$fw->unban_cidr( ban => '1.2.3.0/24' );
	is( $fw->{test_data}[0]{content}, '{"addresses":[{"name":"5.6.7.8"}]}',
		'unban_cidr content drops the unbanned CIDR range' );

	@cidrs = $fw->list_cidr;
	is_deeply( [ sort @cidrs ], [], 'list_cidr is empty after unban_cidr' );
}

# custom partition and name are honored
{
	my $fw = Net::Firewall::BlockerHelper->new(
		backend => 'f5_bigip', name => 'ssh', testing => 1,
		options => { host => 'h', user => 'u', password => 'p', partition => 'Tenant1', name => 'blocked' },
	);
	$fw->init_backend;
	is( $fw->{test_data}[0]{url},
		'https://h/mgmt/tm/security/firewall/address-list/~Tenant1~blocked',
		'custom partition and name are used for the object id' );

	$fw->ban( ban => '9.9.9.9' );
	is( $fw->{test_data}[0]{url},
		'https://h/mgmt/tm/security/firewall/address-list/~Tenant1~blocked',
		'ban uses the custom object id' );
}

# host, user, and password are all required
for my $missing (qw(host user password)) {
	my %opts = ( host => 'h', user => 'u', password => 'p' );
	delete $opts{$missing};
	my $died = 0;
	eval {
		my $fw = Net::Firewall::BlockerHelper->new(
			backend => 'f5_bigip', name => 'ssh', testing => 1, options => \%opts,
		);
		$fw->init_backend;
	};
	$died = 1 if ($@);
	ok( $died, "missing $missing is fatal" );
}

done_testing();
