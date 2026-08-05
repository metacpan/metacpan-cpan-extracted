#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

BEGIN {
	use_ok('Net::Firewall::BlockerHelper') || print "Bail out!\n";
}

# ban adds a host object into the group then publishes; unban deletes + publishes
{
	my $fw = Net::Firewall::BlockerHelper->new(
		backend => 'checkpoint',
		name    => 'ssh',
		prefix  => 'kur',
		testing => 1,
		options => { host => 'cp.ex', user => 'u', password => 'p' },
	);
	$fw->init_backend;

	is( $fw->{test_data}[0]{method}, 'POST', 'init logs in' );
	like( $fw->{test_data}[0]{url}, qr{/web_api/login$}, 'init hits the login endpoint' );
	ok( !defined( $fw->{test_data}[0]{content} ), 'login body (password) is not recorded' );

	$fw->ban( ban => '1.2.3.4' );
	is( scalar( @{ $fw->{test_data} } ), 2, 'ban is add-host then publish' );
	like( $fw->{test_data}[0]{url}, qr{/web_api/add-host$}, 'first adds a host' );
	like( $fw->{test_data}[0]{content}, qr/"ip-address":"1\.2\.3\.4"/, 'host carries the IP' );
	like( $fw->{test_data}[0]{content}, qr/"name":"kur_ssh_1-2-3-4"/,   'object name is sanitized' );
	like( $fw->{test_data}[0]{content}, qr/"groups":\["kur_ssh"\]/,     'host is placed in the group' );
	like( $fw->{test_data}[1]{url}, qr{/web_api/publish$}, 'then publishes' );

	$fw->unban( ban => '1.2.3.4' );
	like( $fw->{test_data}[0]{url}, qr{/web_api/delete-host$}, 'unban deletes the host' );
	like( $fw->{test_data}[0]{content}, qr/"name":"kur_ssh_1-2-3-4"/, 'delete references the object name' );
	like( $fw->{test_data}[1]{url}, qr{/web_api/publish$}, 'then publishes' );

	# CIDR bans mirror single-IP bans, adding a host object then publishing
	ok( $fw->{backend_obj}->{cidr_supported}, 'the checkpoint backend supports CIDR bans' );

	$fw->ban_cidr( ban => '1.2.3.0/24' );
	is( scalar( @{ $fw->{test_data} } ), 2, 'ban_cidr is add-host then publish' );
	like( $fw->{test_data}[0]{url},     qr{/web_api/add-host$}, 'ban_cidr first adds a host' );
	like( $fw->{test_data}[0]{content}, qr{"ip-address":"1\.2\.3\.0/24"}, 'host carries the CIDR' );
	like( $fw->{test_data}[1]{url},     qr{/web_api/publish$}, 'then publishes' );

	my @cidr_after_ban = $fw->list_cidr;
	is_deeply( [ sort @cidr_after_ban ], ['1.2.3.0/24'], 'list_cidr contains the CIDR after ban_cidr' );

	$fw->unban_cidr( ban => '1.2.3.0/24' );
	like( $fw->{test_data}[0]{url}, qr{/web_api/delete-host$}, 'unban_cidr deletes the host' );
	like( $fw->{test_data}[1]{url}, qr{/web_api/publish$}, 'then publishes' );

	my @cidr_after_unban = $fw->list_cidr;
	is_deeply( [ sort @cidr_after_unban ], [], 'list_cidr is empty after unban_cidr' );
}

# host/user/password are all required
for my $missing (qw(host user password)) {
	my %opts = ( host => 'h', user => 'u', password => 'p' );
	delete $opts{$missing};
	my $died = 0;
	eval {
		my $fw = Net::Firewall::BlockerHelper->new(
			backend => 'checkpoint', name => 'ssh', testing => 1, options => \%opts,
		);
		$fw->init_backend;
	};
	$died = 1 if ($@);
	ok( $died, "missing $missing is fatal" );
}

done_testing();
