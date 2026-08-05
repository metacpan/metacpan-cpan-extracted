#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

BEGIN {
	use_ok('Net::Firewall::BlockerHelper') || print "Bail out!\n";
}

# ban creates an ACL entry via POST, unban does a GET-then-DELETE
{
	my $fw = Net::Firewall::BlockerHelper->new(
		backend => 'fastly',
		name    => 'ssh',
		prefix  => 'kur',
		testing => 1,
		options => { token => 'TOK', service => 'SID', acl => 'AID' },
	);
	$fw->init_backend;

	is( $fw->{test_data}[0]{method}, 'GET', 'init probes the entries with a GET' );
	is( $fw->{test_data}[0]{url},
		'https://api.fastly.com/service/SID/acl/AID/entries?per_page=1',
		'init fetches a single ACL entry' );

	$fw->ban( ban => '1.2.3.4' );
	is( scalar( @{ $fw->{test_data} } ), 1, 'ban is a single request' );
	is( $fw->{test_data}[0]{method}, 'POST', 'ban does a POST' );
	is( $fw->{test_data}[0]{url}, 'https://api.fastly.com/service/SID/acl/AID/entry',
		'ban posts to the entry endpoint' );
	is( $fw->{test_data}[0]{content}, '{"ip":"1.2.3.4","subnet":32}',
		'IPv4 ban body has the ip and a /32 subnet' );

	$fw->ban( ban => 'dead::1' );
	is( $fw->{test_data}[0]{method}, 'POST', 'IPv6 ban does a POST' );
	is( $fw->{test_data}[0]{content}, '{"ip":"dead::1","subnet":128}',
		'IPv6 ban body uses subnet 128' );

	$fw->unban( ban => '1.2.3.4' );
	is( scalar( @{ $fw->{test_data} } ), 2, 'unban is two requests' );
	is( $fw->{test_data}[0]{method}, 'GET', 'unban first looks up the entries with a GET' );
	is( $fw->{test_data}[0]{url}, 'https://api.fastly.com/service/SID/acl/AID/entries',
		'unban GET hits the entries endpoint' );
	is( $fw->{test_data}[1]{method}, 'DELETE', 'unban then deletes' );
	is( $fw->{test_data}[1]{url}, 'https://api.fastly.com/service/SID/acl/AID/entry/<id>',
		'unban DELETE targets the entry by id' );

	# CIDR support
	ok( $fw->{backend_obj}{cidr_supported}, 'fastly reports cidr_supported' );

	$fw->ban_cidr( ban => '1.2.3.0/24' );
	is( $fw->{test_data}[0]{method}, 'POST', 'ban_cidr does a POST like ban' );
	is( $fw->{test_data}[0]{url}, 'https://api.fastly.com/service/SID/acl/AID/entry',
		'ban_cidr posts to the entry endpoint' );
	is( $fw->{test_data}[0]{content}, '{"ip":"1.2.3.0","subnet":24}',
		'ban_cidr body splits the CIDR into ip and subnet' );

	my %listed = map { $_ => 1 } $fw->list_cidr;
	ok( $listed{'1.2.3.0/24'}, 'ban_cidr adds the CIDR to list_cidr' );

	$fw->unban_cidr( ban => '1.2.3.0/24' );
	my %listed2 = map { $_ => 1 } $fw->list_cidr;
	ok( !$listed2{'1.2.3.0/24'}, 'unban_cidr removes the CIDR from list_cidr' );
}

# token, service, and acl are each required
for my $missing (qw(token service acl)) {
	my %opts = ( token => 'TOK', service => 'SID', acl => 'AID' );
	delete $opts{$missing};
	my $died = 0;
	eval {
		my $fw = Net::Firewall::BlockerHelper->new(
			backend => 'fastly', name => 'ssh', testing => 1, options => \%opts,
		);
		$fw->init_backend;
	};
	$died = 1 if ($@);
	ok( $died, "missing $missing is fatal" );
}

done_testing();
