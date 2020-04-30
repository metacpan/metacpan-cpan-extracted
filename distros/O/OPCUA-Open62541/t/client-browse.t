use strict;
use warnings;
use OPCUA::Open62541 qw(:all);

use OPCUA::Open62541::Test::Server;
use OPCUA::Open62541::Test::Client;
use Test::More tests =>
    OPCUA::Open62541::Test::Server::planning() +
    OPCUA::Open62541::Test::Client::planning() + 7;
use Test::Deep;
use Test::NoWarnings;

my $server = OPCUA::Open62541::Test::Server->new();
$server->start();
my $client = OPCUA::Open62541::Test::Client->new(port => $server->port());
$client->start();
$server->run();
$client->run();

my %request = (
    BrowseRequest_requestedMaxReferencesPerNode => 0,
    BrowseRequest_nodesToBrowse => [
	{
	    BrowseDescription_nodeId => {
		NodeId_namespaceIndex => 0,
		NodeId_identifierType => 0,
		NodeId_identifier => NS0ID_ROOTFOLDER,
	    },
	    BrowseDescription_resultMask => BROWSERESULTMASK_ALL,
	}
    ],
);

my %response = (
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
	},
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
	},
	{
	  'ReferenceDescription_browseName' => {
	    'QualifiedName_namespaceIndex' => 0,
	    'QualifiedName_name' => 'Types'
	  },
	  'ReferenceDescription_referenceTypeId' => {
	    'NodeId_identifierType' => 0,
	    'NodeId_identifier' => 35,
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
	  'ReferenceDescription_isForward' => 1,
	  'ReferenceDescription_displayName' => {
	    'LocalizedText_text' => 'Types',
	    'LocalizedText_locale' => ''
	  },
	  'ReferenceDescription_nodeClass' => 1,
	  'ReferenceDescription_nodeId' => {
	    'ExpandedNodeId_serverIndex' => 0,
	    'ExpandedNodeId_namespaceUri' => undef,
	    'ExpandedNodeId_nodeId' => {
	      'NodeId_identifier' => 86,
	      'NodeId_identifierType' => 0,
	      'NodeId_namespaceIndex' => 0
	    }
	  }
	},
	{
	  'ReferenceDescription_nodeId' => {
	    'ExpandedNodeId_nodeId' => {
	      'NodeId_namespaceIndex' => 0,
	      'NodeId_identifier' => 87,
	      'NodeId_identifierType' => 0
	    },
	    'ExpandedNodeId_namespaceUri' => undef,
	    'ExpandedNodeId_serverIndex' => 0
	  },
	  'ReferenceDescription_nodeClass' => 1,
	  'ReferenceDescription_displayName' => {
	    'LocalizedText_text' => 'Views',
	    'LocalizedText_locale' => ''
	  },
	  'ReferenceDescription_isForward' => 1,
	  'ReferenceDescription_typeDefinition' => {
	    'ExpandedNodeId_namespaceUri' => undef,
	    'ExpandedNodeId_nodeId' => {
	      'NodeId_identifier' => 61,
	      'NodeId_identifierType' => 0,
	      'NodeId_namespaceIndex' => 0
	    },
	    'ExpandedNodeId_serverIndex' => 0
	  },
	  'ReferenceDescription_referenceTypeId' => {
	    'NodeId_namespaceIndex' => 0,
	    'NodeId_identifierType' => 0,
	    'NodeId_identifier' => 35
	  },
	  'ReferenceDescription_browseName' => {
	    'QualifiedName_name' => 'Views',
	    'QualifiedName_namespaceIndex' => 0
	  }
	}
      ],
      'BrowseResult_continuationPoint' => undef,
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
);

my $result = $client->{client}->Service_browse(\%request);
cmp_deeply($result, \%response, "browse response")
    or diag explain $result;

# Brose a node that does not exist in the middle of some other nodes.

my @nodeids =
    map { { BrowseDescription_nodeId => $_ } }
    map { $_->{ReferenceDescription_nodeId}{ExpandedNodeId_nodeId} }
    map { @{$_->{BrowseResult_references}} }
    @{$response{BrowseResponse_results}};
is(@nodeids, 4, "reference nodeids");

# Add another node with an invalid id at position 3
splice @nodeids, 3, 0, {
  'NodeId_identifier' => 1312634529,  # does not exist
  'NodeId_identifierType' => 0,
  'NodeId_namespaceIndex' => 0
};

$request{BrowseRequest_nodesToBrowse} = [ @nodeids ];

$result = $client->{client}->Service_browse(\%request);
is($result->{BrowseResponse_responseHeader}{ResponseHeader_serviceResult},
    STATUSCODE_GOOD, "header good")
    or diag explain $result;
is(@{$result->{BrowseResponse_results}}, 5, "results")
    or diag explain $result;
my @status =
    map { $_->{BrowseResult_statusCode} }
    @{$result->{BrowseResponse_results}};
is(@status, 5, "reference nodeids");
is_deeply(\@status, ['Good', 'Good', 'Good', 'BadNodeIdUnknown', 'Good'],
    "status") or diag explain \@status;

$client->stop();
$server->stop();
