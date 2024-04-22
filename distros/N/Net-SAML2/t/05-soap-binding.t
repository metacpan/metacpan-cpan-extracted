use strict;
use warnings;
use Test::Lib;
use Test::Net::SAML2;

use Net::SAML2::IdP;
use Net::SAML2::Binding::SOAP;
use Test::Mock::One;

use LWP::UserAgent;

my $sp = net_saml2_sp();

my $metadata = path('t/idp-metadata.xml')->slurp;

my $idp = Net::SAML2::IdP->new_from_xml(
    xml    => $metadata,
    cacert => 't/cacert.pem'
);
isa_ok($idp, "Net::SAML2::IdP");

my $slo_url = $idp->slo_url($idp->binding('soap'));
is(
    $slo_url,
    'http://sso.dev.venda.com/opensso/IDPSloSoap/metaAlias/idp',
    'SLO url is correct'
);

my $idp_cert;
foreach my $use (keys %{$idp->certs}) {
    for my $cert (@{$idp->cert($use)}) {
        $idp_cert = $cert;
        looks_like_a_cert($cert);
    }
};

my $nameid  = 'user-to-log-out';
my $session = 'session-to-log-out';

my $request
    = $sp->logout_request($idp->entityid, $nameid, $idp->format('persistent'),
    $session);

isa_ok($request, "Net::SAML2::Protocol::LogoutRequest");
my $request_xml = $request->as_xml;
my $id = $request->{id};

my $xp = get_xpath($request_xml);
isa_ok($xp, "XML::LibXML::XPathContext");

my $ua   = LWP::UserAgent->new;
my $soap = $sp->soap_binding($ua, $slo_url, $idp->cert('signing'));
isa_ok($soap, "Net::SAML2::Binding::SOAP");

my $soap_req = $soap->create_soap_envelope($request_xml);

# TODO: set soap paths and check envelop and body
$xp = get_xpath($soap_req);
isa_ok($xp, "XML::LibXML::XPathContext");

my $xml = $soap->handle_request($soap_req);
like($xml, qr/\Q<samlp:LogoutRequest\E/, "Logout XML found");
$xp = get_xpath($xml);
isa_ok($xp, "XML::LibXML::XPathContext");

my $soaped_request = Net::SAML2::Protocol::LogoutRequest->new_from_xml(
    xml => $xml
);
isa_ok($soaped_request, 'Net::SAML2::Protocol::LogoutRequest');

is($soaped_request->{id}, $id,
    "LogoutRequest ID is as expected");
is($soaped_request->session, $request->session,
    "SOAP session equals request session");
is($soaped_request->nameid, $request->nameid,
    "SOAP nameid equals request nameid");

{
    # Testing trust anchors of SAML
    # You can set various trust anchors of SAML so the response is checked
    # against some kind of anchor.
    my %anchors = (
        subject     => [qw(foo bar)],
        issuer      => 'Net::SAML2',
        issuer_hash => [
            'f1d2d2f924e986ac86fdf7b36c94bcdf32beec15',
            'e242ed3bffccdf271b7fbaf34ed72d089537b42f'
        ],
    );

    my $xml      = "<xml></xml>";
    my $override = Sub::Override->new(
        'Net::SAML2::Binding::SOAP::_get_saml_from_soap' => sub {
            return $xml;
        },
    );
    $override->override(
        'XML::Sig::new' => sub {
            return Test::Mock::One->new(
                subject     => 'foo',
                issuer      => 'Net::SAML2',
                issuer_hash => 'f1d2d2f924e986ac86fdf7b36c94bcdf32beec15',
            );
        }
    );

    foreach (keys %anchors) {
        my $soap = Net::SAML2::Binding::SOAP->new(
            url      => 'https://example.com/auth/saml',
            key      => $sp->key,
            cert     => $sp->cert,
            idp_cert => [$idp_cert],
            anchors  => { $_ => $anchors{$_} }
        );
        isa_ok($soap, "Net::SAML2::Binding::SOAP");

        is($soap->handle_response('here be soap'),
            "<xml></xml>", "We got our XML, so we are verified");
    }

    my $soap = Net::SAML2::Binding::SOAP->new(
        url      => 'https://example.com/auth/saml',
        key      => $sp->key,
        cert     => $sp->cert,
        idp_cert => [ $idp_cert ],
        anchors  => { subject => 'testsuite failure expected' }
    );

    throws_ok(
        sub {
            $soap->handle_response('here be failure');
        },
        qr/Could not verify trust anchors of certificate!/,
        "We cannot trust the anchor"
    )
}

