use strict;
use warnings;
use OPCUA::Open62541 ':all';

use OPCUA::Open62541::Test::Server;
use Test::More tests => OPCUA::Open62541::Test::Server::planning_nofork() + 6;
use Test::Deep;
use Test::LeakTrace;
use Test::NoWarnings;

my $server = OPCUA::Open62541::Test::Server->new();
$server->start();

is($server->{server}->run_startup(), STATUSCODE_GOOD, "startup");
cmp_ok($server->{server}->run_iterate(0), '>', 0, "iterate");

my %readValueId_datatype = (
    ReadValueId_nodeId => {
	NodeId_identifier => NS0ID_SERVER_SERVERSTATUS_CURRENTTIME,
	NodeId_identifierType => 0,
	NodeId_namespaceIndex => 0,
    },
    ReadValueId_attributeId => ATTRIBUTEID_DATATYPE,
);

my %dataValue_datatype = (
    DataValue_hasServerPicoseconds => '',
    DataValue_hasServerTimestamp => '',
    DataValue_hasSourcePicoseconds => '',
    DataValue_hasSourceTimestamp => '',
    DataValue_hasStatus => '',
    DataValue_hasValue => 1,
    DataValue_serverPicoseconds => 0,
    DataValue_serverTimestamp => 0,
    DataValue_sourcePicoseconds => 0,
    DataValue_sourceTimestamp => 0,
    DataValue_status => 'Good',
    DataValue_value => {
	Variant_scalar => {
	    NodeId_identifier => NS0ID_UTCTIME,
	    NodeId_identifierType => 0,
	    NodeId_namespaceIndex => 0,
	    NodeId_print => "i=".NS0ID_UTCTIME,
	},
	Variant_type => TYPES_NODEID,
    },
);

my $out = $server->{server}->read(\%readValueId_datatype, 0);
cmp_deeply($out, \%dataValue_datatype, "dataValue datatype");

no_leaks_ok {
    my $out = $server->{server}->read(\%readValueId_datatype, 0);
} "read leak";

my %readValueId_value = (
    ReadValueId_nodeId => {
	NodeId_identifier => NS0ID_SERVER_SERVERSTATUS_CURRENTTIME,
	NodeId_identifierType => 0,
	NodeId_namespaceIndex => 0,
    },
    ReadValueId_attributeId => ATTRIBUTEID_VALUE,
);

my %dataValue_value = (
    DataValue_hasServerPicoseconds => '',
    DataValue_hasServerTimestamp => 1,
    DataValue_hasSourcePicoseconds => '',
    DataValue_hasSourceTimestamp => 1,
    DataValue_hasStatus => '',
    DataValue_hasValue => 1,
    DataValue_serverPicoseconds => 0,
    DataValue_serverTimestamp => re(qr/^\d+$/),
    DataValue_sourcePicoseconds => 0,
    DataValue_sourceTimestamp => re(qr/^\d+$/),
    DataValue_status => 'Good',
    DataValue_value => {
	Variant_scalar => re(qr/^\d+$/),
	Variant_type => TYPES_DATETIME,
    },
);

$out = $server->{server}->read(\%readValueId_value, 2);
cmp_deeply($out, \%dataValue_value, "dataValue value");

no_leaks_ok {
    my $out = $server->{server}->read(\%readValueId_value, 2);
} "read leak";
