use Test::Lib;
use Test::Net::SAML2;

use Net::SAML2::Protocol::ArtifactResolve;

my $ar = Net::SAML2::Protocol::ArtifactResolve->new(
    issuer      => 'http://some/sp',
    destination => 'http://some/idp',
    artifact    => 'some-artifact',
);


isa_ok($ar, 'Net::SAML2::Protocol::ArtifactResolve');

my $override
    = Sub::Override->override(
    'Net::SAML2::Protocol::ArtifactResolve::issue_instant' =>
        sub { return 'myissueinstant' });

$override->override(
    'Net::SAML2::Protocol::ArtifactResolve::id' => sub { return 'myid' });

my $xml = $ar->as_xml;

my $xp = get_xpath(
    $xml,
    samlp => 'urn:oasis:names:tc:SAML:2.0:protocol',
    saml  => 'urn:oasis:names:tc:SAML:2.0:assertion',
);

test_xml_attribute_ok($xp, '/samlp:ArtifactResolve/@ID', 'myid');
test_xml_attribute_ok($xp, '/samlp:ArtifactResolve/@IssueInstant',
    'myissueinstant');

test_xml_value_ok($xp, '/samlp:ArtifactResolve/samlp:Artifact',
    'some-artifact',);

done_testing;
