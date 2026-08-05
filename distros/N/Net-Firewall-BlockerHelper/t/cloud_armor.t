#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

BEGIN {
	use_ok('Net::Firewall::BlockerHelper') || print "Bail out!\n";
}

# render the deny rule's src-ip-ranges from the ban set
{
	my $fw = Net::Firewall::BlockerHelper->new(
		backend => 'cloud_armor',
		name    => 'ssh',
		testing => 1,
		options => { policy => 'mypol' },
	);
	$fw->init_backend;
	like( $fw->{test_data}[0], qr/security-policies rules describe 1000 --security-policy mypol/,
		'init describes the rule at the default priority' );

	$fw->ban( ban => '1.2.3.4' );
	is( $fw->{test_data},
		'gcloud compute security-policies rules update 1000 --security-policy mypol --src-ip-ranges 1.2.3.4/32',
		'ban updates the rule with the IP as a /32' );

	$fw->ban( ban => '5.6.7.8' );
	is( $fw->{test_data},
		'gcloud compute security-policies rules update 1000 --security-policy mypol --src-ip-ranges 1.2.3.4/32,5.6.7.8/32',
		'second ban renders both ranges, sorted and comma joined' );

	$fw->ban( ban => 'dead::1' );
	like( $fw->{test_data}, qr{dead::1/128}, 'IPv6 rendered as a /128' );

	$fw->unban( ban => '5.6.7.8' );
	unlike( $fw->{test_data}, qr{5\.6\.7\.8}, 'unban drops that range' );

	ok( $fw->{backend_obj}{cidr_supported}, 'cloud_armor reports cidr_supported' );

	$fw->ban_cidr( ban => '1.2.3.0/24' );
	like( $fw->{test_data}, qr{1\.2\.3\.0/24}, 'ban_cidr adds the CIDR to src-ip-ranges' );
	my %listed = map { $_ => 1 } $fw->list_cidr;
	ok( $listed{'1.2.3.0/24'}, 'ban_cidr adds the CIDR to the cidr list' );

	$fw->unban_cidr( ban => '1.2.3.0/24' );
	my %listed2 = map { $_ => 1 } $fw->list_cidr;
	ok( !$listed2{'1.2.3.0/24'}, 'unban_cidr removes the CIDR from the cidr list' );
}

# custom priority and project
{
	my $fw = Net::Firewall::BlockerHelper->new(
		backend => 'cloud_armor', name => 'ssh', testing => 1,
		options => { policy => 'p', priority => 500, project => 'proj' },
	);
	$fw->init_backend;
	$fw->ban( ban => '9.9.9.9' );
	is( $fw->{test_data},
		'gcloud compute security-policies rules update 500 --security-policy p --src-ip-ranges 9.9.9.9/32 --project proj',
		'priority and project honored' );
}

# a failed ban is rolled back out of the ban set
{
	my $fw = Net::Firewall::BlockerHelper->new(
		backend   => 'cloud_armor', name => 'ssh', testing => 1, self_heal => 0,
		options   => { policy => 'p', gcloud_cmd => 'false' },
	);
	$fw->init_backend;
	$fw->ban( ban => '1.2.3.4' );

	# drop out of testing mode so ban runs gcloud_cmd, which always fails
	$fw->{backend_obj}{testing} = 0;
	eval { $fw->ban( ban => '5.6.7.8' ); };
	ok( $@, 'a failed ban is fatal' );
	ok( !$fw->{backend_obj}{banned}{'5.6.7.8'}, 'the failed ban is not left in the ban set' );

	eval { $fw->ban_cidr( ban => '10.0.0.0/8' ); };
	ok( $@, 'a failed ban_cidr is fatal' );
	ok( !$fw->{backend_obj}{banned_cidr}{'10.0.0.0/8'}, 'the failed ban_cidr is not left in the ban set' );

	$fw->{backend_obj}{testing} = 1;
	$fw->ban( ban => '9.9.9.9' );
	unlike( $fw->{test_data}, qr{5\.6\.7\.8}, 'later bans do not re-render the failed range' );
	like( $fw->{test_data}, qr{1\.2\.3\.4/32}, 'earlier successful bans are still rendered' );
}

# policy is required
{
	my $died = 0;
	eval {
		my $fw = Net::Firewall::BlockerHelper->new(
			backend => 'cloud_armor', name => 'ssh', testing => 1, options => {},
		);
		$fw->init_backend;
	};
	$died = 1 if ($@);
	ok( $died, 'missing policy is fatal' );
}

done_testing();
