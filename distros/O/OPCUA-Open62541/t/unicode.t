use strict;
use warnings;
use Encode qw(encode_utf8 encode decode);
use OPCUA::Open62541 ':all';

use OPCUA::Open62541::Test::Server;
use Test::More tests => OPCUA::Open62541::Test::Server::planning_nofork() + 29;
use Test::Exception;
use Test::NoWarnings;
use Test::Requires 'YAML::Tiny';

use feature 'unicode_strings';

my $auml_string = "\N{U+00E4}";
my $smiley_string = "\N{U+263A}";
my $string = "$auml_string $smiley_string \x00 \xff";
note "string ", encode_utf8("$auml_string $smiley_string");
like($string, qr/^\w \W . .$/, "string match");

my $auml_octets = "\xc3\xa4";
my $smiley_octets = "\xe2\x98\xba";
my $octets = "$auml_octets $smiley_octets \x00 \xff";
note "octets ", "$auml_octets $smiley_octets";
like($octets, qr/^.. ... . .$/, "octets match");

my $server = OPCUA::Open62541::Test::Server->new();
$server->start();

# Write unicode and string and byte string into server.

my %requestedNewNodeId = (
    NodeId_namespaceIndex	=> 1,
    NodeId_identifierType	=> NODEIDTYPE_STRING,
    NodeId_identifier		=> "string $string unicode",
);
my %parentNodeId = (
    NodeId_namespaceIndex	=> 0,
    NodeId_identifierType	=> NODEIDTYPE_NUMERIC,
    NodeId_identifier		=> NS0ID_OBJECTSFOLDER,
);
my %referenceTypeId = (
    NodeId_namespaceIndex	=> 0,
    NodeId_identifierType	=> NODEIDTYPE_NUMERIC,
    NodeId_identifier		=> NS0ID_ORGANIZES,
);
my %browseName = (
    QualifiedName_namespaceIndex	=> 1,
    QualifiedName_name			=> "the answer",
);
my %typeDefinition = (
    NodeId_namespaceIndex	=> 0,
    NodeId_identifierType	=> NODEIDTYPE_NUMERIC,
    NodeId_identifier		=> NS0ID_BASEDATAVARIABLETYPE,
);
my %attr = (
    VariableAttributes_displayName	=> {
	LocalizedText_text		=> "unicode",
    },
    VariableAttributes_description	=> {
	LocalizedText_text		=> "unicode",
    },
    VariableAttributes_value		=> {
	Variant_type			=> TYPES_BYTESTRING,
	Variant_scalar			=> "bytestring $octets unicode",
    },
    VariableAttributes_dataType		=> TYPES_BYTESTRING,
    VariableAttributes_accessLevel	=>
	ACCESSLEVELMASK_READ | ACCESSLEVELMASK_WRITE,
);

is($server->{server}->addVariableNode(\%requestedNewNodeId, \%parentNodeId,
    \%referenceTypeId, \%browseName, \%typeDefinition, \%attr, 0,
    undef), STATUSCODE_GOOD, "add variable node");

# Receive unicode string from server.

my $browse_result = $server->{server}->browse(
    0,
    {
	BrowseDescription_nodeId => {
	    NodeId_namespaceIndex	=> 0,
	    NodeId_identifierType	=> NODEIDTYPE_NUMERIC,
	    NodeId_identifier		=> NS0ID_OBJECTSFOLDER,
	},
	BrowseDescription_resultMask	=> BROWSERESULTMASK_ALL,
    },
);
is($browse_result->{BrowseResult_statusCode}, STATUSCODE_GOOD, "server browse");

my @nodeids =
    map { $_->{ReferenceDescription_nodeId}{ExpandedNodeId_nodeId} }
    grep { $_->{ReferenceDescription_browseName}{QualifiedName_name} eq
    "the answer" } @{$browse_result->{BrowseResult_references}};
is(@nodeids, 1, "nodeid grep") or diag explain $browse_result;

ok(my $identifier = $nodeids[0]{NodeId_identifier}, "nodeid identifier")
    or diag explain \@nodeids;
note encode_utf8($identifier);
is($identifier, "string $string unicode", "nodeid eq");
like($identifier, qr/^string \w \W . . unicode$/, "nodeid match");

# Receive byte string from server.

my $variant;
is($server->{server}->readValue($nodeids[0], \$variant),
    STATUSCODE_GOOD, "server read value");

ok(my $value = $variant->{Variant_scalar}, "value")
    or diag explain $variant;
note $value;
is($value, "bytestring $octets unicode", "value eq");
unlike($value, qr/^string \w \W . . unicode$/, "value match");

# use syswrite to check that wide charaters are preserved

ok(open(my $fh, '>', "unicode.utf8"), "open utf8")
    or diag "open 'unicode.utf8' failed: $!";

throws_ok { syswrite($fh, "string: $string\n") }
    (qr/Wide character in syswrite /, "write string");
throws_ok { syswrite($fh, "identifier: $identifier\n") }
    (qr/Wide character in syswrite /, "write identifier");
ok(syswrite($fh, "octets: $octets\n"), "write octets");
ok(syswrite($fh, "value: $value\n"), "write value");

ok(close($fh), "close utf8")
    or diag "close 'unicode.utf8' failed: $!";

# Put both in a single yaml document

ok(open($fh, '>', "unicode.yaml"), "open yaml")
    or diag "open 'unicode.yaml' failed: $!";

ok(my $yaml = YAML::Tiny->new({
    string => $string,
    octets => $octets,
    noteId => $nodeids[0],
    variant => $variant,
}), "yaml new");
ok(my $unicode = $yaml->write_string(), "yaml write");
throws_ok { syswrite($fh, $unicode) }
    (qr/Wide character in syswrite /, "write unicode");

my $utf8;
lives_ok {
    $utf8 = encode('UTF-8', $unicode, Encode::FB_CROAK);
} "encode";
ok(syswrite($fh, $utf8), "write utf8");

ok(my $yaml_string = YAML::Tiny->new({ noteId => $nodeids[0], }),
    "yaml string new");
throws_ok { syswrite($fh, $yaml_string->write_string()) }
    (qr/Wide character in syswrite /, "write string unicode");

ok(my $yaml_octets = YAML::Tiny->new({
    octets => $octets,
    variant => $variant,
}), "yaml string new");
lives_ok { syswrite($fh, $yaml_octets->write_string()) }
    "write octet unicode";

ok(close($fh), "close yaml")
    or diag "close 'unicode.yaml' failed: $!";
