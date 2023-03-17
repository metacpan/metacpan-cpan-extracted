use strict;
use warnings;
use OPCUA::Open62541;

use IPC::Open3;
use OPCUA::Open62541::Test::CA;

use Test::More;
BEGIN {
    if(not OPCUA::Open62541::ClientConfig->can('setDefaultEncryption')) {
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

    plan tests => 44;
}
use Test::Exception;
use Test::LeakTrace;
use Test::NoWarnings;


my $ca = OPCUA::Open62541::Test::CA->new();
$ca->setup();

my ($cert_pem, $key_pem) = @{$ca->create_cert_client()}{qw(cert_pem key_pem)};
my ($crl_pem) = @{$ca->create_cert_ca()}{qw(crl_pem)};

# open62541 logs errors if security policies are set multiple times for a client
# config. For this reason we create clients and configs in separate blocks for
# the sub tests.

# test setDefaultEncryption() - fail
{
    ok(my $client = OPCUA::Open62541::Client->new(), "client new");
    ok(my $config = $client->getConfig(), "config get");

    throws_ok { OPCUA::Open62541::ClientConfig::setDefaultEncryption() }
	(qr/OPCUA::Open62541::ClientConfig::setDefaultEncryption\(config, localCertificate, privateKey, .*\) /,
	"config missing");
    no_leaks_ok { eval { OPCUA::Open62541::ClientConfig::setDefaultEncryption() } }
	"config missing leak";

    throws_ok { OPCUA::Open62541::ClientConfig::setDefaultEncryption(1, $cert_pem, $key_pem) }
	(qr/Self config is not a OPCUA::Open62541::ClientConfig /,
	"config type");
    no_leaks_ok { eval { OPCUA::Open62541::ClientConfig::setDefaultEncryption(1, $cert_pem, $key_pem) } }
	"config type leak";
}

# test setDefaultEncryption() - invalid certificate
{
    ok(my $client = OPCUA::Open62541::Client->new(), "client new");
    ok(my $config = $client->getConfig(), "config get");
    is($config->setDefaultEncryption("foo", "bar"), "Good", "encryption invalid cert");
}

# test setDefaultEncryption() - invalid certificate leak
no_leaks_ok {
    my $client = OPCUA::Open62541::Client->new();
    my $config = $client->getConfig();
    $config->setDefaultEncryption("foo", "bar");
} "encryption invalid cert leak";

# test setDefaultEncryption() - valid certificate
{
    ok(my $client = OPCUA::Open62541::Client->new(), "client new");
    ok(my $config = $client->getConfig(), "config get");
    is($config->setDefaultEncryption($cert_pem, $key_pem), "Good", "encryption valid");
}

# test setDefaultEncryption() - valid certificate leak
no_leaks_ok {
    my $client = OPCUA::Open62541::Client->new();
    my $config = $client->getConfig();
    $config->setDefaultEncryption($cert_pem, $key_pem);
} "encryption valid leak";

# test setDefaultEncryption() - empty trustList
{
    ok(my $client = OPCUA::Open62541::Client->new(), "client new");
    ok(my $config = $client->getConfig(), "config get");
    is($config->setDefaultEncryption($cert_pem, $key_pem, []), "Good", "encryption empty trustList");
}

# test setDefaultEncryption() - empty trustList leak
no_leaks_ok {
    my $client = OPCUA::Open62541::Client->new();
    my $config = $client->getConfig();
    $config->setDefaultEncryption($cert_pem, $key_pem, []);
} "encryption empty trustList leak";

# test setDefaultEncryption() - invalid trustList
{
    ok(my $client = OPCUA::Open62541::Client->new(), "client new");
    ok(my $config = $client->getConfig(), "config get");
    is($config->setDefaultEncryption($cert_pem, $key_pem, [undef]), "BadInternalError", "encryption invalid trustList");
}

# test setDefaultEncryption() - invalid trustList leak
no_leaks_ok {
    my $client = OPCUA::Open62541::Client->new();
    my $config = $client->getConfig();
    $config->setDefaultEncryption($cert_pem, $key_pem, [undef]);
} "encryption invalid trustList leak";

# test setDefaultEncryption() - valid trustList
{
    ok(my $client = OPCUA::Open62541::Client->new(), "client new");
    ok(my $config = $client->getConfig(), "config get");
    is($config->setDefaultEncryption($cert_pem, $key_pem, [$cert_pem, $cert_pem]), "Good", "encryption valid trustList");
}

# test setDefaultEncryption() - valid trustList leak
no_leaks_ok  {
    my $client = OPCUA::Open62541::Client->new();
    my $config = $client->getConfig();
    $config->setDefaultEncryption($cert_pem, $key_pem, [$cert_pem, $cert_pem]);
} "encryption valid trustList leak";

# test setDefaultEncryption() - empty revocationList
{
    ok(my $client = OPCUA::Open62541::Client->new(), "client new");
    ok(my $config = $client->getConfig(), "config get");
    is($config->setDefaultEncryption($cert_pem, $key_pem, [$cert_pem], []), "Good", "encryption empty revocationList");
}

# test setDefaultEncryption() - empty revocationList leak
no_leaks_ok {
    my $client = OPCUA::Open62541::Client->new();
    my $config = $client->getConfig();
    $config->setDefaultEncryption($cert_pem, $key_pem, [$cert_pem], []);
} "encryption empty revocationList leak";

# test setDefaultEncryption() - invalid revocationList
{
    ok(my $client = OPCUA::Open62541::Client->new(), "client new");
    ok(my $config = $client->getConfig(), "config get");
    is($config->setDefaultEncryption($cert_pem, $key_pem, [$cert_pem], [undef]), "BadInternalError", "encryption invalid revocationList");
}

# test setDefaultEncryption() - invalid revocationList leak
no_leaks_ok {
    my $client = OPCUA::Open62541::Client->new();
    my $config = $client->getConfig();
    $config->setDefaultEncryption($cert_pem, $key_pem, [$cert_pem], [undef]);
} "encryption invalid revocationList leak";

# test setDefaultEncryption() - valid revocationList
{
    ok(my $client = OPCUA::Open62541::Client->new(), "client new");
    ok(my $config = $client->getConfig(), "config get");
    is($config->setDefaultEncryption($cert_pem, $key_pem, [$cert_pem, $cert_pem], [$crl_pem]), "Good", "encryption valid revocationList");
}

# test setDefaultEncryption() - valid revocationList leak
no_leaks_ok {
    my $client = OPCUA::Open62541::Client->new();
    my $config = $client->getConfig();
    $config->setDefaultEncryption($cert_pem, $key_pem, [$cert_pem, $cert_pem], [$crl_pem]);
} "encryption valid revocationList leak";

# test setDefaultEncryption() - valid revocationList no trustList
{
    ok(my $client = OPCUA::Open62541::Client->new(), "client new");
    ok(my $config = $client->getConfig(), "config get");
    is($config->setDefaultEncryption($cert_pem, $key_pem, undef, [$crl_pem]), "Good", "encryption valid revocationList no trustList");
}

# test setDefaultEncryption() - valid revocationList no trustList leak
no_leaks_ok {
    my $client = OPCUA::Open62541::Client->new();
    my $config = $client->getConfig();
    $config->setDefaultEncryption($cert_pem, $key_pem, undef, [$crl_pem]);
} "encryption valid revocationList no trustList leak";
