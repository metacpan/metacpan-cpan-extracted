use strict;
use warnings;

use Test::More;

use_ok( 'Net::MCMP', 'use mcmp' );

my $mcmp_uri = $ENV{MCMP_TEST_URI} || 'http://127.0.0.1:6666';
my $mcmp = Net::MCMP->new( { uri => $mcmp_uri, debug => 0 } );

is( ref $mcmp,  'Net::MCMP', 'making sure object created' );
is( $mcmp->uri, $mcmp_uri,   'making sure URI is returned correctly' );

SKIP: {
	skip "live tests, MCMP_LIVE environment variable is not set", 39
	  unless $ENV{MCMP_LIVE_TESTS};

	print
"using MCMP URI: $mcmp_uri to override, set nvironment variable MCMP_TEST_URI\n";

	ok(
		$mcmp->config(
			{
				StickySession       => 'yes',
				StickySessionCookie => 'session',
				StickySessionPath   => '',
				JvmRoute            => 'MyJVMRoute',
				Domain              => 'Foo',
				Host                => 'localhost',
				Port                => '3000',
				Type                => 'http',
				Context             => '/cluster',
				Alias               => 'SomeHost',
			}
		),
		'checking config'
	);
	ok( !$mcmp->has_error, 'no errors' );

	ok(
		my $ping_resp = $mcmp->ping(
			{
				JvmRoute => 'MyJVMRoute',
			}
		),
		'ping command'
	);

	is( $ping_resp->{'State'},    'OK',         'status State response' );
	is( $ping_resp->{'JvmRoute'}, 'MyJVMRoute', 'status JVMRoute response' );
	is( $ping_resp->{'Type'},     'PING-RSP',   'ping Type response' );
	ok( $ping_resp->{'id'}, 'status id response' );

	ok( !$mcmp->has_error, 'no errors' );

	ok(
		$mcmp->enable_app(
			{
				JvmRoute => 'MyJVMRoute',
				Alias    => 'SomeHost',
				Context  => '/cluster'
			}
		),
		'enable context'
	);
	ok( !$mcmp->has_error, 'no errors' );

	ok( $mcmp->dump,       'response from dump command' );
	ok( !$mcmp->has_error, 'no errors' );
	ok( $mcmp->info,       'response from info command' );
	ok( !$mcmp->has_error, 'no errors' );


	ok(
		my $status_resp = $mcmp->status(
			{
				JvmRoute => 'MyJVMRoute',
				Load     => 55,
			}
		),
		'status'
	);

	#$VAR1 = {
	#          'State' => 'OK',
	#          'JvmRoute' => 'MyJVMRoute',
	#          'id' => '-297586570',
	#          'Type' => 'STATUS-RSP'
	#        };

	is( $status_resp->{'State'},    'OK',         'status State response' );
	is( $status_resp->{'JvmRoute'}, 'MyJVMRoute', 'status JVMRoute response' );
	is( $status_resp->{'Type'},     'STATUS-RSP', 'status Type response' );
	ok( $status_resp->{'id'}, 'status id response' );

	#Type=STATUS-RSP&JVMRoute=MyJVMRoute&State=OK&id=-297586570

	ok( !$mcmp->has_error, 'no errors' );

	ok(
		$mcmp->disable_app(
			{
				JvmRoute => 'MyJVMRoute',
				Alias    => 'SomeHost',
				Context  => '/cluster'
			}
		),
		'disable context'
	);

	ok( !$mcmp->has_error, 'no errors' );

	ok(
		my $stop_resp = $mcmp->stop_app(
			{
				JvmRoute => 'MyJVMRoute',
				Alias    => 'SomeHost',
				Context  => '/cluster'
			}
		),
		'stop context'
	);

#$VAR1 = {
#          'Type' => 'STOP-APP-RSP',
#          'Context' => '/cluster',
#          'JvmRoute' => 'MyJVMRoute',
#          'Requests' => '0',
#          'Alias' => 'SomeHost'
#        };
# Type=STOP-APP-RSP&JvmRoute=MyJVMRoute&Alias=SomeHost&Context=/cluster&Requests=0
	is( $stop_resp->{'Type'},    'STOP-APP-RSP', 'stop-app Type response' );
	is( $stop_resp->{'Alias'},   'SomeHost',     'stop-app alias response' );
	is( $stop_resp->{'Context'}, '/cluster',     'stop-app context response' );
	like( $stop_resp->{'Requests'}, qr/\d+/, 'stop-app requests response' );

	ok( !$mcmp->has_error, 'no errors' );

	ok(
		$mcmp->enable_route(
			{
				JvmRoute => 'MyJVMRoute',
			}
		),
		'enable route'
	);

	ok( !$mcmp->has_error, 'no errors' );

	ok(
		$mcmp->disable_route(
			{
				JvmRoute => 'MyJVMRoute',
			}
		),
		'disable route'
	);

	ok( !$mcmp->has_error, 'no errors' );

	ok(
		$mcmp->stop_route(
			{
				JvmRoute => 'MyJVMRoute',
			}
		),
		'stop route'
	);

	ok( !$mcmp->has_error, 'no errors' );

	ok(
		$mcmp->remove_app(
			{
				JvmRoute => 'MyJVMRoute',
				Alias    => 'SomeHost',
				Context  => '/cluster'
			}
		),
		'remove context'
	);

	ok( !$mcmp->has_error, 'no errors' );

	ok(
		$mcmp->remove_route(
			{
				JvmRoute => 'MyJVMRoute',
			}
		),
		'remove route'
	);

	ok( !$mcmp->has_error, 'no errors' );

}

done_testing();