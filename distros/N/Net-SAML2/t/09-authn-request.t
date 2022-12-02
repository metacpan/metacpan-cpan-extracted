use strict;
use warnings;
use Test::Lib;
use Test::Net::SAML2;

use Net::SAML2::Protocol::AuthnRequest;
use Net::SAML2::XML::Sig;

my $ar = Net::SAML2::Protocol::AuthnRequest->new(
    issuer        => 'http://some/sp',
    destination   => 'http://some/idp',
    nameid_format => 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent',
    nameid_allow_create => 1,
);

isa_ok($ar, "Net::SAML2::Protocol::AuthnRequest");

my $override
    = Sub::Override->override(
    'Net::SAML2::Protocol::AuthnRequest::issue_instant' =>
        sub { return 'myissueinstant' });

my $xml = $ar->as_xml;

my $xp = get_xpath(
    $xml,
    samlp => 'urn:oasis:names:tc:SAML:2.0:protocol',
    saml  => 'urn:oasis:names:tc:SAML:2.0:assertion',
);

test_xml_attribute_ok($xp, '/samlp:AuthnRequest/@ID', qr/^NETSAML2_/);

test_xml_attribute_ok($xp,
    '/samlp:AuthnRequest/@IssueInstant',
    'myissueinstant'
);

test_xml_attribute_ok(
    $xp,
    '/samlp:AuthnRequest/samlp:NameIDPolicy/@Format',
    'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent'
);

test_xml_attribute_ok($xp,
    '/samlp:AuthnRequest/samlp:NameIDPolicy/@AllowCreate', '1');

test_xml_attribute_exists($xp, '/samlp:AuthnRequest/@ForceAuthn', 0);

test_xml_attribute_exists($xp, '/samlp:AuthnRequest/@IsPassive', 0);

my $signer = Net::SAML2::XML::Sig->new({
    key => 't/sign-nopw-cert.pem',
    cert => 't/sign-nopw-cert.pem',
});

isa_ok($signer, "Net::SAML2::XML::Sig");

my $signed = $signer->sign($xml);
ok($signed);

my $verify = $signer->verify($signed);
ok($verify);

$ar = Net::SAML2::Protocol::AuthnRequest->new(
    issuer        => 'http://some/sp',
    destination   => 'http://some/idp',
    nameid_format => 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent',
    nameid_allow_create => 1,
    force_authn   => '1',
    is_passive    => '1'

);

isa_ok($ar, "Net::SAML2::Protocol::AuthnRequest");

$xml = $ar->as_xml;

$xp = get_xpath(
    $xml,
    samlp => 'urn:oasis:names:tc:SAML:2.0:protocol',
    saml  => 'urn:oasis:names:tc:SAML:2.0:assertion',
);

test_xml_attribute_exists($xp, '/samlp:AuthnRequest/@ForceAuthn', 1);
test_xml_attribute_ok($xp, '/samlp:AuthnRequest/@ForceAuthn', 'true');

test_xml_attribute_exists($xp, '/samlp:AuthnRequest/@IsPassive', 1);
test_xml_attribute_ok($xp, '/samlp:AuthnRequest/@IsPassive', 'true');

$ar = Net::SAML2::Protocol::AuthnRequest->new(
    issuer        => 'http://some/sp',
    destination   => 'http://some/idp',
    nameid_format => 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent',
    nameid_allow_create => 1,
    force_authn   => '0',
    is_passive    => '0'

);

isa_ok($ar, "Net::SAML2::Protocol::AuthnRequest");

$xml = $ar->as_xml;

$xp = get_xpath(
    $xml,
    samlp => 'urn:oasis:names:tc:SAML:2.0:protocol',
    saml  => 'urn:oasis:names:tc:SAML:2.0:assertion',
);

test_xml_attribute_exists($xp, '/samlp:AuthnRequest/@ForceAuthn', 1);
test_xml_attribute_ok($xp, '/samlp:AuthnRequest/@ForceAuthn', 'false');

test_xml_attribute_exists($xp, '/samlp:AuthnRequest/@IsPassive', 1);
test_xml_attribute_ok($xp, '/samlp:AuthnRequest/@IsPassive', 'false');

my $sp = net_saml2_sp(
    authnreq_signed        => 0,
    want_assertions_signed => 0,
    slo_url_post           => '/sls-post-response',
    slo_url_soap           => '/slo-soap',
);

my %params = (
    force_authn => 1,
    is_passive => 0,
);

my $req = $sp->authn_request(
    $sp->id,
    '',
    %params,
);

$xml = $req->as_xml;

$xp = get_xpath(
    $xml,
    samlp => 'urn:oasis:names:tc:SAML:2.0:protocol',
    saml  => 'urn:oasis:names:tc:SAML:2.0:assertion',
);

test_xml_attribute_exists($xp, '/samlp:AuthnRequest/@ForceAuthn', 1);
test_xml_attribute_ok($xp, '/samlp:AuthnRequest/@ForceAuthn', 'true');

test_xml_attribute_exists($xp, '/samlp:AuthnRequest/@IsPassive', 1);
test_xml_attribute_ok($xp, '/samlp:AuthnRequest/@IsPassive', 'false');

$xml = $ar->as_xml;

done_testing;
