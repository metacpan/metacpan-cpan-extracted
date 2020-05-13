use strict;
use warnings;
use OPCUA::Open62541 qw(BROWSERESULTMASK_ALL :STATUSCODE);

use OPCUA::Open62541::Test::Server;
use OPCUA::Open62541::Test::Client;
use Test::More tests =>
    OPCUA::Open62541::Test::Server::planning() +
    OPCUA::Open62541::Test::Client::planning() + 61;
use Test::Deep;
use Test::Exception;
use Test::NoWarnings;
use Test::LeakTrace;

my $server = OPCUA::Open62541::Test::Server->new();
$server->start();
my $client = OPCUA::Open62541::Test::Client->new(port => $server->port());
$client->start();
$server->run();
$client->run();

my $request_browse = {
    BrowseRequest_requestedMaxReferencesPerNode => 1,
    BrowseRequest_nodesToBrowse => [
	{
	    BrowseDescription_nodeId => {
		NodeId_namespaceIndex => 0,
		NodeId_identifierType => 0,
		NodeId_identifier => OPCUA::Open62541::NS0ID_ROOTFOLDER,
	    },
	    BrowseDescription_resultMask => BROWSERESULTMASK_ALL,
	}
    ],
};

my $responses = [{
  'BrowseResponse_diagnosticInfos' => [],
  'BrowseResponse_results' => [
    {
      'BrowseResult_references' => [
	{
	  'ReferenceDescription_nodeId' => {
	    'ExpandedNodeId_serverIndex' => 0,
	    'ExpandedNodeId_nodeId' => {
	      'NodeId_identifier' => 61,
	      'NodeId_identifierType' => 0,
	      'NodeId_namespaceIndex' => 0
	    },
	    'ExpandedNodeId_namespaceUri' => undef
	  },
	  'ReferenceDescription_isForward' => 1,
	  'ReferenceDescription_displayName' => {
	    'LocalizedText_text' => 'FolderType',
	    'LocalizedText_locale' => ''
	  },
	  'ReferenceDescription_nodeClass' => 8,
	  'ReferenceDescription_referenceTypeId' => {
	    'NodeId_identifier' => 40,
	    'NodeId_identifierType' => 0,
	    'NodeId_namespaceIndex' => 0
	  },
	  'ReferenceDescription_typeDefinition' => {
	    'ExpandedNodeId_nodeId' => {
	      'NodeId_identifierType' => 0,
	      'NodeId_identifier' => 0,
	      'NodeId_namespaceIndex' => 0
	    },
	    'ExpandedNodeId_namespaceUri' => undef,
	    'ExpandedNodeId_serverIndex' => 0
	  },
	  'ReferenceDescription_browseName' => {
	    'QualifiedName_name' => 'FolderType',
	    'QualifiedName_namespaceIndex' => 0
	  }
	}
      ],
      'BrowseResult_continuationPoint' => re(qr/.*/), # random byte string
      'BrowseResult_statusCode' => 'Good'
    }
  ],
  'BrowseResponse_responseHeader' => {
    'ResponseHeader_stringTable' => [],
    'ResponseHeader_timestamp' => re(qr/^\d+$/),  # '132282586240806600',
    'ResponseHeader_requestHandle' => re(qr/^\d+$/),  # 5,
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
      'ExtensionObject_content_typeId' => {
	'NodeId_identifier' => 0,
	'NodeId_identifierType' => 0,
	'NodeId_namespaceIndex' => 0
      },
      'ExtensionObject_content_body' => undef,
      'ExtensionObject_encoding' => 0
    }
  }
}, {
  'BrowseNextResponse_diagnosticInfos' => [],
  'BrowseNextResponse_results' => [
    {
      'BrowseResult_references' => [
	{
	  'ReferenceDescription_referenceTypeId' => {
	    'NodeId_identifier' => 35,
	    'NodeId_identifierType' => 0,
	    'NodeId_namespaceIndex' => 0
	  },
	  'ReferenceDescription_typeDefinition' => {
	    'ExpandedNodeId_serverIndex' => 0,
	    'ExpandedNodeId_namespaceUri' => undef,
	    'ExpandedNodeId_nodeId' => {
	      'NodeId_identifier' => 61,
	      'NodeId_identifierType' => 0,
	      'NodeId_namespaceIndex' => 0
	    }
	  },
	  'ReferenceDescription_browseName' => {
	    'QualifiedName_name' => 'Objects',
	    'QualifiedName_namespaceIndex' => 0
	  },
	  'ReferenceDescription_nodeId' => {
	    'ExpandedNodeId_serverIndex' => 0,
	    'ExpandedNodeId_nodeId' => {
	      'NodeId_identifier' => 85,
	      'NodeId_identifierType' => 0,
	      'NodeId_namespaceIndex' => 0
	    },
	    'ExpandedNodeId_namespaceUri' => undef
	  },
	  'ReferenceDescription_isForward' => 1,
	  'ReferenceDescription_nodeClass' => 1,
	  'ReferenceDescription_displayName' => {
	    'LocalizedText_locale' => '',
	    'LocalizedText_text' => 'Objects'
	  }
	}
      ],
      'BrowseResult_continuationPoint' => re(qr/.*/),
      'BrowseResult_statusCode' => 'Good'
    }
  ],
  'BrowseNextResponse_responseHeader' => {
    'ResponseHeader_stringTable' => [],
    'ResponseHeader_timestamp' => re(qr/^\d+$/),  # '132282586240806600',
    'ResponseHeader_requestHandle' => re(qr/^\d+$/),  # 5,
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
      'ExtensionObject_content_typeId' => {
	'NodeId_identifier' => 0,
	'NodeId_identifierType' => 0,
	'NodeId_namespaceIndex' => 0
      },
      'ExtensionObject_content_body' => undef,
      'ExtensionObject_encoding' => 0
    }
  }
}];

