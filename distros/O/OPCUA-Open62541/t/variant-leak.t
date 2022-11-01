use strict;
use warnings;
use OPCUA::Open62541 qw(:TYPES :NODEIDTYPE);

use Test::More tests => 20;
use Test::Exception;
use Test::LeakTrace;
use Test::NoWarnings;
use Test::Warn;

ok(my $variant = OPCUA::Open62541::Variant->new(), "variant new");

my %nodeid = (
    NodeId_namespaceIndex       => 1,
    NodeId_identifierType       => NODEIDTYPE_STRING,
    NodeId_identifier           => "SOME_VARIABLE_TYPE",
);

my %nodeid_badtype = %nodeid;
$nodeid_badtype{NodeId_identifierType} = 77;

### trigger leaks with croak in unpack

# scalar

lives_ok { $variant->setScalar(\%nodeid, TYPES_NODEID) }
    "scalar nodeid";
no_leaks_ok { $variant->setScalar(\%nodeid, TYPES_NODEID) }
    "scalar nodeid leak";

throws_ok { $variant->setScalar({}, TYPES_NODEID) }
    qr/UA_NodeId: No NodeId_namespaceIndex in HASH /,
    "scalar nodeid croak";
no_leaks_ok { eval { $variant->setScalar({}, TYPES_NODEID) } }
    "scalar nodeid croak leak";

# bad type

throws_ok { $variant->setScalar(\%nodeid_badtype, TYPES_NODEID) }
    qr/unpack_UA_NodeId: NodeId_identifierType 77 unknown /,
    "scalar badtype set";
no_leaks_ok { eval { $variant->setScalar(\%nodeid_badtype, TYPES_NODEID) } }
    "scalar badtype set leak";

throws_ok { $variant->getScalar() }
    qr/pack_UA_NodeId: NodeId_identifierType 77 unknown /,
    "scalar badtype get";
no_leaks_ok { eval { $variant->getScalar() } }
    "scalar badtype croak leak";

# array

lives_ok { $variant->setArray([\%nodeid, \%nodeid], TYPES_NODEID) }
    "array nodeid";
no_leaks_ok { $variant->setArray([\%nodeid, \%nodeid], TYPES_NODEID) }
    "array nodeid leak";

throws_ok { $variant->setArray([\%nodeid, {}], TYPES_NODEID) }
    qr/UA_NodeId: No NodeId_namespaceIndex in HASH /,
    "array nodeid croak";
no_leaks_ok { eval { $variant->setArray([\%nodeid, {}], TYPES_NODEID) } }
    "array nodeid croak leak";

lives_ok { $variant->getArray() }
    "array nodeid get";
no_leaks_ok { $variant->getArray() }
    "array nodeid get leak";

throws_ok {
    $variant->setArray([\%nodeid, \%nodeid_badtype], TYPES_NODEID);
} qr/unpack_UA_NodeId: NodeId_identifierType 77 unknown /,
    "array badtype set";
no_leaks_ok { eval {
    $variant->setArray([\%nodeid, \%nodeid_badtype], TYPES_NODEID);
} } "array badtype set leak";

throws_ok { $variant->getArray() }
    qr/pack_UA_NodeId: NodeId_identifierType 77 unknown /,
    "array badtype get";
no_leaks_ok { eval { $variant->getArray() } }
    "array badtype croak leak";
