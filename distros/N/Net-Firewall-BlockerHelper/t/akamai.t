#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

BEGIN {
	use_ok('Net::Firewall::BlockerHelper') || print "Bail out!\n";
}

# ban appends to the network list; unban removes the element
{
	my $fw = Net::Firewall::BlockerHelper->new(
		backend => 'akamai',
		name    => 'ssh',
		prefix  => 'kur',
		testing => 1,
		options => {
			host            => 'akab.ex',
			client_token    => 'ct',
			client_secret   => 'cs',
			access_token    => 'at',
			network_list_id => 'NL',
		},
	);
	$fw->init_backend;

	$fw->ban( ban => '1.2.3.4' );
	is( $fw->{test_data}[0]{method}, 'POST', 'ban appends' );
	is( $fw->{test_data}[0]{url}, 'https://akab.ex/network-list/v2/network-lists/NL/append',
		'append targets the network list' );
	is( $fw->{test_data}[0]{content}, '{"list":["1.2.3.4"]}', 'append body carries the IP' );

	$fw->ban( ban => 'dead::1' );
	is( $fw->{test_data}[0]{content}, '{"list":["dead::1"]}', 'IPv6 appends too' );

	$fw->unban( ban => '1.2.3.4' );
	is( $fw->{test_data}[0]{method}, 'DELETE', 'unban removes the element' );
	is( $fw->{test_data}[0]{url}, 'https://akab.ex/network-list/v2/network-lists/NL/elements?element=1.2.3.4',
		'element is removed by value' );

	# CIDR support
	ok( $fw->{backend_obj}{cidr_supported}, 'cidr is supported' );
	$fw->ban_cidr( ban => '1.2.3.0/24' );
	is( $fw->{test_data}[0]{method}, 'POST', 'ban_cidr appends' );
	is( $fw->{test_data}[0]{content}, '{"list":["1.2.3.0/24"]}', 'ban_cidr body carries the CIDR' );
	my %listed = map { $_ => 1 } $fw->{backend_obj}->list_cidr;
	ok( $listed{'1.2.3.0/24'}, 'list_cidr contains the banned CIDR' );
	$fw->unban_cidr( ban => '1.2.3.0/24' );
	%listed = map { $_ => 1 } $fw->{backend_obj}->list_cidr;
	ok( !$listed{'1.2.3.0/24'}, 'list_cidr no longer contains the CIDR after unban_cidr' );
}

# all EdgeGrid credentials and the list id are required
for my $missing (qw(host client_token client_secret access_token network_list_id)) {
	my %opts = (
		host            => 'h',
		client_token    => 'ct',
		client_secret   => 'cs',
		access_token    => 'at',
		network_list_id => 'NL',
	);
	delete $opts{$missing};
	my $died = 0;
	eval {
		my $fw = Net::Firewall::BlockerHelper->new(
			backend => 'akamai', name => 'ssh', testing => 1, options => \%opts,
		);
		$fw->init_backend;
	};
	$died = 1 if ($@);
	ok( $died, "missing $missing is fatal" );
}

done_testing();
