#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

BEGIN {
	use_ok('Net::Firewall::BlockerHelper') || print "Bail out!\n";
}

# ban loads a set-format config then commits; unban deletes then commits
{
	my $fw = Net::Firewall::BlockerHelper->new(
		backend => 'juniper_srx',
		name    => 'ssh',
		prefix  => 'kur',
		testing => 1,
		options => { host => 'srx.ex', user => 'u', password => 'p' },
	);
	$fw->init_backend;

	$fw->ban( ban => '1.2.3.4' );
	is( scalar( @{ $fw->{test_data} } ), 2, 'ban is a load then a commit' );
	is( $fw->{test_data}[0]{url}, 'https://srx.ex/rpc', 'config load goes to the /rpc endpoint' );
	like( $fw->{test_data}[0]{content},
		qr{set security address-book global address kur_ssh_1-2-3-4 1\.2\.3\.4/32},
		'load sets the address object as a /32' );
	like( $fw->{test_data}[0]{content},
		qr{set security address-book global address-set kur_ssh address kur_ssh_1-2-3-4},
		'address is placed in the address-set' );
	like( $fw->{test_data}[1]{content}, qr{<commit-configuration/>}, 'then commits' );

	$fw->ban( ban => 'dead::1' );
	like( $fw->{test_data}[0]{content}, qr{dead::1/128}, 'IPv6 uses a /128' );

	$fw->unban( ban => '1.2.3.4' );
	like( $fw->{test_data}[0]{content},
		qr{delete security address-book global address kur_ssh_1-2-3-4},
		'unban deletes the address object' );
	like( $fw->{test_data}[1]{content}, qr{<commit-configuration/>}, 'then commits' );

	ok( $fw->{backend_obj}{cidr_supported}, 'the juniper_srx backend supports CIDR bans' );

	$fw->ban_cidr( ban => '1.2.3.0/24' );
	is( scalar( @{ $fw->{test_data} } ), 2, 'ban_cidr is a load then a commit' );
	like( $fw->{test_data}[0]{content},
		qr{set security address-book global address kur_ssh_1-2-3-0-24 1\.2\.3\.0/24},
		'load sets the CIDR address object with its own prefix' );
	unlike( $fw->{test_data}[0]{content}, qr{address kur_ssh_1-2-3-0/24},
		'the CIDR object name contains no slash' );
	like( $fw->{test_data}[0]{content},
		qr{set security address-book global address-set kur_ssh address kur_ssh_1-2-3-0-24},
		'CIDR address is placed in the address-set' );
	like( $fw->{test_data}[1]{content}, qr{<commit-configuration/>}, 'then commits' );
	is_deeply( [ $fw->list_cidr ], ['1.2.3.0/24'], 'list_cidr shows the banned CIDR' );

	$fw->unban_cidr( ban => '1.2.3.0/24' );
	like( $fw->{test_data}[0]{content},
		qr{delete security address-book global address kur_ssh_1-2-3-0-24},
		'unban_cidr deletes the CIDR address object' );
	is_deeply( [ $fw->list_cidr ], [], 'list_cidr is empty after unban_cidr' );
}

# host/user/password are all required
for my $missing (qw(host user password)) {
	my %opts = ( host => 'h', user => 'u', password => 'p' );
	delete $opts{$missing};
	my $died = 0;
	eval {
		my $fw = Net::Firewall::BlockerHelper->new(
			backend => 'juniper_srx', name => 'ssh', testing => 1, options => \%opts,
		);
		$fw->init_backend;
	};
	$died = 1 if ($@);
	ok( $died, "missing $missing is fatal" );
}

done_testing();
