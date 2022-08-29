use strict;
use warnings;
use Test::Lib;
use Test::Net::SAML2;
use URN::OASIS::SAML2 qw(:urn);

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
    samlp => URN_PROTOCOL,
    saml  => URN_ASSERTION,
);

isa_ok($xpath, 'XML::LibXML::XPathContext');

test_xml_attribute_ok($xpath, '/samlp:LogoutRequest/@ID', qr/^NETSAML2_/);
test_xml_attribute_ok($xpath, '/samlp:LogoutRequest/@IssueInstant', 'foo');

my $name_id = get_single_node_ok($xpath, '/samlp:LogoutRequest/saml:NameID');
is($name_id->getAttribute('Format'), $args{nameid_format});

foreach (qw(NameQualifier SPNameQualifier SPProvidedID)) {
    is(
        $name_id->getAttribute($_),
        undef,
        "We don't have $_ as an attribute in the nameid"
    );
}

{
    my $lor = Net::SAML2::Protocol::LogoutRequest->new(%args,
        sp_provided_id => "Some provided ID");
    my $xml = $lor->as_xml;

    my $xpath = get_xpath(
        $xml,
        samlp => URN_PROTOCOL,
        saml  => URN_ASSERTION,
    );
    my $name_id = get_single_node_ok($xpath, '/samlp:LogoutRequest/saml:NameID');
    is(
        $name_id->getAttribute('SPProvidedID'),
        "Some provided ID",
        "We have the SP provided ID"
    );
}

{
    my $lor = Net::SAML2::Protocol::LogoutRequest->new(%args,
        include_name_qualifier => 1);
    my $xml = $lor->as_xml;

    my $xpath = get_xpath(
        $xml,
        samlp => URN_PROTOCOL,
        saml  => URN_ASSERTION,
    );
    my $name_id = get_single_node_ok($xpath, '/samlp:LogoutRequest/saml:NameID');
    is($name_id->getAttribute('SPNameQualifier'),
        $args{issuer}, "We the SPNameQualifier");
    is($name_id->getAttribute('NameQualifier'),
        $args{destination}, ".. and the NameQualifier");
}


done_testing;
