use strict;
use warnings;

use OPCUA::Open62541 qw(:STATUSCODE);
use OPCUA::Open62541::Test::Server;
use OPCUA::Open62541::Test::Client;

use Test::More tests => 39;

use Test::Exception;
use Test::LeakTrace;
use Test::NoWarnings;

my $server = OPCUA::Open62541::Test::Server->new();
$server->start();
my $client = OPCUA::Open62541::Test::Client->new(port => $server->port());
$client->start();
$server->run();

ok(my $config = $client->{client}->getConfig(), "config get");

no_leaks_ok {
    $config->setUsernamePassword("user", "pass");
} "setUserNamePassword user/pass";

is($client->{client}->connect($client->url()), STATUSCODE_BADUSERACCESSDENIED,
    "client connect bad user denied");
$client->stop;

$config->setUsernamePassword(undef, undef);
note("client connect anon");
is($client->{client}->connect($client->url()), STATUSCODE_GOOD,
    "client connect anonymous success (undef)");
$client->stop();

$config->setUsernamePassword("", undef);
note("client connect anon");
is($client->{client}->connect($client->url()), STATUSCODE_GOOD,
    "client connect anonymous success (empty string)");
$client->stop();

$config->setUsernamePassword({}, undef);
note("client connect anon");
is($client->{client}->connect($client->url()), STATUSCODE_BADUSERACCESSDENIED,
    "client connect bad user denied (non string)");
$client->stop();

$server->stop();
