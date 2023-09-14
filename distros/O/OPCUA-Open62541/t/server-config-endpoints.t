use strict;
use warnings;
use OPCUA::Open62541 qw(:STATUSCODE :MESSAGESECURITYMODE);
use OPCUA::Open62541::Test::Server;
use OPCUA::Open62541::Test::Client;
use OPCUA::Open62541::Test::CA;

use Test::More tests => 50;
use Test::Exception;
use Test::LeakTrace;
use Test::NoWarnings;
use Test::Warn;

my $ca = OPCUA::Open62541::Test::CA->new();
$ca->setup();
$ca->create_cert_client(issuer => $ca->create_cert_ca(name => "ca_client"));
$ca->create_cert_server(issuer => $ca->create_cert_ca(name => "ca_server"));

my $server = OPCUA::Open62541::Test::Server->new(
    certificate    => $ca->{certs}{server}{cert_pem},
    privateKey     => $ca->{certs}{server}{key_pem},
);
my $config    = $server->{server}->getConfig();
$server->start();

my $endpoints = $config->getEndpointDescriptions();
is(ref($endpoints), 'ARRAY', 'get ARRAY');

# 1 x None + 4 x Sign + 4 x SignAndEncrypt
is(scalar(@$endpoints), 9, 'get 9 endpoints');

no_leaks_ok { $config->getEndpointDescriptions() } 'get ok leak';

my $endpoints_filtered = [grep {
    $_->{EndpointDescription_securityMode} == MESSAGESECURITYMODE_SIGNANDENCRYPT
} @$endpoints];

# 4 x SignAndEncrypt
is(scalar(@$endpoints_filtered), 4, 'get 4 endpoints');

throws_ok { $config->setEndpointDescriptions() } (qr/Usage:/, 'set noarg');
lives_ok { $config->setEndpointDescriptions($endpoints_filtered) } 'set value';
no_leaks_ok { $config->setEndpointDescriptions($endpoints_filtered) } 'set value leak';

is(scalar(@{$config->getEndpointDescriptions()}), 4, 'get 4 endpoints');

my $client = OPCUA::Open62541::Test::Client->new(port => $server->port());
my $clientconfig = $client->{client}->getConfig();
$client->start();
$server->run();

# the client has an internal error because no endpoint matches
is($client->{client}->connect($client->url()), STATUSCODE_BADINTERNALERROR,
   "connect no endpoint fail");
ok($client->{log}->loggrep('No suitable endpoint found'));
$client->stop;

$client = OPCUA::Open62541::Test::Client->new(
    port => $server->port(),
    certificate    => $ca->{certs}{client}{cert_pem},
    privateKey     => $ca->{certs}{client}{key_pem},
);
$client->start();
is($client->{client}->connect($client->url()), STATUSCODE_GOOD,
    "connect encrypted ok");

$client->stop();
$server->stop();
