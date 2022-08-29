use strict;
use warnings;
use Test::Lib;
use Test::Net::SAML2;

use Net::SAML2::Protocol::ArtifactResolve;
use URN::OASIS::SAML2 qw(:urn);

my $ar = Net::SAML2::Protocol::ArtifactResolve->new(
    issuer      => 'http://some/sp',
    destination => 'http://some/idp',
    artifact    => 'some-artifact',
    provider    => 'Net-SAML2 Test',
);


isa_ok($ar, 'Net::SAML2::Protocol::ArtifactResolve');

my $override = Sub::Override->override(
    'Net::SAML2::Protocol::ArtifactResolve::issue_instant' => sub {
        return 'myissueinstant';
    }
);

$override->override(
    'Net::SAML2::Protocol::ArtifactResolve::id' => sub { return 'myid' }
);

my $xml = $ar->as_xml;

my $xp = get_xpath(
    $xml,
    samlp => URN_PROTOCOL,
    saml  => URN_ASSERTION,
);

test_xml_attribute_ok($xp, '/samlp:ArtifactResolve/@ID', 'myid');
test_xml_attribute_ok($xp, '/samlp:ArtifactResolve/@IssueInstant',
    'myissueinstant');

test_xml_value_ok($xp, '/samlp:ArtifactResolve/samlp:Artifact',
    'some-artifact');

test_xml_attribute_ok($xp, '/samlp:ArtifactResolve/@ProviderName',
    'Net-SAML2 Test');

{
    my $ar = Net::SAML2::Protocol::ArtifactResolve->new(
        issuer      => 'http://some/sp',
        destination => 'http://some/idp',
        artifact    => 'some-artifact',
    );

    my $xml = $ar->as_xml;
    my $xp = get_xpath(
        $xml,
        samlp => URN_PROTOCOL,
        saml  => URN_ASSERTION,
    );

    my $nodes = $xp->findnodes('/samlp:ArtifactResolve/@ProviderName');
    is($nodes->size, 0, "We don't have a provider name");

}

done_testing;
