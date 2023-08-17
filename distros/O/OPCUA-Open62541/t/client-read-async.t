use strict;
use warnings;
use OPCUA::Open62541 qw(:ATTRIBUTEID :NODECLASS :STATUSCODE :TYPES);

use OPCUA::Open62541::Test::Server;
use OPCUA::Open62541::Test::Client;
use Test::More tests =>
    OPCUA::Open62541::Test::Server::planning() +
    OPCUA::Open62541::Test::Client::planning() + 55;
use Test::Deep;
use Test::Exception;
use Test::NoWarnings;
use Test::LeakTrace;

my $server = OPCUA::Open62541::Test::Server->new();
$server->start();

my %nodes = $server->setup_complex_objects();
my $object_node = $nodes{some_object_0}{nodeId};
my $object_attr = {};
for my $key (keys %{$nodes{some_object_0}{attributes}}) {
    my $stripped = $key;
    $stripped =~ s/^ObjectAttributes_//;
    $object_attr->{$stripped} = $nodes{some_object_0}{attributes}{$key};
}
my $variable_node = $nodes{some_variable_0}{nodeId};

# make the value for some_variable_0 not readable for error testing
is($server->{server}->writeAccessLevel($variable_node, 0),
   STATUSCODE_GOOD, "writeAccessLevel");

$server->run();

my $client = OPCUA::Open62541::Test::Client->new(port => $server->port());
$client->start();
$client->run();

my $request = {
    ReadRequest_nodesToRead => []
};

my $response = {
    'ReadResponse_diagnosticInfos' => [],
    'ReadResponse_results' => [],
    'ReadResponse_responseHeader' => {
	'ResponseHeader_stringTable' => [],
	'ResponseHeader_timestamp' => re(qr/^\d+$/), # '132282586240806600',
	'ResponseHeader_requestHandle' => re(qr/^\d+$/), # 5,
	'ResponseHeader_serviceDiagnostics' => {
	    'DiagnosticInfo_hasSymbolicId' => '',
	    'DiagnosticInfo_locale' => 0,
	    'DiagnosticInfo_localizedText' => 0,
	    'DiagnosticInfo_additionalInfo' => undef,
	    'DiagnosticInfo_hasInnerStatusCode' => '',
	    'DiagnosticInfo_namespaceUri' => 0,
	    'DiagnosticInfo_hasAdditionalInfo' => '',
	    'DiagnosticInfo_hasNamespaceUri' => '',
	    'DiagnosticInfo_hasLocalizedText' => '',
	    'DiagnosticInfo_hasLocale' => '',
	    'DiagnosticInfo_innerStatusCode' => 'Good',
	    'DiagnosticInfo_hasInnerDiagnosticInfo' => '',
	    'DiagnosticInfo_symbolicId' => 0
	},
	'ResponseHeader_serviceResult' => 'Good',
	'ResponseHeader_additionalHeader' => {
	    'ExtensionObject_content' => {
	      'ExtensionObject_content_typeId' => {
		'NodeId_identifier' => 0,
		'NodeId_identifierType' => 0,
		'NodeId_namespaceIndex' => 0,
		'NodeId_print' => "i=0",
	      },
	      'ExtensionObject_content_body' => undef,
	    },
	    'ExtensionObject_encoding' => 0
	}
    }
};

