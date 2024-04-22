use strict;
use warnings;
use Test::Lib;
use Test::Net::SAML2;

use Net::SAML2::Protocol::LogoutResponse;

my $lor = Net::SAML2::Protocol::LogoutResponse->new(
    issuer      => 'http://some/sp',
    destination => 'http://some/idp',
    status      => 'success',
    in_response_to => 'randomID',
);

isa_ok($lor, 'Net::SAML2::Protocol::LogoutResponse');

my $override = Sub::Override->override(
    'Net::SAML2::Protocol::LogoutResponse::issue_instant' =>
        sub { return 'foo' });

$override->override(
    'Net::SAML2::Protocol::LogoutResponse::id' => sub { return 'myid' });

my $xpath = get_xpath(
    $lor->as_xml,
    samlp => 'urn:oasis:names:tc:SAML:2.0:protocol',
    saml  => 'urn:oasis:names:tc:SAML:2.0:assertion',
);
isa_ok($xpath, 'XML::LibXML::XPathContext');

test_xml_attribute_ok($xpath, '/samlp:LogoutResponse/@ID',           'myid');
test_xml_attribute_ok($xpath, '/samlp:LogoutResponse/@IssueInstant', 'foo');
test_xml_attribute_ok($xpath, '/samlp:LogoutResponse/@InResponseTo', 'randomID');
test_xml_attribute_ok($xpath,
    '/samlp:LogoutResponse/samlp:Status/samlp:StatusCode/@Value', 'success');

done_testing;
