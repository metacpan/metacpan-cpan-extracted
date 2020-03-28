use strict;
use warnings;
use OPCUA::Open62541 'STATUSCODE_GOOD';

use OPCUA::Open62541::Test::Server;
use Test::More tests => OPCUA::Open62541::Test::Server::planning() + 12;
use Test::LeakTrace;
use Test::NoWarnings;

my $server = OPCUA::Open62541::Test::Server->new();
$server->start();

is($server->{server}->run_startup(), STATUSCODE_GOOD, "startup");

cmp_ok($server->{server}->run_iterate(0), '>', 0, "iterate");
foreach (1..10) {
    is($server->{server}->run_iterate(1), 0, "iterate $_");
}
ok($server->{log}->loggrep(qr/TCP network layer listening on /),
    "sever loggrep listening");

is($server->{server}->run_shutdown(), STATUSCODE_GOOD, "shutdown");

no_leaks_ok { $server->{server}->run_startup() } "startup leak";
no_leaks_ok { $server->{server}->run_iterate(0) } "iterate leak";
no_leaks_ok { $server->{server}->run_shutdown() } "shutdown leak";