for my $r (
    {
	node => $object_node,
	attribute => ATTRIBUTEID_NODEID,
	value => {
	    Variant_scalar=> $object_node,
	    Variant_type => TYPES_NODEID,
	},
    }, {
	node => $object_node,
	attribute => ATTRIBUTEID_NODECLASS,
	value => {
	    Variant_scalar => NODECLASS_OBJECT,
	    Variant_type => TYPES_INT32,
	},
    },  {
	node => $object_node,
	attribute => ATTRIBUTEID_BROWSENAME,
	value => {
	    Variant_scalar => $nodes{some_object_0}{browseName},
	    Variant_type => TYPES_QUALIFIEDNAME,
	},
    },  {
	node => $object_node,
	attribute => ATTRIBUTEID_DISPLAYNAME,
	value => {
	    Variant_scalar => $object_attr->{displayName},
	    Variant_type => TYPES_LOCALIZEDTEXT,
	},
    }, {
	node => $object_node,
	attribute => ATTRIBUTEID_DESCRIPTION,
	value => {
	    Variant_scalar => $object_attr->{description},
	    Variant_type => TYPES_LOCALIZEDTEXT,
	},
    }, {
	node => $variable_node,
	attribute => ATTRIBUTEID_NODEID,
	value => {
	    Variant_scalar => $variable_node,
	    Variant_type => TYPES_NODEID,
	},
    }, {
	node => $object_node,
	attribute => ATTRIBUTEID_CONTAINSNOLOOPS,
	value => {},
	DataValue => {
	    DataValue_hasStatus => 1,
	    DataValue_status => 'BadAttributeIdInvalid',
	    DataValue_hasValue => '',
	},
    }, {
	node => $variable_node,
	attribute => ATTRIBUTEID_VALUE,
	value => {},
	DataValue => {
	    DataValue_hasStatus => 1,
	    DataValue_status => 'BadNotReadable',
	    DataValue_hasValue => '',
	},
    }
) {
    my $nodestoread = {
	ReadValueId_nodeId => $r->{node},
	ReadValueId_attributeId => $r->{attribute},
    };
    my $result = {
	DataValue_sourceTimestamp => re(qr/^\d+$/),
	DataValue_serverTimestamp => re(qr/^\d+$/),
	DataValue_sourcePicoseconds => 0,
	DataValue_serverPicoseconds => 0,
	DataValue_status => 'Good',
	DataValue_hasValue => 1,
	DataValue_hasStatus => '',
	DataValue_hasSourceTimestamp =>
	    ($r->{attribute} == ATTRIBUTEID_VALUE ? re(qr/^(1|)$/) : ''),
	DataValue_hasServerTimestamp => '',
	DataValue_hasSourcePicoseconds => '',
	DataValue_hasServerPicoseconds => '',
	DataValue_value => $r->{value},
	$r->{DataValue} ? (%{$r->{DataValue}}) : (),
    };

    push(@{$request->{ReadRequest_nodesToRead}}, $nodestoread);
    push(@{$response->{ReadResponse_results}}, $result);
}

### deep

my $data = "foo",
my $reqid;
my $read = 0;
is($client->{client}->sendAsyncReadRequest(
    $request,
    sub {
	my ($c, $d, $i, $r) = @_;

	is($c, $client->{client}, "client");
	is($$d, "foo", "data in");
	$$d = "bar";
	is($i, $reqid, "reqid");
	cmp_deeply($r, $response, "response");

	$read = 1;
    },
    \$data,
    \$reqid,
), STATUSCODE_GOOD, "sendAsyncReadRequest");
is($data, "foo", "data unchanged");
like($reqid, qr/^\d+$/, "reqid number");
$client->iterate(\$read, "read deep");
is($data, 'bar', "data out");

no_leaks_ok {
    $read = 0;
    $client->{client}->sendAsyncReadRequest(
	$request,
	sub {
	    my ($c, $d, $i, $r) = @_;
	    $read = 1;
	},
	$data,
	\$reqid,
    );
    $client->iterate(\$read);
} "sendAsyncReadRequest leak";

### data reqid undef

$read = 0;
is($client->{client}->sendAsyncReadRequest(
    $request,
    sub {
	my ($c, $d, $i, $r) = @_;

	is($d, undef, "data undef");
	like($reqid, qr/^\d+$/, "reqid number");

	$read = 1;
    },
    undef,
    undef,
), STATUSCODE_GOOD, "sendAsyncReadRequest undef");
$client->iterate(\$read, "read undef");

no_leaks_ok {
    $read = 0;
    $client->{client}->sendAsyncReadRequest(
	$request,
	sub {
	    my ($c, $d, $i, $r) = @_;
	    $read = 1;
	},
	undef,
	undef,
    );
    $client->iterate(\$read);
} "sendAsyncReadRequest undef leak";

### reqid bad ref

throws_ok {
    $client->{client}->sendAsyncReadRequest(
	$request,
	sub {
	    my ($c, $d, $i, $r) = @_;
	},
	undef,
	[],
    );
} (qr/Output parameter outoptReqId is not a scalar reference /,
    "sendAsyncReadRequest ref reqid");