### deep

my $data = "foo",
my $reqid;
my $browsed = 0;
my $cp;
is($client->{client}->sendAsyncBrowseRequest(
    $request_browse,
    sub {
	my ($c, $d, $i, $r) = @_;

	is($c, $client->{client}, "client");
	is($$d, "foo", "data in");
	$$d = "bar";
	is($i, $reqid, "reqid");
	cmp_deeply($r, $responses->[0], "response");

	$browsed = 1;
	($cp) = map { $_->{BrowseResult_continuationPoint} }
	    @{$r->{BrowseResponse_results}};
	ok(defined $cp, "continuationpoint set");
    },
    \$data,
    \$reqid,
), STATUSCODE_GOOD, "sendAsyncBrowseRequest");
is($data, "foo", "data unchanged");
like($reqid, qr/^\d+$/, "reqid number");
$client->iterate(\$browsed, "browse deep");
is($data, 'bar', "data out");

is($client->{client}->sendAsyncBrowseNextRequest(
    {BrowseNextRequest_continuationPoints => [$cp]},
    sub {
	my ($c, $d, $i, $r) = @_;

	is($c, $client->{client}, "client");
	is($$d, "bar", "data in");
	$$d = "test";
	is($i, $reqid, "reqid");
	cmp_deeply($r, $responses->[1], "response");

	$browsed = 1;
	($cp) = map { $_->{BrowseResult_continuationPoint} }
	    @{$r->{BrowseNextResponse_results}};
	ok(defined $cp, "continuationpoint set");
    },
    \$data,
    \$reqid,
), STATUSCODE_GOOD, "sendAsyncBrowseNextRequest");
is($data, "bar", "data unchanged");
like($reqid, qr/^\d+$/, "reqid number");
$client->iterate(\$browsed, "browse deep");
is($data, 'test', "data out");

my $request_browse_next = {
    BrowseNextRequest_continuationPoints => [$cp]
};

no_leaks_ok {
    $browsed = 0;
    $client->{client}->sendAsyncBrowseNextRequest(
    $request_browse_next,
	sub {
	    my ($c, $d, $i, $r) = @_;
	    $browsed = 1;
	},
	$data,
	\$reqid,
    );
    $client->iterate(\$browsed);
} "sendAsyncBrowseNextRequest leak";

### data reqid undef

$browsed = 0;
is($client->{client}->sendAsyncBrowseNextRequest(
    $request_browse_next,
    sub {
	my ($c, $d, $i, $r) = @_;

	is($d, undef, "data undef");
	like($reqid, qr/^\d+$/, "reqid number");

	$browsed = 1;
    },
    undef,
    undef,
), STATUSCODE_GOOD, "sendAsyncBrowseNextRequest undef");
$client->iterate(\$browsed, "browse undef");

no_leaks_ok {
    $browsed = 0;
    $client->{client}->sendAsyncBrowseNextRequest(
	$request_browse_next,
	sub {
	    my ($c, $d, $i, $r) = @_;
	    $browsed = 1;
	},
	undef,
	undef,
    );
    $client->iterate(\$browsed);
} "sendAsyncBrowseNextRequest undef leak";

