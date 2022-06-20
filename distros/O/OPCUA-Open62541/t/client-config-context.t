use strict;
use warnings;
use OPCUA::Open62541;

use Test::More tests => 11;
use Test::Exception;
use Test::LeakTrace;
use Test::NoWarnings;

ok(my $client = OPCUA::Open62541::Client->new(), "client new");
ok(my $config = $client->getConfig(), "config get");

is(my $context = $config->getClientContext(), undef, "context undef");
no_leaks_ok { $config->getClientContext() } "context undef leak";

$context = "foo";
lives_ok { $config->setClientContext($context) } "set context";
no_leaks_ok { $config->setClientContext($context) } "set context leak";
is($config->getClientContext(), "foo", "context foo");
$context = "bar";
is($config->getClientContext(), "foo", "context not bar");
no_leaks_ok { $config->getClientContext() } "context foo leak";

no_leaks_ok {
    my $client = OPCUA::Open62541::Client->new();
    my $config = $client->getConfig();
    $config->setClientContext("foo");
    $config->setClientContext("bar");
} "context leak";