no_leaks_ok { eval {
    $client->{client}->sendAsyncReadRequest(
	$request,
	sub {
	    my ($c, $d, $i, $r) = @_;
	},
	undef,
	[],
    );
} } "sendAsyncReadRequest ref reqid leak";

### client undef

throws_ok {
    OPCUA::Open62541::Client::sendAsyncReadRequest(
	undef,
	$request,
	sub {
	    my ($c, $d, $i, $r) = @_;
	},
	undef,
	undef,
    );
} (qr/Self client is not a OPCUA::Open62541::Client /,
    "sendAsyncReadRequest undef client");

no_leaks_ok { eval {
    OPCUA::Open62541::Client::sendAsyncReadRequest(
	undef,
	$request,
	sub {
	    my ($c, $d, $i, $r) = @_;
	},
	undef,
	undef,
    );
} } "sendAsyncReadRequest undef client leak";

### request undef

throws_ok {
    $client->{client}->sendAsyncReadRequest(
	undef,
	sub {
	    my ($c, $d, $i, $r) = @_;
	},
	undef,
	undef,
    );
} (qr/Parameter request is undefined /,
    "sendAsyncReadRequest undef request");

no_leaks_ok { eval {
    $client->{client}->sendAsyncReadRequest(
	undef,
	sub {
	    my ($c, $d, $i, $r) = @_;
	},
	undef,
	undef,
    );
} } "sendAsyncReadRequest undef request leak";

### callback undef

throws_ok {
    $client->{client}->sendAsyncReadRequest(
	$request,
	"foobar",
	undef,
	undef,
    );
} (qr/Callback 'foobar' is not a CODE reference /,
    "sendAsyncReadRequest bad callback");

no_leaks_ok { eval {
    $client->{client}->sendAsyncReadRequest(
	$request,
	"foobar",
	undef,
	undef,
    );
} } "sendAsyncReadRequest bad callback leak";

### multiple requests
# Call sendAsyncReadRequest() multiple times.  Check that request
# id is unique.  Check that all request id are uses in callback.

my %reqid2seq;
foreach my $seq (1..5) {
    my $reqid;
    is($client->{client}->sendAsyncReadRequest(
	$request,
	sub {
	    my ($c, $d, $i, $r) = @_;

	    note "multiple reqid $i";
	    is($d->[0]{$i}, $d->[1], "multiple reqid seqence");
	    ok(delete $d->[0]{$i}, "multiple reqid exists");
	},
	[ \%reqid2seq, $seq ],
	\$reqid,
    ), STATUSCODE_GOOD, "sendAsyncReadRequest multiple reqid");
    is($reqid2seq{$reqid}, undef, "multiple reqid unique");
    $reqid2seq{$reqid} = $seq;
}
$client->iterate(\%reqid2seq, "multiple reqid");

no_leaks_ok { eval {
    foreach my $seq (1..5) {
	my $reqid;
	$client->{client}->sendAsyncReadRequest(
	    $request,
	    sub {
		my ($c, $d, $i, $r) = @_;
		delete $d->{$i};
	    },
	    \%reqid2seq,
	    \$reqid,
	);
	$reqid2seq{$reqid} = $seq;
    }
    # For unknown reasons this note command makes a potential leak
    # go away.  no_leaks_ok() does not work well with hashes.
    note "keys before iterate: ", scalar keys %reqid2seq;
    $client->iterate(\%reqid2seq);
    note "keys after iterate: ", scalar keys %reqid2seq;
} } "sendAsyncReadRequest multiple reqid leak";

$client->stop();

### status fail

# read with closed client fails, check that it does not leak
$data = "foo";
undef $reqid;
is($client->{client}->sendAsyncReadRequest(
    $request,
    sub {
	my ($c, $d, $i, $r) = @_;
	fail "callback called";
    },
    \$data,
    \$reqid,
), STATUSCODE_BADSERVERNOTCONNECTED, "sendAsyncReadRequest fail");
is($data, "foo", "data fail");
is($reqid, 0, "reqid zero");

no_leaks_ok {
    $client->{client}->sendAsyncReadRequest(
	$request,
	sub {
	    my ($c, $d, $i, $r) = @_;
	},
	\$data,
	\$reqid,
    );
} "sendAsyncReadRequest fail leak";

$server->stop();