### reqid bad ref

throws_ok {
    $client->{client}->sendAsyncBrowseNextRequest(
	$request_browse_next,
	sub {
	    my ($c, $d, $i, $r) = @_;
	},
	undef,
	[],
    );
} (qr/Output parameter outoptReqId is not a scalar reference /,
    "sendAsyncBrowseNextRequest ref reqid");

no_leaks_ok { eval {
    $client->{client}->sendAsyncBrowseNextRequest(
	$request_browse_next,
	sub {
	    my ($c, $d, $i, $r) = @_;
	},
	undef,
	[],
    );
} } "sendAsyncBrowseNextRequest ref reqid leak";

### client undef

throws_ok {
    OPCUA::Open62541::Client::sendAsyncBrowseNextRequest(
	undef,
	$request_browse_next,
	sub {
	    my ($c, $d, $i, $r) = @_;
	},
	undef,
	undef,
    );
} (qr/Self client is not a OPCUA::Open62541::Client /,
    "sendAsyncBrowseNextRequest undef client");

no_leaks_ok { eval {
    OPCUA::Open62541::Client::sendAsyncBrowseNextRequest(
	undef,
	$request_browse_next,
	sub {
	    my ($c, $d, $i, $r) = @_;
	},
	undef,
	undef,
    );
} } "sendAsyncBrowseNextRequest undef client leak";

### request undef

throws_ok {
    $client->{client}->sendAsyncBrowseNextRequest(
	undef,
	sub {
	    my ($c, $d, $i, $r) = @_;
	},
	undef,
	undef,
    );
} (qr/Parameter request is undefined /,
    "sendAsyncBrowseNextRequest undef request");

no_leaks_ok { eval {
    $client->{client}->sendAsyncBrowseNextRequest(
	undef,
	sub {
	    my ($c, $d, $i, $r) = @_;
	},
	undef,
	undef,
    );
} } "sendAsyncBrowseNextRequest undef request leak";

### callback undef

throws_ok {
    $client->{client}->sendAsyncBrowseNextRequest(
	$request_browse_next,
	"foobar",
	undef,
	undef,
    );
} (qr/Callback 'foobar' is not a CODE reference /,
    "sendAsyncBrowseNextRequest bad callback");

no_leaks_ok { eval {
    $client->{client}->sendAsyncBrowseNextRequest(
	$request_browse_next,
	"foobar",
	undef,
	undef,
    );
} } "sendAsyncBrowseNextRequest bad callback leak";

### multiple requests
# Call sendAsyncBrowseNextRequest() multiple times.  Check that request
# id is unique.  Check that all request id are uses in callback.

my %reqid2seq;
foreach my $seq (1..5) {
    my $reqid;
    is($client->{client}->sendAsyncBrowseNextRequest(
	$request_browse_next,
	sub {
	    my ($c, $d, $i, $r) = @_;

	    note "multiple reqid $i";
	    is($d->[0]{$i}, $d->[1], "multiple reqid seqence");
	    ok(delete $d->[0]{$i}, "multiple reqid exists");
	},
	[ \%reqid2seq, $seq ],
	\$reqid,
    ), STATUSCODE_GOOD, "sendAsyncBrowseNextRequest multiple reqid");
    is($reqid2seq{$reqid}, undef, "multiple reqid unique");
    $reqid2seq{$reqid} = $seq;
}
$client->iterate(\%reqid2seq, "multiple reqid");

no_leaks_ok { eval {
    foreach my $seq (1..5) {
	my $reqid;
	$client->{client}->sendAsyncBrowseNextRequest(
	    $request_browse_next,
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
} } "sendAsyncBrowseNextRequest multiple reqid leak";

$client->stop();

### status fail

# browse with closed client fails, check that it does not leak
$data = "foo";
undef $reqid;
is($client->{client}->sendAsyncBrowseNextRequest(
    $request_browse_next,
    sub {
	my ($c, $d, $i, $r) = @_;
	fail "callback called";
    },
    \$data,
    \$reqid,
), STATUSCODE_BADSERVERNOTCONNECTED, "sendAsyncBrowseNextRequest fail");
is($data, "foo", "data fail");
is($reqid, 0, "reqid zero");

no_leaks_ok {
    $client->{client}->sendAsyncBrowseNextRequest(
	$request_browse_next,
	sub {
	    my ($c, $d, $i, $r) = @_;
	},
	\$data,
	\$reqid,
    );
} "sendAsyncBrowseNextRequest fail leak";

$server->stop();
