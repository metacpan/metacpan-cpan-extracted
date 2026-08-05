#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

BEGIN {
	use_ok('Net::Firewall::BlockerHelper')                       || print "Bail out!\n";
	use_ok('Net::Firewall::BlockerHelper::backends::cloudflare') || print "Bail out!\n";
}

my $zone_endpoint = 'https://api.cloudflare.com/client/v4/zones/abc123/firewall/access_rules/rules';
my $user_endpoint = 'https://api.cloudflare.com/client/v4/user/firewall/access_rules/rules';

# --- token auth, zone level ---------------------------------------------------
{
	my $fw = Net::Firewall::BlockerHelper->new(
		backend => 'cloudflare',
		name    => 'ssh',
		prefix  => 'derp',
		options => { token => 'sometoken', zone => 'abc123' },
		testing => 1,
	);
	$fw->init_backend;
	is_deeply(
		$fw->{test_data},
		{ requests => [ { method => 'GET', url => $zone_endpoint . '?per_page=5' } ] },
		'init probes the zone level endpoint'
	);

	$fw->ban( ban => '1.2.3.4' );
	is_deeply(
		$fw->{test_data},
		[
			{
				method  => 'POST',
				url     => $zone_endpoint,
				content => '{"configuration":{"target":"ip","value":"1.2.3.4"},"mode":"block","notes":"derp_ssh"}',
			}
		],
		'IPv4 ban POSTs an access rule with target ip'
	);

	$fw->ban( ban => 'dead::1' );
	is( $fw->{test_data}[0]{content},
		'{"configuration":{"target":"ip6","value":"dead::1"},"mode":"block","notes":"derp_ssh"}',
		'IPv6 ban uses target ip6' );

	$fw->ban( ban => '1.2.3.4' );
	is( $fw->{test_data}, 'already banned', 'double ban short-circuits' );

	$fw->unban( ban => '1.2.3.4' );
	is_deeply(
		$fw->{test_data},
		[
			{
				method => 'GET',
				url    => $zone_endpoint
					. '?mode=block&notes=derp_ssh&configuration.target=ip&configuration.value=1.2.3.4',
			},
			{ method => 'DELETE', url => $zone_endpoint . '/<id>' },
		],
		'unban looks the rule up by target/value/notes and deletes it'
	);

	ok( $fw->{backend_obj}{cidr_supported}, 'cloudflare reports cidr_supported' );
	$fw->ban_cidr( ban => '1.2.3.0/24' );
	my %listed = map { $_ => 1 } $fw->list_cidr;
	ok( $listed{'1.2.3.0/24'}, 'ban_cidr adds the cidr to list_cidr' );
	$fw->unban_cidr( ban => '1.2.3.0/24' );
	my %listed2 = map { $_ => 1 } $fw->list_cidr;
	ok( !$listed2{'1.2.3.0/24'}, 'unban_cidr removes the cidr from list_cidr' );

	is( $fw->check, 1, 'check reports healthy in testing mode' );
	is_deeply(
		$fw->{test_data},
		[ { method => 'GET', url => $zone_endpoint . '?per_page=5' } ],
		'check probes the endpoint'
	);

	$fw->re_init;
	is( $fw->{test_data}[0]{method}, 'POST', 're_init re-POSTs the remaining ban' );
	like( $fw->{test_data}[0]{content}, qr/dead::1/, 're_init re-adds the remaining banned IP' );

	$fw->flush;
	is( scalar( @{ $fw->{test_data} } ), 2,, 'flush removes the rule for each banned IP' );
	is( scalar( $fw->list ),             0,  'flush empties the ban list' );
}

# --- legacy email + key auth, user level ---------------------------------------
{
	my $fw = Net::Firewall::BlockerHelper->new(
		backend => 'cloudflare',
		name    => 'ssh',
		options => { email => 'foo@bar', key => 'somekey', mode => 'challenge' },
		testing => 1,
	);
	$fw->init_backend;
	is( $fw->{test_data}{requests}[0]{url},
		$user_endpoint . '?per_page=5', 'no zone option means the user level endpoint' );

	$fw->ban( ban => '1.2.3.4' );
	like( $fw->{test_data}[0]{content}, qr/"mode":"challenge"/, 'the mode option is used' );
}

# --- validation, on the backend directly as that is where these are checked ------
{
	local $@;
	eval { Net::Firewall::BlockerHelper::backends::cloudflare->new( name => 'ssh' ); };
	ok( $@, 'no auth options errors' );
	is( $Error::Helper::error, 28, 'missing auth raises error 28' );

	eval {
		Net::Firewall::BlockerHelper::backends::cloudflare->new(
			name    => 'ssh',
			options => { token => 't', mode => 'derp' }
		);
	};
	ok( $@, 'an invalid mode errors' );

	eval {
		Net::Firewall::BlockerHelper::backends::cloudflare->new(
			name    => 'ssh',
			ports   => ['22'],
			options => { token => 't' }
		);
	};
	ok( $@, 'ports error as unsupported' );
	is( $Error::Helper::error, 26, 'ports raise error 26' );
}

done_testing();
