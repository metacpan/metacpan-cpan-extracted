use strict;
use warnings;
use OPCUA::Open62541;

use Test::More;
BEGIN {
    if (OPCUA::Open62541::ClientConfig->can('setApplicationUri')) {
	plan tests => 14;
    } elsif (not $^C) {
	plan skip_all => 'open62541 has no client config applicationUri';
    }
}
use Test::Exception;
use Test::LeakTrace;
use Test::NoWarnings;

ok(my $client = OPCUA::Open62541::Client->new(), "client new");
ok(my $config = $client->getConfig(), "config get");

is($config->getApplicationUri(), undef, "get unset");
no_leaks_ok { $config->getApplicationUri() } "get unset leak";

throws_ok { $config->setApplicationUri() } (qr/Usage:/, "set noarg");
lives_ok { $config->setApplicationUri("foo") } "set value";
no_leaks_ok { $config->setApplicationUri("foo") } "set value leak";

is($config->getApplicationUri(), "foo", "get value");
no_leaks_ok { $config->getApplicationUri() } "get value leak";

lives_ok { $config->setApplicationUri(undef) } "reset value";
no_leaks_ok { $config->setApplicationUri(undef) } "reset value leak";
is($config->getApplicationUri(), undef, "get reset");
no_leaks_ok { $config->getApplicationUri() } "get reset leak";
