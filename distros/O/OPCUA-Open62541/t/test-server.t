# test server listens
# check that test module works

use strict;
use warnings;

use OPCUA::Open62541::Test::Server;
use Test::More tests => OPCUA::Open62541::Test::Server::planning() + 1;
use Test::NoWarnings;

# Tests that OPCUA::Open62541::Test::Server works.  Start, run and
# stop an open62541 server.

my $server = OPCUA::Open62541::Test::Server->new();
$server->start();
$server->run();
$server->stop();
