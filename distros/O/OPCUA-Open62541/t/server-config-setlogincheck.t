use strict;
use warnings;
use OPCUA::Open62541 qw(:STATUSCODE);
use OPCUA::Open62541::Test::Server;
use OPCUA::Open62541::Test::Client;
use OPCUA::Open62541::Test::CA;

use Test::More;
BEGIN {
    if (OPCUA::Open62541::ServerConfig->can(
	'setAccessControl_defaultWithLoginCallback')) {
	plan tests => 57;
    } elsif (not $^C) {
	plan skip_all => 'open62541 has no server config '.
	    'setAccessControl_defaultWithLoginCallback';
    }
}
use Test::Exception;
use Test::LeakTrace;
use Test::NoWarnings;
use Test::Warn;

my $server = OPCUA::Open62541::Test::Server->new();
my $serverconfig = $server->{server}->getConfig();

lives_and { is
    $serverconfig->setAccessControl_defaultWithLoginCallback(0,
	undef, undef, undef, undef, undef),
    STATUSCODE_GOOD
} "without callback";
no_leaks_ok {
    $serverconfig->setAccessControl_defaultWithLoginCallback(0,
	undef, undef, undef, undef, undef),
} "without callback leak";

throws_ok {
    $serverconfig->setAccessControl_defaultWithLoginCallback(0,
	undef, undef, undef, "foo", "bar"),
} qr/Callback 'foo' is not CODE reference and unknown check/, "callback bad";
no_leaks_ok { eval {
    $serverconfig->setAccessControl_defaultWithLoginCallback(0,
	undef, undef, undef, "foo", "bar"),
} } "callback bad leak";

my $can_crypt_newhash =
    OPCUA::Open62541::ServerConfig->can('AccessControl_CryptNewhash');

SKIP: {
    skip "server does not support crypt_checkpass", 2
	unless $can_crypt_newhash;

    lives_and { is
	$serverconfig->setAccessControl_defaultWithLoginCallback(0,
	    undef, undef, undef, "crypt_checkpass", undef),
	STATUSCODE_GOOD
    } "crypt_checkpass";
    no_leaks_ok {
	$serverconfig->setAccessControl_defaultWithLoginCallback(0,
	    undef, undef, undef, "crypt_checkpass", undef),
    } "crypt_checkpass leak";
}

SKIP: {
    skip "server config does not provide crypt_newhash", 8
	unless $can_crypt_newhash;

    throws_ok {
	$serverconfig->AccessControl_CryptNewhash(undef, undef)
    } qr/Undef password /, "crypt_newhash undef";
    no_leaks_ok { eval {
	$serverconfig->AccessControl_CryptNewhash(undef, undef)
    } } "crypt_newhash undef leak";

    lives_and { like
	$serverconfig->AccessControl_CryptNewhash("foo", undef),
	qr{\$2b\$\d+\$[\w/.]+}
    } "crypt_newhash hash";
    no_leaks_ok {
	$serverconfig->AccessControl_CryptNewhash("foo", undef)
    } "crypt_newhash hash leak";

    throws_ok {
	$serverconfig->AccessControl_CryptNewhash("foo", "bar")
    } qr/crypt_newhash: Invalid argument /,"crypt_newhash pref";
    no_leaks_ok { eval {
	$serverconfig->AccessControl_CryptNewhash("foo", "bar")
    } } "crypt_newhash pref leak";

    lives_and { like
	$serverconfig->AccessControl_CryptNewhash("foo", "bcrypt,4"),
	qr{\$2b\$04\$[\w/.]+}
    } "crypt_newhash bcrypt";
    no_leaks_ok {
	$serverconfig->AccessControl_CryptNewhash("foo", "bcrypt,4")
    } "crypt_newhash bcrypt leak";

    note "pass: ". $serverconfig->AccessControl_CryptNewhash("pass");
    note "bar: ". $serverconfig->AccessControl_CryptNewhash("bar");
}

note "test if server uses access control with password hashes";

$server = OPCUA::Open62541::Test::Server->new();
$serverconfig = $server->{server}->getConfig();
$server->start();
my @login = (
    {
	UsernamePasswordLogin_username => "user",
	UsernamePasswordLogin_password => !$can_crypt_newhash ? "pass" :
	    '$2b$08$nz828OX4t7a6Sg8JO/0GnO/bcfY0UyBmlAwkvIGE9ZaBq.0n2tkoS',
    },
    {
	UsernamePasswordLogin_username => "foo",
	UsernamePasswordLogin_password => !$can_crypt_newhash ? "bar" :
	    '$2b$08$4p.1jayeXDdosNjfp5wFce.yYmLcKSrs84qrRJo8LmhbhKr2WKhOK',
    },
);
my $policy = "http://opcfoundation.org/UA/SecurityPolicy#None";
is $serverconfig->setAccessControl_defaultWithLoginCallback(0, undef, $policy,
    \@login, $can_crypt_newhash ? "crypt_checkpass" : undef, undef),
    STATUSCODE_GOOD, "set login";
$server->run();

note "client with user/pass";

my $client = OPCUA::Open62541::Test::Client->new(
    port => $server->port(),
);
my $clientconfig = $client->{client}->getConfig();
$client->start();

is($client->{client}->connect($client->url()),
    STATUSCODE_BADIDENTITYTOKENINVALID, "connect no pass");
$client->stop();

$clientconfig->setUsernamePassword("user", "pass");
is($client->{client}->connect($client->url()), STATUSCODE_GOOD,
    "connect user pass");
$client->stop();

$clientconfig->setUsernamePassword("user", "bar");
is($client->{client}->connect($client->url()), STATUSCODE_BADUSERACCESSDENIED,
    "connect bad pass");
$client->stop();

$clientconfig->setUsernamePassword("foo", "bar");
is($client->{client}->connect($client->url()), STATUSCODE_GOOD,
    "connect other user");
$client->stop();

$clientconfig->setUsernamePassword("nobody", "pass");
is($client->{client}->connect($client->url()), STATUSCODE_BADUSERACCESSDENIED,
    "connect bad user");
$client->stop();

$server->stop();
