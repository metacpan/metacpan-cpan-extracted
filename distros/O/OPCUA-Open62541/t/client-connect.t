use strict;
use warnings;
use OPCUA::Open62541 ':all';
use POSIX qw(sigaction SIGALRM);

use OPCUA::Open62541::Test::Server;
use Test::More tests => 16;
use Test::NoWarnings;
use Test::Warn;

my $server = OPCUA::Open62541::Test::Server->new();
$server->start();
my $port = $server->port();

my $c = OPCUA::Open62541::Client->new();
ok($c, "client");

my $cc = $c->getConfig();
ok($c, "config client");

my $r = $cc->setDefault();
is($r, STATUSCODE_GOOD, "default client config");

$r = $c->connect("opc.tcp://localhost:$port");
is($r, STATUSCODE_GOOD, "client connected");

is($c->getState, CLIENTSTATE_SESSION, "client state connected");

$r = $c->disconnect();
is($r, STATUSCODE_GOOD, "client disconnected");

is($c->getState, CLIENTSTATE_DISCONNECTED, "client state disconnected");

$server->stop();
