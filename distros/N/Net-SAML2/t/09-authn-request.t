use strict;
use warnings;
use Test::Lib;
use Test::Net::SAML2;

use Net::SAML2::Protocol::AuthnRequest;

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

my $signer = Net::SAML2::XML::Sig->new({
    canonicalizer => 'XML::CanonicalizeXML',
    key => 't/sign-nopw-cert.pem',
    cert => 't/sign-nopw-cert.pem',
});

isa_ok($signer, "Net::SAML2::XML::Sig");

my $signed = $signer->sign($xml);
ok($signed);

my $verify = $signer->verify($signed);
ok($verify);
done_testing;
