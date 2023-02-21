use strict;
use warnings;
use OPCUA::Open62541 ':all';

use OPCUA::Open62541::Test::Server;
use OPCUA::Open62541::Test::Client;
use Test::More tests =>
    OPCUA::Open62541::Test::Server::planning() +
    OPCUA::Open62541::Test::Client::planning() + 13;
use Test::LeakTrace;
use Test::NoWarnings;

my $server = OPCUA::Open62541::Test::Server->new();
$server->start();
my $client = OPCUA::Open62541::Test::Client->new(port => $server->port());
$client->start();

my %nodes = $server->setup_complex_objects();
my %nodeid = %{$nodes{some_variable_0}{nodeId}};
my $outvalue;

undef $outvalue;
is($server->{server}->readDataType(\%nodeid, \$outvalue),
    STATUSCODE_GOOD,
    "server readDataType");
is_deeply($outvalue, TYPES_INT32,
    "server readDataType deeply");
is($server->{server}->writeDataType(\%nodeid, TYPES_UINT32),
    STATUSCODE_BADTYPEMISMATCH,
    "server writeDataType");

$server->run();
$client->run();

undef $outvalue;
is($client->{client}->readDataTypeAttribute(\%nodeid, \$outvalue),
    STATUSCODE_GOOD,
    "client readDataType");
is_deeply($outvalue, TYPES_INT32,
    "client readDataType deeply");
is($client->{client}->writeDataTypeAttribute(\%nodeid, TYPES_UINT32),
    STATUSCODE_BADUSERACCESSDENIED,
    "client writeDataType");
undef $outvalue;
is($client->{client}->readDataTypeAttribute_async(\%nodeid,
    sub { ${$_[1]} = $_[3] }, \$outvalue, undef),
    STATUSCODE_GOOD,
    "client readDataType async");
$client->iterate(\$outvalue);
is_deeply($outvalue, TYPES_INT32,
    "client readDataType async deeply");

$client->stop();
$server->stop();
