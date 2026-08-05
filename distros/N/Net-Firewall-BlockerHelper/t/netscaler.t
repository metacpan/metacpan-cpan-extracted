#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

BEGIN {
	use_ok('Net::Firewall::BlockerHelper')                      || print "Bail out!\n";
	use_ok('Net::Firewall::BlockerHelper::backends::netscaler') || print "Bail out!\n";
}

my $base = 'https://ns.foo.bar/nitro/v1/config';

my $fw = Net::Firewall::BlockerHelper->new(
	backend => 'netscaler',
	name    => 'ssh',
	prefix  => 'derp',
	options => { host => 'ns.foo.bar', user => 'nsroot', pass => 'derp' },
	testing => 1,
);
$fw->init_backend;
is_deeply(
	$fw->{test_data},
	{ requests => [ { method => 'GET', url => $base } ] },
	'init probes the NITRO config API'
);

$fw->ban( ban => '1.2.3.4' );
is_deeply(
	$fw->{test_data},
	[
		{
			method  => 'PUT',
			url     => $base . '/policydataset_value_binding',
			content => '{"policydataset_value_binding":{"name":"derp_ssh","value":"1.2.3.4"}}',
		}
	],
	'ban PUTs a dataset binding, defaulting the dataset to prefix_name'
);

$fw->ban( ban => '1.2.3.4' );
is( $fw->{test_data}, 'already banned', 'double ban short-circuits' );

$fw->unban( ban => '1.2.3.4' );
is_deeply(
	$fw->{test_data},
	[ { method => 'DELETE', url => $base . '/policydataset_value_binding/derp_ssh?args=value:1.2.3.4' } ],
	'unban DELETEs the binding'
);

$fw->ban( ban => 'dead::1' );
$fw->unban( ban => 'dead::1' );
is( $fw->{test_data}[0]{url},
	$base . '/policydataset_value_binding/derp_ssh?args=value:dead%3A%3A1',
	'IPv6 IPs are percent encoded in the unban URL' );

my $cidr_blocked = 0;
eval { $fw->ban_cidr( ban => '1.2.3.0/24' ); };
if ( defined( $fw->{error} ) && $fw->{error} == 29 ) { $cidr_blocked = 1; }
if ( !$cidr_blocked ) {
	die( 'ban_cidr did not set frontend error 29 cidrNotSupported... got ' . ( defined( $fw->{error} ) ? $fw->{error} : 'undef' ) );
}

is( $fw->check, 1, 'check reports healthy in testing mode' );
is_deeply( $fw->{test_data}, [ { method => 'GET', url => $base } ], 'check probes the NITRO config API' );

$fw->ban( ban => '1.2.3.4' );
$fw->re_init;
is( $fw->{test_data}[0]{method}, 'PUT', 're_init re-PUTs the remaining bans' );

$fw->teardown;
is( $fw->{test_data}[0]{method}, 'DELETE', 'teardown DELETEs the bindings' );
is( scalar( $fw->list ), 1, 'teardown keeps the ban list for re_init' );

# re-arm the same backend object so the kept ban list is exercised
$fw->{backend_obj}->init;
$fw->flush;
is( scalar( $fw->list ), 0, 'flush empties the ban list' );

# --- dataset option and validation -----------------------------------------------
{
	my $fw2 = Net::Firewall::BlockerHelper->new(
		backend => 'netscaler',
		name    => 'ssh',
		options => { host => 'ns.foo.bar', auth => 'someb64', dataset => 'fail2ban', scheme => 'http' },
		testing => 1,
	);
	$fw2->init_backend;
	$fw2->ban( ban => '1.2.3.4' );
	is( $fw2->{test_data}[0]{url},
		'http://ns.foo.bar/nitro/v1/config/policydataset_value_binding',
		'the scheme option is used' );
	like( $fw2->{test_data}[0]{content}, qr/"name":"fail2ban"/, 'the dataset option is used' );
}
{
	local $@;
	eval { Net::Firewall::BlockerHelper::backends::netscaler->new( name => 'ssh', options => { user => 'a', pass => 'b' } ); };
	ok( $@, 'a missing host errors' );
	is( $Error::Helper::error, 28, 'missing host raises error 28' );

	eval { Net::Firewall::BlockerHelper::backends::netscaler->new( name => 'ssh', options => { host => 'ns.foo.bar' } ); };
	ok( $@, 'missing auth errors' );

	eval {
		Net::Firewall::BlockerHelper::backends::netscaler->new(
			name    => 'ssh',
			ports   => ['22'],
			options => { host => 'ns.foo.bar', auth => 'x' }
		);
	};
	ok( $@, 'ports error as unsupported' );
}

done_testing();
