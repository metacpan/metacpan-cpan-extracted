#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

BEGIN {
	use_ok('Net::Firewall::BlockerHelper') || print "Bail out!\n";
}

# ban does a get-ip-set then an update-ip-set with the rendered addresses
{
	my $fw = Net::Firewall::BlockerHelper->new(
		backend => 'aws_wafv2',
		name    => 'ssh',
		testing => 1,
		options => { name4 => 'v4set', id4 => 'ID4', name6 => 'v6set', id6 => 'ID6' },
	);
	$fw->init_backend;
	like( $fw->{test_data}[0], qr/wafv2 get-ip-set --scope REGIONAL --name v4set --id ID4/, 'init gets the v4 set' );
	like( $fw->{test_data}[1], qr/--name v6set --id ID6/, 'init gets the v6 set too' );

	$fw->ban( ban => '1.2.3.4' );
	is( scalar( @{ $fw->{test_data} } ), 2, 'ban is get then update' );
	like( $fw->{test_data}[0], qr/wafv2 get-ip-set --scope REGIONAL --name v4set --id ID4/, 'ban gets the v4 set' );
	is( $fw->{test_data}[1],
		'aws wafv2 update-ip-set --scope REGIONAL --name v4set --id ID4 --addresses 1.2.3.4/32 --lock-token <lock-token>',
		'ban updates the v4 set with the CIDR and a lock token' );

	$fw->ban( ban => '5.6.7.8' );
	like( $fw->{test_data}[1], qr{--addresses 1\.2\.3\.4/32 5\.6\.7\.8/32 }, 'second v4 ban renders both, sorted' );

	$fw->ban( ban => 'dead::1' );
	like( $fw->{test_data}[1], qr/--name v6set --id ID6 --addresses dead::1\/128 /, 'IPv6 ban targets the v6 set' );

	# CIDR support
	ok( $fw->{backend_obj}{cidr_supported}, 'aws_wafv2 reports cidr_supported' );

	$fw->ban_cidr( ban => '1.2.3.0/24' );
	like( $fw->{test_data}[1], qr{--name v4set --id ID4 --addresses .*1\.2\.3\.0/24}, 'ban_cidr renders the CIDR as is into the v4 set' );
	my %listed = map { $_ => 1 } $fw->list_cidr;
	ok( $listed{'1.2.3.0/24'}, 'ban_cidr adds the CIDR to list_cidr' );

	$fw->unban_cidr( ban => '1.2.3.0/24' );
	%listed = map { $_ => 1 } $fw->list_cidr;
	ok( !$listed{'1.2.3.0/24'}, 'unban_cidr removes the CIDR from list_cidr' );
}

# banning a family whose set is not configured is fatal
{
	my $died = 0;
	eval {
		my $fw = Net::Firewall::BlockerHelper->new(
			backend => 'aws_wafv2', name => 'ssh', testing => 1,
			options => { name4 => 'v4set', id4 => 'ID4' },
		);
		$fw->init_backend;
		$fw->ban( ban => 'dead::1' );
	};
	$died = 1 if ($@);
	ok( $died, 'banning IPv6 with no v6 set configured is fatal' );
}

# an invalid scope is fatal
{
	my $died = 0;
	eval {
		my $fw = Net::Firewall::BlockerHelper->new(
			backend => 'aws_wafv2', name => 'ssh', testing => 1,
			options => { scope => 'GLOBAL', name4 => 'v4', id4 => 'i' },
		);
		$fw->init_backend;
	};
	$died = 1 if ($@);
	ok( $died, 'an invalid scope is fatal' );
}

done_testing();
