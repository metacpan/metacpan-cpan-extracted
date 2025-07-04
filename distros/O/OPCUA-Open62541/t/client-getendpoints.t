use strict;
use warnings;

use OPCUA::Open62541 qw(:all);
use OPCUA::Open62541::Test::Client;
use OPCUA::Open62541::Test::Server;

use Test::More tests =>
    OPCUA::Open62541::Test::Server::planning() +
    OPCUA::Open62541::Test::Client::planning() + 19;
use Test::Deep;
use Test::Exception;
use Test::LeakTrace;
use Test::NoWarnings;

my $server = OPCUA::Open62541::Test::Server->new();

$server->start();
$server->run();

my $client = OPCUA::Open62541::Test::Client->new(port => $server->port());
$client->start();

my $endpoints;
my $serverurl_valid   = 'opc.tcp://127.0.0.1:' . $server->port . '/';
my $serverurl_invalid = 'opc.tcp://127.0.0.2:' . $server->port . '/';
my $serverurl         = '';

my $expected = [{
    EndpointDescription_server => {
	ApplicationDescription_gatewayServerUri => undef,
	ApplicationDescription_applicationType => 0,
	ApplicationDescription_discoveryUrls => [$serverurl_valid],
	ApplicationDescription_applicationName => {
	    LocalizedText_locale => 'en',
	    LocalizedText_text => 'open62541-based OPC UA Application'
	},
	ApplicationDescription_applicationUri => 'urn:open62541.server.application',
	ApplicationDescription_discoveryProfileUri => undef,
	ApplicationDescription_productUri => 'http://open62541.org'
    },
    EndpointDescription_serverCertificate => undef,
    EndpointDescription_securityLevel => 1,
    EndpointDescription_securityMode => 1,
    EndpointDescription_transportProfileUri => 'http://opcfoundation.org/UA-Profile/Transport/uatcp-uasc-uabinary',
    EndpointDescription_userIdentityTokens => [{
	UserTokenPolicy_tokenType => 0,
	UserTokenPolicy_policyId => 'open62541-anonymous-policy',
	UserTokenPolicy_securityPolicyUri => undef,
	UserTokenPolicy_issuerEndpointUrl => undef,
	UserTokenPolicy_issuedTokenType => undef
    }, {
	UserTokenPolicy_issuerEndpointUrl => undef,
	UserTokenPolicy_securityPolicyUri => 'http://opcfoundation.org/UA/SecurityPolicy#None',
	UserTokenPolicy_policyId => 'open62541-username-policy',
	UserTokenPolicy_tokenType => 1,
	UserTokenPolicy_issuedTokenType => undef
    }],
    EndpointDescription_securityPolicyUri => 'http://opcfoundation.org/UA/SecurityPolicy#None',
    EndpointDescription_endpointUrl => $serverurl_valid
}];

note 'test parameter croaks';

throws_ok { $client->{client}->getEndpoints($serverurl, undef) }
    (qr/Output parameter endpoints is not a scalar reference/,
    'endpoints parameter undef');

throws_ok { $client->{client}->getEndpoints($serverurl, 5) }
    (qr/Output parameter endpoints is not a scalar reference/,
    'endpoints parameter scalar');

throws_ok { $client->{client}->getEndpoints($serverurl, []) }
    (qr/Output parameter endpoints is not a scalar reference/,
    'endpoints parameter array ref');

throws_ok { $client->{client}->getEndpoints($serverurl, \5) }
    (qr/Output parameter endpoints is not a scalar reference/,
    'endpoints parameter read only ref');

no_leaks_ok { eval { $client->{client}->getEndpoints($serverurl, undef) } }
    'leaks endpoints parameter undef';

no_leaks_ok { eval { $client->{client}->getEndpoints($serverurl, \5) } }
    'leaks endpoints parameter read only ref';

note 'test not connected valid';
$serverurl = $serverurl_valid;

is $client->{client}->getEndpoints($serverurl, \$endpoints), 'Good',
   'status getendpoints not connected';
cmp_deeply $endpoints, $expected, 'data getendpoints not connected';
no_leaks_ok {
    my $endpoints;
    $client->{client}->getEndpoints($serverurl, \$endpoints)
} 'leaks getendpoints not connected';

note 'test not connected invalid';

$serverurl = $serverurl_invalid;

is $client->{client}->getEndpoints($serverurl, \$endpoints), 'BadDisconnect',
   'status not connected getendpoints invalid';
cmp_deeply $endpoints, [], 'data not connected getendpoints invalid';
no_leaks_ok {
    my $endpoints;
    $client->{client}->getEndpoints($serverurl, \$endpoints)
} 'leaks not connected getendpoints invalid';

note 'test connected valid';

$serverurl = $serverurl_valid;
$client->run;

is $client->{client}->getEndpoints($serverurl, \$endpoints), 'Good',
   'status getendpoints connected';
cmp_deeply $endpoints, $expected, 'data getendpoints connected';
no_leaks_ok {
    my $endpoints;
    $client->{client}->getEndpoints($serverurl, \$endpoints)
} 'leaks getendpoints connected';

note 'test connected invalid';

$serverurl = $serverurl_invalid;

is $client->{client}->getEndpoints($serverurl, \$endpoints), 'BadInvalidArgument',
   'status getendpoints invalid';
cmp_deeply $endpoints, [], 'data getendpoints invalid';
no_leaks_ok {
    my $endpoints;
    $client->{client}->getEndpoints($serverurl, \$endpoints)
} 'leaks getendpoints invalid';

$client->stop();
$server->stop();
