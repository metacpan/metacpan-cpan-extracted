use strict;
use warnings;
use OPCUA::Open62541 ':all';

use IPC::Open3;
use MIME::Base64;
use OPCUA::Open62541::Test::Server;
use OPCUA::Open62541::Test::Client;
use OPCUA::Open62541::Test::CA;
use Test::More;
BEGIN {
    if(not OPCUA::Open62541::ServerConfig->can('setDefaultWithSecurityPolicies')) {
	plan skip_all => 'open62541 without UA_ENABLE_ENCRYPTION';
	return;
    }

    my $pid = eval { open3(undef, undef, undef, 'openssl', 'version') };
    if (not $pid) {
	plan skip_all => 'no openssl for CRL generation';
	return;
    }

    waitpid($pid, 0);

    if ($? >> 8) {
	plan skip_all => 'no openssl for CRL generation';
	return;
    }

    plan tests =>
	OPCUA::Open62541::Test::Server::planning() +
	OPCUA::Open62541::Test::Client::planning() + 243;
}
use Test::LeakTrace;
use Test::NoWarnings;

my $ca = OPCUA::Open62541::Test::CA->new();
$ca->setup();

$ca->create_cert_client(issuer => $ca->create_cert_root(name => "ca_client"));
$ca->create_cert_server(issuer => $ca->create_cert_root(name => "ca_server"));

$ca->create_cert_server(name => "server_selfsigned");

$ca->create_cert_server(
    name        => "server_expired",
    issuer      => "ca_server",
    create_args => {not_after => time() - 365*24*60*60},
);

$ca->create_cert_server(
    name        => 'server_revoked',
    issuer      => 'ca_server',
);
$ca->revoke(
    name => 'server_revoked',
    issuer => 'ca_server',
);

sub _setup {
    my %args = @_;
    my $client_name = $args{client_name} // 'client';
    my $server_name = $args{server_name} // 'server';

    my $server = OPCUA::Open62541::Test::Server->new(
	certificate    => $ca->{certs}{$server_name}{cert_pem},
	privateKey     => $ca->{certs}{$server_name}{key_pem},
	trustList      => $args{server_trustList},
	issuerList     => $args{server_issuerList},
	revocationList => $args{server_revocationList},
    );

    my $serverconfig = $server->{server}->getConfig();
    $server->start();

    $serverconfig->setApplicationDescription({
	ApplicationDescription_applicationUri => "urn:server.p5-opcua-open65241",
	ApplicationDescription_applicationType => APPLICATIONTYPE_SERVER,
    });

    my $client = OPCUA::Open62541::Test::Client->new(
	port => $server->port(),
	certificate    => $ca->{certs}{$client_name}{cert_pem},
	privateKey     => $ca->{certs}{$client_name}{key_pem},
	trustList      => $args{client_trustList},
	revocationList => $args{client_revocationList},
    );
    my $clientconfig = $client->{client}->getConfig();
    $client->start();

    $clientconfig->setSecurityMode(MESSAGESECURITYMODE_SIGNANDENCRYPT);
    $clientconfig->setClientDescription({
	ApplicationDescription_applicationUri => "urn:client.p5-opcua-open65241",
	ApplicationDescription_applicationType => APPLICATIONTYPE_CLIENT,
    });

    $server->run();

    return ($client, $server);
}

my $secpol = "Basic128Rsa15";

# test client connect no validation success
{
    my ($client, $server) = _setup(server_name => "server_selfsigned");

    is($client->{client}->connect($client->url()), STATUSCODE_GOOD,
       "client connect no validation success");

    ok($client->{log}->loggrep("Selected endpoint .* with SecurityMode SignAndEncrypt and SecurityPolicy .*#$secpol"),
       "client: endpoint SignAndEncrypt");
    ok($client->{log}->loggrep("Selected UserTokenPolicy .* with UserTokenType Anonymous and SecurityPolicy .*#$secpol"),
       "client: UserTokenPolicy anonymous");

    ok($server->{log}->loggrep("SecureChannel opened with SecurityPolicy .*#$secpol"),
       "server: secure channel with security policy");

    $client->stop;
    $server->stop;
}

