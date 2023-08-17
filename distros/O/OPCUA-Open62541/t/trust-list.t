use strict;
use warnings;
use OPCUA::Open62541;
use OPCUA::Open62541 qw(:STATUSCODE);
use OPCUA::Open62541::Test::CA;

use Test::More tests => 18;
use Test::Exception;
use Test::LeakTrace;
use Test::NoWarnings;
use Test::Warn;

lives_ok { OPCUA::Open62541::CertificateVerification->new() }
    "new destroy";
no_leaks_ok { OPCUA::Open62541::CertificateVerification->new() }
    "new destroy leak";

my $cv = OPCUA::Open62541::CertificateVerification->new();
ok($cv, "new");
my $sc = $cv->Trustlist(undef, undef, undef);
is($sc, STATUSCODE_GOOD, "trustlist good");
no_leaks_ok { $cv->Trustlist(undef, undef, undef) }
    "trustlist good leak";

throws_ok { $cv->Trustlist("foo", undef, undef) }
    qr/Not an ARRAY reference with ByteString list/, "trustlist foo";
throws_ok { $cv->Trustlist(undef, "bar", undef) }
    qr/Not an ARRAY reference with ByteString list/, "trustlist bar";
throws_ok { $cv->Trustlist(undef, undef, "foobar") }
    qr/Not an ARRAY reference with ByteString list/, "trustlist foobar";
no_leaks_ok { eval { $cv->Trustlist(undef, "bar", undef) } }
    "trustlist bar leak";

is($cv->Trustlist([], [], []), STATUSCODE_GOOD, "trustlist empty");
no_leaks_ok { $cv->Trustlist([], [], []) }
    "trustlist empty leak";

is($cv->Trustlist(["foo"], ["bar"], ["foo", "bar"]),
    STATUSCODE_BADINTERNALERROR, "trustlist array foo bar");
no_leaks_ok { $cv->Trustlist(["foo"], ["bar"], ["foo", "bar"]) }
    "trustlist array foo bar leak";

my $ca = OPCUA::Open62541::Test::CA->new();
$ca->setup();
$ca->create_cert_client(issuer => $ca->create_cert_ca(name => "ca_client"));
$ca->create_cert_server(issuer => $ca->create_cert_ca(name => "ca_server"));
$ca->create_cert_server(name => "server_selfsigned");

is($cv->Trustlist(
    [$ca->{certs}{ca_client}{cert_pem}],
    [$ca->{certs}{ca_server}{cert_pem}],
    [$ca->{certs}{ca_client}{crl_pem}, $ca->{certs}{ca_server}{crl_pem}]
), STATUSCODE_GOOD, "trustlist pem");
no_leaks_ok { $cv->Trustlist(
    [$ca->{certs}{ca_client}{cert_pem}],
    [$ca->{certs}{ca_server}{cert_pem}],
    [$ca->{certs}{ca_client}{crl_pem}, $ca->{certs}{ca_server}{crl_pem}]
)} "trustlist pem leak";