$metadata = path('t/data/idp-samlid-metadata.xml')->slurp;

$idp = Net::SAML2::IdP->new_from_xml(
    xml    => $metadata,
    cacert => 't/data/cacert-samlid.pem'
);
isa_ok($idp, "Net::SAML2::IdP");

my $sso_url = $idp->sso_url($idp->binding('soap')); #'urn:oasis:names:tc:SAML:2.0:bindings:SOAP');

is(
    $sso_url,
    'https://samltest.id/idp/profile/SAML2/SOAP/ECP',
    'SSO url is correct'
);

foreach my $use (keys %{$idp->certs}) {
    for my $cert (@{$idp->cert($use)}) {
        $idp_cert = $cert;
        ok(looks_like_a_cert($idp_cert), "Certificate for: \"$use\" looks like a cert");
    }
};

{

my $art_response = << 'ARTIFACT';
<?xml version="1.0" encoding="UTF-8"?>
<soap11:Envelope xmlns:soap11="http://schemas.xmlsoap.org/soap/envelope/"><soap11:Body><saml2p:ArtifactResponse ID="_c9ce9fb074bc6e1773f21f1e32a935b5" InResponseTo="NETSAML2_fc7ddf1855713b8cd4ea05b3f190d7e84328f48d7e7683addea941f930e026ef" IssueInstant="2022-12-17T23:46:54.386Z" Version="2.0" xmlns:saml2p="urn:oasis:names:tc:SAML:2.0:protocol"><saml2:Issuer xmlns:saml2="urn:oasis:names:tc:SAML:2.0:assertion">https://samltest.id/saml/idp</saml2:Issuer><ds:Signature xmlns:ds="http://www.w3.org/2000/09/xmldsig#"><ds:SignedInfo><ds:CanonicalizationMethod Algorithm="http://www.w3.org/2001/10/xml-exc-c14n#"/><ds:SignatureMethod Algorithm="http://www.w3.org/2001/04/xmldsig-more#rsa-sha256"/><ds:Reference URI="#_c9ce9fb074bc6e1773f21f1e32a935b5"><ds:Transforms><ds:Transform Algorithm="http://www.w3.org/2000/09/xmldsig#enveloped-signature"/><ds:Transform Algorithm="http://www.w3.org/2001/10/xml-exc-c14n#"/></ds:Transforms><ds:DigestMethod Algorithm="http://www.w3.org/2001/04/xmlenc#sha256"/><ds:DigestValue>s/eocRHqszIYvUW/5TUXYeppjFfxRhBktwGPFCBZx60=</ds:DigestValue></ds:Reference></ds:SignedInfo><ds:SignatureValue>H/V267LZbAZBA9hm/kiL8u2MiA1Tkc65cM6B3ZsFBRvff4Wq2szl2hTAFNW0zSItJvI3PS531z4/YWZ6K1qAxeWJfJIwzuQcA7qwH5ZDBpzlbOXLfFfzKRK75jUGUItHowRCGtMo31rOW67VJWR2LrQ3whmzk5g5SXOUhKaYx0xhgFevt6ba2ynXGih9tdqsypkZrtJEFrv+FcDPkKKvltf1eO9NoFPKwK5E57c47c/qI7B9andA50a1ij58WrSakNR1P0RCjdBkjnVRxpWSCZFu0SOw57vIVG470o47txib6AZ4UygsZyna7kqNoB/1XVXZsYtMEpyRZ60TMrfKHg==</ds:SignatureValue><ds:KeyInfo><ds:X509Data><ds:X509Certificate>MIIDEjCCAfqgAwIBAgIVAMECQ1tjghafm5OxWDh9hwZfxthWMA0GCSqGSIb3DQEBCwUAMBYxFDAS
BgNVBAMMC3NhbWx0ZXN0LmlkMB4XDTE4MDgyNDIxMTQwOVoXDTM4MDgyNDIxMTQwOVowFjEUMBIG
A1UEAwwLc2FtbHRlc3QuaWQwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQC0Z4QX1NFK
s71ufbQwoQoW7qkNAJRIANGA4iM0ThYghul3pC+FwrGv37aTxWXfA1UG9njKbbDreiDAZKngCgyj
xj0uJ4lArgkr4AOEjj5zXA81uGHARfUBctvQcsZpBIxDOvUUImAl+3NqLgMGF2fktxMG7kX3GEVN
c1klbN3dfYsaw5dUrw25DheL9np7G/+28GwHPvLb4aptOiONbCaVvh9UMHEA9F7c0zfF/cL5fOpd
Va54wTI0u12CsFKt78h6lEGG5jUs/qX9clZncJM7EFkN3imPPy+0HC8nspXiH/MZW8o2cqWRkrw3
MzBZW3Ojk5nQj40V6NUbjb7kfejzAgMBAAGjVzBVMB0GA1UdDgQWBBQT6Y9J3Tw/hOGc8PNV7JEE
4k2ZNTA0BgNVHREELTArggtzYW1sdGVzdC5pZIYcaHR0cHM6Ly9zYW1sdGVzdC5pZC9zYW1sL2lk
cDANBgkqhkiG9w0BAQsFAAOCAQEASk3guKfTkVhEaIVvxEPNR2w3vWt3fwmwJCccW98XXLWgNbu3
YaMb2RSn7Th4p3h+mfyk2don6au7Uyzc1Jd39RNv80TG5iQoxfCgphy1FYmmdaSfO8wvDtHTTNiL
ArAxOYtzfYbzb5QrNNH/gQEN8RJaEf/g/1GTw9x/103dSMK0RXtl+fRs2nblD1JJKSQ3AdhxK/we
P3aUPtLxVVJ9wMOQOfcy02l+hHMb6uAjsPOpOVKqi3M8XmcUZOpx4swtgGdeoSpeRyrtMvRwdcci
NBp9UZome44qZAYH1iqrpmmjsfI9pJItsgWu3kXPjhSfj1AJGR1l9JGvJrHki1iHTA==</ds:X509Certificate></ds:X509Data></ds:KeyInfo></ds:Signature><saml2p:Status><saml2p:StatusCode Value="urn:oasis:names:tc:SAML:2.0:status:Success"/></saml2p:Status><saml2p:Response Destination="https://netsaml2-testapp.local/consumer-artifact" ID="_f8737da9954da23081f3cdeeb46813a8" InResponseTo="NETSAML2_32dbfe9bc418be519c05becf92666280738519f497cd3a4bff29e5f4a574ed3b" IssueInstant="2022-12-17T23:46:53.840Z" Version="2.0" xmlns:saml2p="urn:oasis:names:tc:SAML:2.0:protocol"><saml2:Issuer xmlns:saml2="urn:oasis:names:tc:SAML:2.0:assertion">https://samltest.id/saml/idp</saml2:Issuer><ds:Signature xmlns:ds="http://www.w3.org/2000/09/xmldsig#"><ds:SignedInfo><ds:CanonicalizationMethod Algorithm="http://www.w3.org/2001/10/xml-exc-c14n#"/><ds:SignatureMethod Algorithm="http://www.w3.org/2001/04/xmldsig-more#rsa-sha256"/><ds:Reference URI="#_f8737da9954da23081f3cdeeb46813a8"><ds:Transforms><ds:Transform Algorithm="http://www.w3.org/2000/09/xmldsig#enveloped-signature"/><ds:Transform Algorithm="http://www.w3.org/2001/10/xml-exc-c14n#"/></ds:Transforms><ds:DigestMethod Algorithm="http://www.w3.org/2001/04/xmlenc#sha256"/><ds:DigestValue>++jc2oCbTRaE3yPSXOohxH2ptXRtjsvekIOP8Svg7+w=</ds:DigestValue></ds:Reference></ds:SignedInfo><ds:SignatureValue>U8KnYvlLtqC+suCOk0BDRXbqNlfAbwurQ8oOIgLS5gL3CSVCFFMXxoGtmhzum7iAwpL+zE4zdvMbYd/mZOgbsoQsOJXK0KHUzn/y5lRDwtaCfH59osNz2J9aUc8IRX6T8UvPpx4nZg2LjUQbM4LvYp19wREnGKFBwQbA7BJ0293EsU8S9GZAoN3dYSy+GbESXBLGT2PbXwIFp9NGnvBPLb11mv6mAP7s0DCHbH6Ly2YMyqv4SGe3Jou+Iwc+uuvgDm9SAWklN3ITzEd6KfpajsAd1faXpvAwyQpDtYPxz2z4AUDJzXeHUFY7TAzwQXn1pYASWjF8ry57U3xynHDZ9w==</ds:SignatureValue><ds:KeyInfo><ds:X509Data><ds:X509Certificate>MIIDEjCCAfqgAwIBAgIVAMECQ1tjghafm5OxWDh9hwZfxthWMA0GCSqGSIb3DQEBCwUAMBYxFDAS
BgNVBAMMC3NhbWx0ZXN0LmlkMB4XDTE4MDgyNDIxMTQwOVoXDTM4MDgyNDIxMTQwOVowFjEUMBIG
A1UEAwwLc2FtbHRlc3QuaWQwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQC0Z4QX1NFK
s71ufbQwoQoW7qkNAJRIANGA4iM0ThYghul3pC+FwrGv37aTxWXfA1UG9njKbbDreiDAZKngCgyj
xj0uJ4lArgkr4AOEjj5zXA81uGHARfUBctvQcsZpBIxDOvUUImAl+3NqLgMGF2fktxMG7kX3GEVN
c1klbN3dfYsaw5dUrw25DheL9np7G/+28GwHPvLb4aptOiONbCaVvh9UMHEA9F7c0zfF/cL5fOpd
Va54wTI0u12CsFKt78h6lEGG5jUs/qX9clZncJM7EFkN3imPPy+0HC8nspXiH/MZW8o2cqWRkrw3
MzBZW3Ojk5nQj40V6NUbjb7kfejzAgMBAAGjVzBVMB0GA1UdDgQWBBQT6Y9J3Tw/hOGc8PNV7JEE
4k2ZNTA0BgNVHREELTArggtzYW1sdGVzdC5pZIYcaHR0cHM6Ly9zYW1sdGVzdC5pZC9zYW1sL2lk
cDANBgkqhkiG9w0BAQsFAAOCAQEASk3guKfTkVhEaIVvxEPNR2w3vWt3fwmwJCccW98XXLWgNbu3
YaMb2RSn7Th4p3h+mfyk2don6au7Uyzc1Jd39RNv80TG5iQoxfCgphy1FYmmdaSfO8wvDtHTTNiL
ArAxOYtzfYbzb5QrNNH/gQEN8RJaEf/g/1GTw9x/103dSMK0RXtl+fRs2nblD1JJKSQ3AdhxK/we
P3aUPtLxVVJ9wMOQOfcy02l+hHMb6uAjsPOpOVKqi3M8XmcUZOpx4swtgGdeoSpeRyrtMvRwdcci
NBp9UZome44qZAYH1iqrpmmjsfI9pJItsgWu3kXPjhSfj1AJGR1l9JGvJrHki1iHTA==</ds:X509Certificate></ds:X509Data></ds:KeyInfo></ds:Signature><saml2p:Status xmlns:saml2p="urn:oasis:names:tc:SAML:2.0:protocol"><saml2p:StatusCode Value="urn:oasis:names:tc:SAML:2.0:status:Success"/></saml2p:Status><saml2:EncryptedAssertion xmlns:saml2="urn:oasis:names:tc:SAML:2.0:assertion"><xenc:EncryptedData Id="_f15d9c06ba0060293a313e1a562e1d5c" Type="http://www.w3.org/2001/04/xmlenc#Element" xmlns:xenc="http://www.w3.org/2001/04/xmlenc#"><xenc:EncryptionMethod Algorithm="http://www.w3.org/2001/04/xmlenc#aes128-cbc" xmlns:xenc="http://www.w3.org/2001/04/xmlenc#"/><ds:KeyInfo xmlns:ds="http://www.w3.org/2000/09/xmldsig#"><xenc:EncryptedKey Id="_14f9e98985580605e5b3d026afb30796" Recipient="https://netsaml2-testapp.local" xmlns:xenc="http://www.w3.org/2001/04/xmlenc#"><xenc:EncryptionMethod Algorithm="http://www.w3.org/2001/04/xmlenc#rsa-oaep-mgf1p" xmlns:xenc="http://www.w3.org/2001/04/xmlenc#"><ds:DigestMethod Algorithm="http://www.w3.org/2000/09/xmldsig#sha1" xmlns:ds="http://www.w3.org/2000/09/xmldsig#"/></xenc:EncryptionMethod><ds:KeyInfo><ds:X509Data><ds:X509Certificate>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
1vCZjyOZTb+mYgWUvg==</ds:X509Certificate></ds:X509Data></ds:KeyInfo><xenc:CipherData xmlns:xenc="http://www.w3.org/2001/04/xmlenc#"><xenc:CipherValue>QW4S06gEvFsBNEPRK4hSajaRVvdd99caZP13daqLV9v9VfH6AlMNUtW4g7x4JeTbAdVqxu3m9psjByE6hWX0mPrp+8vEWVE0nFPxaqU6ojoXj7Me+yQRf0eE9a47qHAFbom5ghY1tTuo9tP5eR94JI5+ASkcYjbX2D5uecJflRYsXOVslqnDAV0ygRS0Sb0WcKbGGRft8T/Sx6W4yxI7/0d75mY631O2v5i+KO8YeAY+TjmyZ1m4uvRG1MGbGJUG967lYY+w1RWZLo72P9iv0cunBN2/rG6XviuwjxOiByFPTaoN/hS+LzrkjSsuo6kuEVcLdsYf5rRh750lQW96ncg0p7NxC02Bwnk7yQeI1Ay8ytvVG/CdGsNz1RMKnR5OsiU2h/RVMsGIuOb3ty7f7cOdHTfQEyG9yD3raiNHM75ttTBmR31Z7WCzDRdDNxdgZhymS+nDV+vUcnhgf9GOA3iqgoXAOBQIxfOauguR3Jc59RFcfdJ0A0wEHK7Iryt1OQ0rtUu0j7RJdsmQYmmzqrH08gHaMGJsPQlSQT92+cCoy39Y7UnA235mrQWIjdCqvI+dKIRgvJX5jhJmsRHnwRp/g4kmwqi4322Tb2tdvqqCvENcR0Wa6GR3Sl+Yc80OF6gvtkA64xVwPoFofh/FBTwr8YOWlZSNbjyPXadNdCI=</xenc:CipherValue></xenc:CipherData></xenc:EncryptedKey></ds:KeyInfo><xenc:CipherData xmlns:xenc="http://www.w3.org/2001/04/xmlenc#"><xenc:CipherValue>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</xenc:CipherValue></xenc:CipherData></xenc:EncryptedData></saml2:EncryptedAssertion></saml2p:Response></saml2p:ArtifactResponse></soap11:Body></soap11:Envelope>
ARTIFACT

my $cert1 = << 'CERT1';
-----BEGIN CERTIFICATE-----
MIIDEjCCAfqgAwIBAgIVAMECQ1tjghafm5OxWDh9hwZfxthWMA0GCSqGSIb3DQEB
CwUAMBYxFDASBgNVBAMMC3NhbWx0ZXN0LmlkMB4XDTE4MDgyNDIxMTQwOVoXDTM4
MDgyNDIxMTQwOVowFjEUMBIGA1UEAwwLc2FtbHRlc3QuaWQwggEiMA0GCSqGSIb3
DQEBAQUAA4IBDwAwggEKAoIBAQC0Z4QX1NFKs71ufbQwoQoW7qkNAJRIANGA4iM0
ThYghul3pC+FwrGv37aTxWXfA1UG9njKbbDreiDAZKngCgyjxj0uJ4lArgkr4AOE
jj5zXA81uGHARfUBctvQcsZpBIxDOvUUImAl+3NqLgMGF2fktxMG7kX3GEVNc1kl
bN3dfYsaw5dUrw25DheL9np7G/+28GwHPvLb4aptOiONbCaVvh9UMHEA9F7c0zfF
/cL5fOpdVa54wTI0u12CsFKt78h6lEGG5jUs/qX9clZncJM7EFkN3imPPy+0HC8n
spXiH/MZW8o2cqWRkrw3MzBZW3Ojk5nQj40V6NUbjb7kfejzAgMBAAGjVzBVMB0G
A1UdDgQWBBQT6Y9J3Tw/hOGc8PNV7JEE4k2ZNTA0BgNVHREELTArggtzYW1sdGVz
dC5pZIYcaHR0cHM6Ly9zYW1sdGVzdC5pZC9zYW1sL2lkcDANBgkqhkiG9w0BAQsF
AAOCAQEASk3guKfTkVhEaIVvxEPNR2w3vWt3fwmwJCccW98XXLWgNbu3YaMb2RSn
7Th4p3h+mfyk2don6au7Uyzc1Jd39RNv80TG5iQoxfCgphy1FYmmdaSfO8wvDtHT
TNiLArAxOYtzfYbzb5QrNNH/gQEN8RJaEf/g/1GTw9x/103dSMK0RXtl+fRs2nbl
D1JJKSQ3AdhxK/weP3aUPtLxVVJ9wMOQOfcy02l+hHMb6uAjsPOpOVKqi3M8XmcU
ZOpx4swtgGdeoSpeRyrtMvRwdcciNBp9UZome44qZAYH1iqrpmmjsfI9pJItsgWu
3kXPjhSfj1AJGR1l9JGvJrHki1iHTA==
-----END CERTIFICATE-----
CERT1

my $cert2 = << 'CERT2';
-----BEGIN CERTIFICATE-----
MIIDETCCAfmgAwIBAgIUZRpDhkNKl5eWtJqk0Bu1BgTTargwDQYJKoZIhvcNAQEL
BQAwFjEUMBIGA1UEAwwLc2FtbHRlc3QuaWQwHhcNMTgwODI0MjExNDEwWhcNMzgw
ODI0MjExNDEwWjAWMRQwEgYDVQQDDAtzYW1sdGVzdC5pZDCCASIwDQYJKoZIhvcN
AQEBBQADggEPADCCAQoCggEBAJrh9/PcDsiv3UeL8Iv9rf4WfLPxuOm9W6aCntEA
8l6c1LQ1Zyrz+Xa/40ZgP29ENf3oKKbPCzDcc6zooHMji2fBmgXp6Li3fQUzu7yd
+nIC2teejijVtrNLjn1WUTwmqjLtuzrKC/ePoZyIRjpoUxyEMJopAd4dJmAcCq/K
k2eYX9GYRlqvIjLFoGNgy2R4dWwAKwljyh6pdnPUgyO/WjRDrqUBRFrLQJorR2kD
c4seZUbmpZZfp4MjmWMDgyGM1ZnR0XvNLtYeWAyt0KkSvFoOMjZUeVK/4xR74F8e
8ToPqLmZEg9ZUx+4z2KjVK00LpdRkH9Uxhh03RQ0FabHW6UCAwEAAaNXMFUwHQYD
VR0OBBYEFJDbe6uSmYQScxpVJhmt7PsCG4IeMDQGA1UdEQQtMCuCC3NhbWx0ZXN0
LmlkhhxodHRwczovL3NhbWx0ZXN0LmlkL3NhbWwvaWRwMA0GCSqGSIb3DQEBCwUA
A4IBAQBNcF3zkw/g51q26uxgyuy4gQwnSr01Mhvix3Dj/Gak4tc4XwvxUdLQq+jC
cxr2Pie96klWhY/v/JiHDU2FJo9/VWxmc/YOk83whvNd7mWaNMUsX3xGv6AlZtCO
L3JhCpHjiN+kBcMgS5jrtGgV1Lz3/1zpGxykdvS0B4sPnFOcaCwHe2B9SOCWbDAN
JXpTjz1DmJO4ImyWPJpN1xsYKtm67Pefxmn0ax0uE2uuzq25h0xbTkqIQgJzyoE/
DPkBFK1vDkMfAW11dQ0BXatEnW7Gtkc0lh2/PIbHWj4AzxYMyBf5Gy6HSVOftwjC
voQR2qr2xJBixsg+MIORKtmKHLfU
-----END CERTIFICATE-----
CERT2

my @certs = ($cert2, $cert1);

$soap = Net::SAML2::Binding::SOAP->new(
        url      => $sso_url,
        key      => $sp->key,
        cert     => $sp->cert,
        idp_cert => \@certs,
    );

my $assertion =  $soap->handle_response($art_response);
}
done_testing;
