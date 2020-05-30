use strict;
use warnings;
use OPCUA::Open62541 ':all';

use OPCUA::Open62541::Test::Server;
use OPCUA::Open62541::Test::Client;
use Test::More tests =>
    OPCUA::Open62541::Test::Server::planning() +
    OPCUA::Open62541::Test::Client::planning() + 14;
use Test::LeakTrace;
use Test::NoWarnings;

my $server = OPCUA::Open62541::Test::Server->new();
$server->start();
my $client = OPCUA::Open62541::Test::Client->new(port => $server->port());
$client->start();

my %nodes = $server->setup_complex_objects();
my %nodeid = %{$nodes{some_variable_0}{nodeId}};
my $outvalue;

# There is a bug in open62541 1.0.1 that crashes the client with a
# segmentation fault.  It happens when the request Id is omitted.
# The OpenBSD port has a patch that fixes the bug.
# https://github.com/open62541/open62541/commit/
#   b172ae033adb5dd2aa6766b9cd6af8fc8c91453c

my $skip_reqid;
ok(my $buildinfo = $server->{config}->getBuildInfo());
note explain $buildinfo;
if ($^O ne 'openbsd' && $buildinfo->{BuildInfo_softwareVersion} =~ /^1\.0\./) {
    $skip_reqid = "request id bug in ".
	"library '$buildinfo->{BuildInfo_manufacturerName}' ".
	"version '$buildinfo->{BuildInfo_softwareVersion}' ".
	"operating system '$^O'";
}

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
SKIP: {
    skip $skip_reqid, 2 if $skip_reqid;
is($client->{client}->readDataTypeAttribute_async(\%nodeid,
    sub { ${$_[1]} = $_[3] }, \$outvalue, undef),
    STATUSCODE_GOOD,
    "client readDataType async");
$client->iterate(\$outvalue);
is_deeply($outvalue, TYPES_INT32,
    "client readDataType async deeply");
}  # SKIP

$client->stop();
$server->stop();
