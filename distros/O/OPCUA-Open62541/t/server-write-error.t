use strict;
use warnings;
use OPCUA::Open62541 ':all';

use OPCUA::Open62541::Test::Server;

use Test::More tests => OPCUA::Open62541::Test::Server::planning() + 14;
use Test::Exception;
use Test::LeakTrace;
use Test::NoWarnings;
use Test::Warn;

my $server = OPCUA::Open62541::Test::Server->new();
$server->start();

my %requestedNewNodeId = (
    NodeId_namespaceIndex       => 1,
    NodeId_identifierType       => NODEIDTYPE_STRING,
    NodeId_identifier           => "the.answer",
);
my %parentNodeId = (
    NodeId_namespaceIndex       => 0,
    NodeId_identifierType       => NODEIDTYPE_NUMERIC,
    NodeId_identifier           => NS0ID_OBJECTSFOLDER,
);
my %referenceTypeId = (
    NodeId_namespaceIndex       => 0,
    NodeId_identifierType       => NODEIDTYPE_NUMERIC,
    NodeId_identifier           => NS0ID_ORGANIZES,
);
my %browseName = (
    QualifiedName_namespaceIndex        => 1,
    QualifiedName_name                  => "the answer",
);

my %typeDefinition = (
    NodeId_namespaceIndex       => 0,
    NodeId_identifierType       => NODEIDTYPE_NUMERIC,
    NodeId_identifier           => NS0ID_BASEDATAVARIABLETYPE,
);

my %attr = (
    VariableAttributes_displayName      => {
        LocalizedText_text              => "the answer",
    },
    VariableAttributes_description      => {
        LocalizedText_text              => "the answer",
    },
    VariableAttributes_value            => {
        Variant_type                    => TYPES_FLOAT,
        Variant_scalar                  => 4.2,
    },
    VariableAttributes_valueRank        => VALUERANK_SCALAR,
    VariableAttributes_dataType         => TYPES_FLOAT,
    VariableAttributes_accessLevel      =>
        ACCESSLEVELMASK_READ | ACCESSLEVELMASK_WRITE,
);
is($server->{server}->addVariableNode(\%requestedNewNodeId, \%parentNodeId,
    \%referenceTypeId, \%browseName, \%typeDefinition, \%attr, 0, undef),
    STATUSCODE_GOOD, "server add variable node");

$server->run();

$attr{VariableAttributes_value}{Variant_scalar} = 23.;

is($server->{server}->writeValue(\%requestedNewNodeId,
    $attr{VariableAttributes_value}),
    STATUSCODE_GOOD, "server write value");

no_leaks_ok {
    $server->{server}->writeValue(\%requestedNewNodeId,
    $attr{VariableAttributes_value})
} "server write value leak";

$attr{VariableAttributes_value}{Variant_scalar} = 1e+39;

throws_ok {
    $server->{server}->writeValue(\%requestedNewNodeId,
    $attr{VariableAttributes_value})
} qr/\QFloat value 1.000000e+39 greater than 3.402823e+38/,
    "server error value";

no_leaks_ok { eval {
    $server->{server}->writeValue(\%requestedNewNodeId,
    $attr{VariableAttributes_value})
} } "server error value leak";


$attr{VariableAttributes_value}{Variant_scalar} = 23.;
my $out;
is($server->{server}->readValue(\%requestedNewNodeId, \$out),
    STATUSCODE_GOOD, "server read value");
is_deeply($out, $attr{VariableAttributes_value}, "value");

$attr{VariableAttributes_value}{Variant_scalar} = 42.;
my %dataValue = (
    DataValue_hasValue => 1,
    DataValue_value => $attr{VariableAttributes_value},
);
my %writeValue = (
    WriteValue_nodeId		=> \%requestedNewNodeId,
    WriteValue_attributeId	=> ATTRIBUTEID_VALUE,
    WriteValue_value		=> \%dataValue,
);
is ($server->{server}->write(\%writeValue), STATUSCODE_GOOD, "server write");

no_leaks_ok { eval {
    $server->{server}->write(\%writeValue,
    $attr{VariableAttributes_value})
} } "server write leak";

$attr{VariableAttributes_value}{Variant_scalar} = 1e+39;

throws_ok { $server->{server}->write(\%writeValue) }
    qr/\QFloat value 1.000000e+39 greater than 3.402823e+38/,
    "server error write";

no_leaks_ok { eval { $server->{server}->write(\%writeValue) } }
    "server error write leak";

$attr{VariableAttributes_value}{Variant_scalar} = 42.;
my %readValueId = (
    ReadValueId_nodeId => \%requestedNewNodeId,
    ReadValueId_attributeId => ATTRIBUTEID_VALUE,
);
$out = $server->{server}->read(\%readValueId, 0);
is($out->{DataValue_status}, STATUSCODE_GOOD, "server read");
is_deeply($out->{DataValue_value}, $attr{VariableAttributes_value}, "read");

$server->stop();
