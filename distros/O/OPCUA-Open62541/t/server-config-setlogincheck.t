use strict;
use warnings;
use OPCUA::Open62541 qw(:STATUSCODE);
use OPCUA::Open62541::Test::Server;
use OPCUA::Open62541::Test::Client;
use OPCUA::Open62541::Test::CA;

use Test::More;
BEGIN {
    if (OPCUA::Open62541::ServerConfig->can('setAccessControl_loginCheck')) {
	plan tests => 61;
    } else {
	plan skip_all =>
	    'open62541 has no server config setAccessControl_loginCheck';
    }
}
use Test::Exception;
use Test::LeakTrace;
use Test::NoWarnings;
use Test::Warn;

my $server = OPCUA::Open62541::Test::Server->new();
my $serverconfig = $server->{server}->getConfig();

lives_and { is
    $serverconfig->setAccessControl_loginCheck(undef),
    STATUSCODE_BADINTERNALERROR
} "access control";
no_leaks_ok {
    $serverconfig->setAccessControl_loginCheck(undef),
} "access control leak";

is $serverconfig->setAccessControl_default(0, undef, undef, undef),
    STATUSCODE_GOOD, "access control default";

lives_and { is
    $serverconfig->setAccessControl_loginCheck(undef),
    STATUSCODE_GOOD
} "unset";
no_leaks_ok {
    $serverconfig->setAccessControl_loginCheck(undef),
} "unset leak";

lives_and { is
    $serverconfig->setAccessControl_loginCheck("foo"),
    STATUSCODE_BADINVALIDARGUMENT
} "set bad";
no_leaks_ok {
    $serverconfig->setAccessControl_loginCheck("foo"),
} "set bad leak";

my $can_crypt_newhash =
    OPCUA::Open62541::ServerConfig->can('AccessControl_CryptNewhash');

lives_and { is
    $serverconfig->setAccessControl_loginCheck("crypt_checkpass"),
    $can_crypt_newhash ? STATUSCODE_GOOD : STATUSCODE_BADINVALIDARGUMENT;
} "set crypt_checkpass";
no_leaks_ok {
    $serverconfig->setAccessControl_loginCheck("crypt_checkpass"),
} "set crypt_checkpass leak";

SKIP: {
    skip "server does not support crypt_checkpass", 8 if !$can_crypt_newhash;

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
is $serverconfig->setAccessControl_default(0, undef, $policy, \@login),
    STATUSCODE_GOOD, "set login";
is $serverconfig->setAccessControl_loginCheck("crypt_checkpass"),
    $can_crypt_newhash ? STATUSCODE_GOOD : STATUSCODE_BADINVALIDARGUMENT,
    "set crypt";
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