# test client connect validation success
{
    my ($client, $server) = _setup(
	client_trustList      => [$ca->{certs}{ca_server}{cert_pem}],
	client_revocationList => [$ca->{certs}{ca_server}{crl_pem}]
    );

    is($client->{client}->connect($client->url()), STATUSCODE_GOOD,
       "client connect validation success");

    ok($client->{log}->loggrep("Selected endpoint .* with SecurityMode SignAndEncrypt and SecurityPolicy .*#$secpol"),
       "client: endpoint SignAndEncrypt");
    ok($client->{log}->loggrep("Selected UserTokenPolicy .* with UserTokenType Anonymous and SecurityPolicy .*#$secpol"),
       "client: UserTokenPolicy anonymous");

    ok($server->{log}->loggrep("SecureChannel opened with SecurityPolicy .*#$secpol"),
       "server: secure channel with security policy");

    $client->stop;
    $server->stop;
}

# test client connect no CRL fail
{
    my ($client, $server) = _setup(
	client_trustList => [$ca->{certs}{ca_server}{cert_pem}]
    );

    is($client->{client}->connect($client->url()), STATUSCODE_BADCONNECTIONCLOSED,
       "client connect no CRL fail");

    ok($client->{log}->loggrep("Receiving the response failed with StatusCode BadCertificateRevocationUnknown"),
       "client: statuscode revocationunknown");

    $client->stop;
    $server->stop;
}

# test client connect not trusted fail
{
    my ($client, $server) = _setup(
	client_trustList => [$ca->{certs}{ca_client}{cert_pem}]
    );

    is($client->{client}->connect($client->url()), STATUSCODE_BADCONNECTIONCLOSED,
       "client connect not trusted fail");

    ok($client->{log}->loggrep("Receiving the response failed with StatusCode BadCertificateUntrusted"),
       "client: statuscode untrusted");

    $client->stop;
    $server->stop;
}

# test client connect use not allowed fail
{
    my ($client, $server) = _setup(
	server_name           => "ca_server",
	client_trustList      => [$ca->{certs}{ca_server}{cert_pem}],
	client_revocationList => [$ca->{certs}{ca_server}{crl_pem}]
    );

    is($client->{client}->connect($client->url()), STATUSCODE_BADCONNECTIONCLOSED,
       "client connect use not allowed fail");

    ok($client->{log}->loggrep("Receiving the response failed with StatusCode BadCertificateUseNotAllowed"),
       "client: statuscode usenotallowed");

    $client->stop;
    $server->stop;
}

# test client connect cert expired fail
{
    my ($client, $server) = _setup(
	server_name           => "server_expired",
	client_trustList      => [$ca->{certs}{ca_server}{cert_pem}],
	client_revocationList => [$ca->{certs}{ca_server}{crl_pem}]
    );

    is($client->{client}->connect($client->url()), STATUSCODE_BADCONNECTIONCLOSED,
       "client connect cert expired fail");

    ok($client->{log}->loggrep("Receiving the response failed with StatusCode BadCertificateTimeInvalid"),
       "client: statuscode timeinvalid");

    $client->stop;
    $server->stop;
}

# test client connect cert revoked fail
{
    my ($client, $server) = _setup(
	server_name           => 'server_revoked',
	client_trustList      => [$ca->{certs}{ca_server}{cert_pem}],
	client_revocationList => [$ca->{certs}{ca_server}{crl_pem}]
    );

    is($client->{client}->connect($client->url()), STATUSCODE_BADCONNECTIONCLOSED,
       'client connect cert revoked fail');

    ok($client->{log}->loggrep('Receiving the response failed with StatusCode BadCertificateRevoked'),
       'client: statuscode revoked');

    $client->stop;
    $server->stop;
}

# test client connect validation server success
{
    my ($client, $server) = _setup(
	client_trustList      => [$ca->{certs}{ca_server}{cert_pem}],
	client_revocationList => [$ca->{certs}{ca_server}{crl_pem}],
	server_trustList      => [$ca->{certs}{ca_client}{cert_pem}],
	server_revocationList => [$ca->{certs}{ca_client}{crl_pem}],
    );

    is($client->{client}->connect($client->url()), STATUSCODE_GOOD,
       'client connect validation server success');

    $client->stop;
    $server->stop;
}

# test client connect validation server not trusted fail
{
    my ($client, $server) = _setup(
	client_trustList      => [$ca->{certs}{ca_server}{cert_pem}],
	client_revocationList => [$ca->{certs}{ca_server}{crl_pem}],
	server_trustList      => [$ca->{certs}{ca_server}{cert_pem}],
    );

    is($client->{client}->connect($client->url()), STATUSCODE_BADCONNECTIONCLOSED,
       'client connect validation server not trusted fail');

    ok($server->{log}->loggrep('failed with error BadCertificateUntrusted'),
       'server: statuscode untrusted');

    $client->stop;
    $server->stop;
}
