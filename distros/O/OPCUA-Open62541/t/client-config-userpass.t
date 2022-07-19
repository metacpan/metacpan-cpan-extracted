use strict;
use warnings;

use OPCUA::Open62541 qw(:STATUSCODE);
use OPCUA::Open62541::Test::Server;
use OPCUA::Open62541::Test::Client;

use Test::More tests => 30;

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
    "client connect denied");

$client->stop();
$server->stop();
