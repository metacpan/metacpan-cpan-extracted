use strict;
use warnings;
use OPCUA::Open62541;

use Test::More;
BEGIN {
    if (OPCUA::Open62541::ServerConfig->can('setCustomHostname')) {
	plan tests => 14;
    } else {
	plan skip_all => 'open62541 has no server config customHostname';
    }
}
use Test::Exception;
use Test::LeakTrace;
use Test::NoWarnings;

ok(my $server = OPCUA::Open62541::Server->new(), "server new");
ok(my $config = $server->getConfig(), "config get");

is($config->getCustomHostname(), undef, "get unset");
no_leaks_ok { $config->getCustomHostname() } "get unset leak";

throws_ok { $config->setCustomHostname() } (qr/Usage:/, "set noarg");
lives_ok { $config->setCustomHostname("foo") } "set value";
no_leaks_ok { $config->setCustomHostname("foo") } "set value leak";

is($config->getCustomHostname(), "foo", "get value");
no_leaks_ok { $config->getCustomHostname() } "get value leak";

lives_ok { $config->setCustomHostname(undef) } "reset value";
no_leaks_ok { $config->setCustomHostname(undef) } "reset value leak";
is($config->getCustomHostname(), undef, "get reset");
no_leaks_ok { $config->getCustomHostname() } "get reset leak";
