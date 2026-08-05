#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

BEGIN {
	use_ok('Net::Firewall::BlockerHelper') || print "Bail out!\n";
}

# ban/unban route to shorewall (IPv4) and shorewall6 (IPv6) with the type verb
{
	my $fw = Net::Firewall::BlockerHelper->new(
		backend => 'shorewall',
		name    => 'ssh',
		testing => 1,
		options => { type => 'drop' },
	);
	$fw->init_backend;

	$fw->ban( ban => '1.2.3.4' );
	is( $fw->{test_data}, 'shorewall drop 1.2.3.4', 'IPv4 ban uses shorewall drop' );

	$fw->ban( ban => 'dead::1' );
	is( $fw->{test_data}, 'shorewall6 drop dead::1', 'IPv6 ban uses shorewall6 drop' );

	is_deeply( [ sort $fw->list ], [ '1.2.3.4', 'dead::1' ], 'list holds both bans' );

	$fw->unban( ban => '1.2.3.4' );
	is( $fw->{test_data}, 'shorewall allow 1.2.3.4', 'unban uses shorewall allow' );

	is_deeply( [ sort $fw->list ], ['dead::1'], 'list drops the unbanned ip' );

	ok( $fw->{backend_obj}->{cidr_supported}, 'backend reports cidr_supported' );

	$fw->ban_cidr( ban => '1.2.3.0/24' );
	is( $fw->{test_data}, 'shorewall drop 1.2.3.0/24', 'IPv4 CIDR ban uses shorewall drop' );

	$fw->ban_cidr( ban => 'dead::/64' );
	is( $fw->{test_data}, 'shorewall6 drop dead::/64', 'IPv6 CIDR ban uses shorewall6 drop' );

	is_deeply( [ sort $fw->list_cidr ], [ '1.2.3.0/24', 'dead::/64' ], 'list_cidr holds both CIDR bans' );

	$fw->unban_cidr( ban => '1.2.3.0/24' );
	is( $fw->{test_data}, 'shorewall allow 1.2.3.0/24', 'CIDR unban uses shorewall allow' );

	is_deeply( [ sort $fw->list_cidr ], ['dead::/64'], 'list_cidr drops the unbanned CIDR' );
}

# type reject maps to the reject verb
{
	my $fw = Net::Firewall::BlockerHelper->new(
		backend => 'shorewall', name => 'ssh', testing => 1,
		options => { type => 'reject' },
	);
	$fw->init_backend;
	$fw->ban( ban => '9.9.9.9' );
	is( $fw->{test_data}, 'shorewall reject 9.9.9.9', 'type reject uses the reject verb' );
}

# an invalid type is fatal
{
	my $died = 0;
	eval {
		my $fw = Net::Firewall::BlockerHelper->new(
			backend => 'shorewall', name => 'ssh', testing => 1,
			options => { type => 'bogus' },
		);
		$fw->init_backend;
	};
	$died = 1 if ($@);
	ok( $died, 'invalid type is fatal' );
}

done_testing();
