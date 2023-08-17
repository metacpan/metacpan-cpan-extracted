use strict;
use warnings;
use OPCUA::Open62541 qw(:STATUSCODE);
use OPCUA::Open62541::Test::Server;
use OPCUA::Open62541::Test::Client;
use OPCUA::Open62541::Test::CA;

use Test::More tests => 110;
use Test::Exception;
use Test::LeakTrace;
use Test::NoWarnings;
use Test::Warn;

my $server = OPCUA::Open62541::Test::Server->new();
my $serverconfig = $server->{server}->getConfig();

lives_and { is
    $serverconfig->setAccessControl_default(0, undef, undef, undef),
    STATUSCODE_GOOD
} "undef good";
no_leaks_ok {
    $serverconfig->setAccessControl_default(0, undef, undef, undef)
} "undef leak";

lives_and { is
    $serverconfig->setAccessControl_default(1, undef, undef, undef),
    STATUSCODE_GOOD
} "anon good";
no_leaks_ok {
    $serverconfig->setAccessControl_default(1, undef, undef, undef)
} "anon leak";

my $verify = OPCUA::Open62541::CertificateVerification->new();
ok($verify, "verification new");
my $sc = $verify->Trustlist(undef, undef, undef);
is($sc, STATUSCODE_GOOD, "trustlist good");

throws_ok {
    $serverconfig->setAccessControl_default(0, $verify, undef, undef),
} qr/VerifyX509 needs userTokenPolicyUri/, "verify undef";
no_leaks_ok { eval {
    $serverconfig->setAccessControl_default(0, $verify, undef, undef)
} } "verify undef leak";

lives_and { is
    $serverconfig->setAccessControl_default(0, $verify, "uri", undef),
    STATUSCODE_GOOD
} "verify good";
no_leaks_ok {
    $serverconfig->setAccessControl_default(0, $verify, "uri", undef)
} "verify leak";

lives_and { is
    $serverconfig->setAccessControl_default(0, undef, "uri", undef),
    STATUSCODE_GOOD
} "uri good";
no_leaks_ok {
    $serverconfig->setAccessControl_default(0, undef, "uri", undef)
} "uri leak";

lives_and { is
    $serverconfig->setAccessControl_default(0, undef, undef, []),
    STATUSCODE_GOOD
} "login empty good";
no_leaks_ok {
    $serverconfig->setAccessControl_default(0, undef, undef, [])
} "login empty leak";

my @login = (
    {
	UsernamePasswordLogin_username => "user",
	UsernamePasswordLogin_password => "pass",
    },
);

throws_ok {
    $serverconfig->setAccessControl_default(0, undef, undef, \@login),
} qr/UsernamePasswordLogin needs userTokenPolicyUri/, "login undef";
no_leaks_ok { eval {
    $serverconfig->setAccessControl_default(0, undef, undef, \@login)
} } "login undef leak";

lives_and { is
    $serverconfig->setAccessControl_default(0, undef, "uri", \@login),
    STATUSCODE_GOOD
} "login good";
no_leaks_ok {
    $serverconfig->setAccessControl_default(0, undef, "uri", \@login)
} "login leak";

push @login, { UsernamePasswordLogin_username => "passmiss" };

throws_ok {
    $serverconfig->setAccessControl_default(0, undef, "uri", \@login),
} qr/No UsernamePasswordLogin_password in HASH/, "login passmiss";
no_leaks_ok { eval {
    $serverconfig->setAccessControl_default(0, undef, "uri", \@login)
} } "login passmiss leak";

pop @login;

note "test if server respects new access control method";

note "server with default password";

my $ca = OPCUA::Open62541::Test::CA->new();
$ca->setup();
$ca->create_cert_client(issuer => $ca->create_cert_ca(name => "ca_client"));
$ca->create_cert_server(issuer => $ca->create_cert_ca(name => "ca_server"));

$server = OPCUA::Open62541::Test::Server->new(
    certificate    => $ca->{certs}{server}{cert_pem},
    privateKey     => $ca->{certs}{server}{key_pem},
);
$serverconfig = $server->{server}->getConfig();
$server->start();

note "client with default password";

my $client = OPCUA::Open62541::Test::Client->new(
    port => $server->port(),
    certificate    => $ca->{certs}{client}{cert_pem},
    privateKey     => $ca->{certs}{client}{key_pem},
);
my $clientconfig = $client->{client}->getConfig();
$client->start();
$server->run();

$clientconfig->setUsernamePassword("user1", "password");
is($client->{client}->connect($client->url()), STATUSCODE_GOOD,
    "connect user1 good");

$client->stop();

note "client without username";

$client = OPCUA::Open62541::Test::Client->new(
    port => $server->port(),
    certificate    => $ca->{certs}{client}{cert_pem},
    privateKey     => $ca->{certs}{client}{key_pem},
);
$clientconfig = $client->{client}->getConfig();
$client->start();

is($client->{client}->connect($client->url()), STATUSCODE_GOOD,
    "connect without username good");

$client->stop();
$server->stop();

note "server with user/pass access control";

$server = OPCUA::Open62541::Test::Server->new(
    certificate    => $ca->{certs}{server}{cert_pem},
    privateKey     => $ca->{certs}{server}{key_pem},
);
$serverconfig = $server->{server}->getConfig();
$server->start();
my $policy = "http://opcfoundation.org/UA/SecurityPolicy#None";
is($serverconfig->setAccessControl_default(0, undef, $policy, \@login),
    STATUSCODE_GOOD, "set login");

note "client with default passowrd";

$client = OPCUA::Open62541::Test::Client->new(
    port => $server->port(),
    certificate    => $ca->{certs}{client}{cert_pem},
    privateKey     => $ca->{certs}{client}{key_pem},
);
$clientconfig = $client->{client}->getConfig();
$client->start();
$server->run();

$clientconfig->setUsernamePassword("user1", "password");
is($client->{client}->connect($client->url()), STATUSCODE_BADUSERACCESSDENIED,
    "connect user1 bad");

$client->stop();

note "client with user/pass";

$client = OPCUA::Open62541::Test::Client->new(
    port => $server->port(),
    certificate    => $ca->{certs}{client}{cert_pem},
    privateKey     => $ca->{certs}{client}{key_pem},
);
$clientconfig = $client->{client}->getConfig();
$client->start();

$clientconfig->setUsernamePassword("user", "pass");
is($client->{client}->connect($client->url()), STATUSCODE_GOOD,
    "connect user pass");

$client->stop();

note "client without username";

$client = OPCUA::Open62541::Test::Client->new(
    port => $server->port(),
    certificate    => $ca->{certs}{client}{cert_pem},
    privateKey     => $ca->{certs}{client}{key_pem},
);
$clientconfig = $client->{client}->getConfig();
$client->start();

is($client->{client}->connect($client->url()),
    STATUSCODE_BADIDENTITYTOKENINVALID, "connect without username bad");

$client->stop();
$server->stop();
