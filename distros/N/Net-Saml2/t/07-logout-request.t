use Test::Lib;
use Test::Net::SAML2;

use Net::SAML2::Protocol::LogoutRequest;

my %args = (
    issuer        => 'http://some/sp',
    destination   => 'http://some/idp',
    nameid        => 'name-to-log-out',
    session       => 'session-to-log-out',
    nameid_format => 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent',
);

my $lor = Net::SAML2::Protocol::LogoutRequest->new(%args);

isa_ok($lor, 'Net::SAML2::Protocol::LogoutRequest');

my $override = Sub::Override->override(
    'Net::SAML2::Protocol::LogoutRequest::issue_instant' =>
        sub { return 'foo' });


my $xml = $lor->as_xml;

my $xpath = get_xpath(
    $xml,
    samlp => 'urn:oasis:names:tc:SAML:2.0:protocol',
    saml  => 'urn:oasis:names:tc:SAML:2.0:assertion',
);

isa_ok($xpath, 'XML::LibXML::XPathContext');

test_xml_attribute_ok($xpath, '/samlp:LogoutRequest/@ID', qr/^NETSAML2_/);
test_xml_attribute_ok($xpath, '/samlp:LogoutRequest/@IssueInstant', 'foo');
test_xml_attribute_ok($xpath, '/samlp:LogoutRequest/saml:NameID/@Format',
    $args{nameid_format});

done_testing;
