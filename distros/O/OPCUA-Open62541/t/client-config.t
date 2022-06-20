use strict;
use warnings;
use OPCUA::Open62541;

use Test::More tests => 17;
use Test::Exception;
use Test::LeakTrace;
use Test::NoWarnings;

ok(my $client = OPCUA::Open62541::Client->new(), "client new");

ok(my $config = $client->getConfig(), "config get");
is(ref($config), "OPCUA::Open62541::ClientConfig", "config class");
no_leaks_ok { $client->getConfig() } "config leak";

throws_ok { OPCUA::Open62541::Client::getConfig() }
    (qr/Usage: OPCUA::Open62541::Client::getConfig\(client\) /,
    "config missing");
no_leaks_ok { eval { OPCUA::Open62541::Client::getConfig() } }
    "config missing leak";
throws_ok { OPCUA::Open62541::Client::getConfig(undef) }
    (qr/Self client is not a OPCUA::Open62541::Client /,
    "config undef");
no_leaks_ok { eval { OPCUA::Open62541::Client::getConfig(undef) } }
    "config undef leak";

ok(my $config1 = $client->getConfig(), "config get first");
{
    my $config2;
    $client = OPCUA::Open62541::Client->new();
    ok($config2 = $client->getConfig(), "config get second");
}
no_leaks_ok { $client->getConfig() }
    "config get second leak";

# config gets destroyed when leaving scope
$client = OPCUA::Open62541::Client->new();
{
    ok(my $scope1 = $client->getConfig(), "config scope first");
    # client context must be freed with client, not with config
    lives_ok { $scope1->setClientContext("foo") }
	"config scope context";
    lives_ok { $scope1->setStateCallback(sub {"bar"}) }
	"config scope callback";
    {
	ok(my $scope2 = $client->getConfig(), "config scope second");
    }
    {
	ok(my $scope3 = $client->getConfig(), "config scope third");
    }
}
