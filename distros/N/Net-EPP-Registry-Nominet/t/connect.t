#
#===============================================================================
#
#         FILE:  connect.t
#
#  DESCRIPTION: Test of connection to Nominet EPP servers
#               and other basic features of the object.
#
#        NOTES:  Must have set $NOMTAG and $NOMPASS env vars first
#       AUTHOR:  Pete Houston (cpan@openstrike.co.uk)
#      COMPANY:  Openstrike
#      CREATED:  04/02/13 11:54:43
#===============================================================================

use strict;
use warnings FATAL => 'recursion';

use Test::More tests => 46;
use Test::Warn;


BEGIN { use_ok ('Net::EPP::Registry::Nominet') }

my $epp;
my %newargs = (
	ote     => 1,
	login   => 0,
	user    => $ENV{NOMTAG},
	pass    => $ENV{NOMPASS},
	debug   => $ENV{DEBUG_TEST} || 0,
	timeout => ['dog', 'cat']
);

if (defined $Net::EPP::Protocol::THRESHOLD) {
	$Net::EPP::Protocol::THRESHOLD = 10000000; # 10 MB for small servers
}
$epp = Net::EPP::Registry::Nominet->new (%newargs);

SKIP: {
	skip "No access to testbed from this IP address", 9 unless defined $epp;

	ok ($epp->{def_years} == 2, 'def_years validation');

	$epp = new_ok ('Net::EPP::Registry::Nominet', [
		ote   => 1,
		login => 0,
		debug => $ENV{DEBUG_TEST} || 0 ]
	);

	is ($epp->login ('nosuchuser', 'nosuchpass'), undef,
		'Login with duff user');
	my $res;
	warning_is {$res = $epp->login ()} 
		{carped => 'No username (tagname) supplied'},
		'Carped msg for no username';
	is ($epp->get_error, 'No username (tagname) supplied',
		'Error msg for no username');
	is ($res, undef,
		'Login with no args trapped');
	warning_is {$res = $epp->login ('nosuchuser')} 
		{carped => 'No password supplied'},
		'Carped msg for no password';
	is ($res, undef,
		'Login with no password trapped');
	is ($epp->get_error, 'No password supplied',
		'Error msg for no password');
}

SKIP: {
	skip "NOMTAG/NOMPASS not set", 36 unless (defined $ENV{NOMTAG} and defined $ENV{NOMPASS});

	isnt ($epp->login ($ENV{NOMTAG}, $ENV{NOMPASS}), undef, 'Login with good credentials');

	is ($Net::EPP::Registry::Nominet::Code, 1000, 'Logged in');
	
	if ($Net::EPP::Registry::Nominet::Error) {
		diag $Net::EPP::Registry::Nominet::Error;
		BAIL_OUT ("Cannot login to EPP server");
	}

	my $res;
	warning_is {$res = $epp->login ()} 
		{carped => 'Already logged in'},
		'Carped msg for double log-in';
	is ($res, undef, 'Login when already logged in trapped');

	ok ($epp->hello(), 'Hello');
	ok ($epp->ping(), 'Ping');
	ok ($epp->logout(), 'Logout');
	ok ((not defined $epp->hello()), 'Hello attempt when logged out');

	# rt-147136 login as new user.
	is $epp->{authenticated}, 0, 'Unauthenticated';
	is $epp->{connected}, undef, 'Unconnected';
	isnt ($epp->login ("$ENV{NOMTAG}_", $ENV{NOMPASS}), undef, 'Login as secondary user with good credentials');
	is ($Net::EPP::Registry::Nominet::Code, 1000, 'Logged in') or diag
	$epp->get_message;
	is ($epp->{login_params}->[0], "$ENV{NOMTAG}_", 'Correct user');
	ok ($epp->logout(), 'Logout');


	$newargs{login} = 1;
	$epp = Net::EPP::Registry::Nominet->new (%newargs);
	ok (defined $epp, 'Reconnect and Login with good credentials');
	$epp->logout;
	$newargs{login}    = 0;
	$newargs{verify}   = 1;
	$newargs{testssl}  = 1;
	$newargs{ca_file}  = '/foo';
	warnings_exist { $epp = Net::EPP::Registry::Nominet->new (%newargs); }
		[qr/^No greeting returned: cannot continue/,
		qr/^SSL_ca_file \/foo (can't be used|does not exist)/],
		'Expected warnings are thrown';
	ok ((not defined $epp), 'Reconnect with duff SSL cert verification');
	SKIP: {
		skip "Server cert may not be valid now", 1 if time > 1930130556;
		$newargs{ca_file}  = 't/ca.crt';
		$epp = Net::EPP::Registry::Nominet->new (%newargs);
		ok (defined $epp, 'Reconnect with good SSL cert verification');
		delete $newargs{ca_file};
	}
	$newargs{verify}   = 0;
	$newargs{ciphers}  = 'duff';
	warnings_exist { $epp = Net::EPP::Registry::Nominet->new (%newargs); }
		[qr/^No greeting returned: cannot continue/,
		qr/^Connection to ote-epp\.nominet\.org\.uk:700 failed/],
		'Expected warnings are thrown';
	ok ((not defined $epp), 'Reconnect with duff cipher list');

	$newargs{ciphers}  = 'HIGH:!ADH:!MEDIUM:!LOW:!SSLv2:!EXP';
	$epp = Net::EPP::Registry::Nominet->new (%newargs);
	ok (defined $epp, 'Reconnect with good cipher list');

	$newargs{def_years} = 'holiday';
	warning_is {$epp = Net::EPP::Registry::Nominet->new (%newargs)} 
		{carped => 'Supplied parameter def_years is not an integer'},
		'Warning of non-integer value raised';
	ok (defined $epp, 'Reconnect with non-integer def_years');
	ok ($epp->{def_years} == 2, 'def_years validation');
	$newargs{def_years} = 20;
	warning_is {$epp = Net::EPP::Registry::Nominet->new (%newargs)} 
		{carped => 'Supplied parameter def_years is not between 0 and 11'},
		'Warning of out of range value raised';
	ok (defined $epp, 'Reconnect with too large def_years');
	ok ($epp->{def_years} == 2, 'def_years validation');
	$newargs{def_years} = 0;
	warning_is {$epp = Net::EPP::Registry::Nominet->new (%newargs)} 
		{carped => 'Supplied parameter def_years is not between 0 and 11'},
		'Warning of out of range value raised';
	ok (defined $epp, 'Reconnect with too small def_years');
	ok ($epp->{def_years} == 2, 'def_years validation');
	$newargs{def_years} = 5;
	$epp = Net::EPP::Registry::Nominet->new (%newargs);
	ok (defined $epp, 'Reconnect with valid def_years');
	ok ($epp->{def_years} == 5, 'def_years validation');

	# Timeout
	$newargs{timeout} = -1;
	$epp = Net::EPP::Registry::Nominet->new (%newargs);
	ok (defined $epp, 'Reconnect with negative timeout');
	ok ($epp->{timeout} == 5, 'Default timeout set');
	$newargs{timeout} = 10;
	$epp = Net::EPP::Registry::Nominet->new (%newargs);
	ok (defined $epp, 'Reconnect with valid timeout');
	ok ($epp->{timeout} == 10, 'Override timeout set');
};

exit;
