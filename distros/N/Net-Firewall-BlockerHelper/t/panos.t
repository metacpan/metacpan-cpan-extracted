#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

BEGIN {
	use_ok('Net::Firewall::BlockerHelper') || print "Bail out!\n";
}

# url-decode a form body so the uid-message XML can be asserted on readably
sub urldecode {
	my ($s) = @_;
	$s =~ s/%([0-9A-Fa-f]{2})/chr( hex($1) )/ge;
	return $s;
}

# ban/unban register/unregister the IP with the tag via the User-ID API
{
	my $fw = Net::Firewall::BlockerHelper->new(
		backend => 'panos',
		name    => 'ssh',
		prefix  => 'kur',
		testing => 1,
		options => { host => 'fw.example', key => 'KEY', tag => 'blocklist', vsys => 'vsys1' },
	);
	$fw->init_backend;

	is( $fw->{test_data}[0]{url}, 'https://fw.example/api/', 'requests go to the /api/ endpoint' );
	like( urldecode( $fw->{test_data}[0]{content} ), qr/type=user-id|type=op/, 'init issues an API call' );

	$fw->ban( ban => '1.2.3.4' );
	my $body = urldecode( $fw->{test_data}[0]{content} );
	like( $body, qr/type=user-id/,    'ban uses the user-id API' );
	like( $body, qr/key=KEY/,         'ban carries the api key' );
	like( $body, qr/vsys=vsys1/,      'ban is scoped to the vsys' );
	like( $body, qr{<register><entry ip="1\.2\.3\.4"><tag><member>blocklist</member>},
		'ban registers the IP with the tag' );

	$fw->ban( ban => 'dead::1' );
	like( urldecode( $fw->{test_data}[0]{content} ), qr{<entry ip="dead::1">}, 'IPv6 registers under the same tag' );

	$fw->unban( ban => '1.2.3.4' );
	like( urldecode( $fw->{test_data}[0]{content} ), qr{<unregister><entry ip="1\.2\.3\.4">},
		'unban unregisters the IP' );

	is_deeply( [ $fw->list ], ['dead::1'], 'list reflects the remaining ban' );

	# CIDR support: the range registers/unregisters under the same tag
	ok( $fw->{backend_obj}{cidr_supported}, 'the panos backend reports CIDR support' );

	$fw->ban_cidr( ban => '1.2.3.0/24' );
	like( urldecode( $fw->{test_data}[0]{content} ), qr{<register><entry ip="1\.2\.3\.0/24"><tag><member>blocklist</member>},
		'ban_cidr registers the CIDR range with the tag' );
	is_deeply( [ $fw->list_cidr ], ['1.2.3.0/24'], 'list_cidr reflects the banned CIDR range' );

	$fw->unban_cidr( ban => '1.2.3.0/24' );
	like( urldecode( $fw->{test_data}[0]{content} ), qr{<unregister><entry ip="1\.2\.3\.0/24">},
		'unban_cidr unregisters the CIDR range' );
	is_deeply( [ $fw->list_cidr ], [], 'list_cidr is empty after unban_cidr' );
}

# host and key are both required
for my $missing (qw(host key)) {
	my %opts = ( host => 'h', key => 'k' );
	delete $opts{$missing};
	my $died = 0;
	eval {
		my $fw = Net::Firewall::BlockerHelper->new(
			backend => 'panos', name => 'ssh', testing => 1, options => \%opts,
		);
		$fw->init_backend;
	};
	$died = 1 if ($@);
	ok( $died, "missing $missing is fatal" );
}

# tag defaults to prefix_name
{
	my $fw = Net::Firewall::BlockerHelper->new(
		backend => 'panos', name => 'web', prefix => 'derp', testing => 1,
		options => { host => 'h', key => 'k' },
	);
	$fw->init_backend;
	$fw->ban( ban => '5.6.7.8' );
	like( urldecode( $fw->{test_data}[0]{content} ), qr{<member>derp_web</member>}, 'default tag is prefix_name' );
}

done_testing();
