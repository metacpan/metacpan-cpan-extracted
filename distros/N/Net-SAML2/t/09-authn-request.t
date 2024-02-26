use strict;
use warnings;
use Test::Lib;
use Test::Net::SAML2;

use Net::SAML2::Protocol::AuthnRequest;
use Net::SAML2::XML::Sig;

my $override
    = Sub::Override->override(
    'Net::SAML2::Protocol::AuthnRequest::issue_instant' =>
        sub { return 'myissueinstant' });

$override->override('Net::SAML2::Protocol::AuthnRequest::_build_id' =>
        sub { return 'NETSAML2_fake_id' });

{
    my ($ar, $xp) = net_saml2_authnreq(
        nameid        => 'mynameid',
        nameidpolicy_format =>
            'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent',
        nameid_allow_create  => 1,
        issuer_namequalifier => 'bar',
        issuer_format        => 'foo',
    );

    my %attributes = (
        Destination  => 'http://some/idp',
        ID           => 'NETSAML2_fake_id',
        IssueInstant => 'myissueinstant',
        Version      => '2.0',
    );

    test_node_attributes_ok($xp, '/samlp:AuthnRequest', \%attributes);

    my $node = get_single_node_ok($xp, '/samlp:AuthnRequest/saml:Issuer');
    is($node->textContent, 'http://some/sp', '... and has the correct value');
    is($node->getAttribute('Format'), 'foo', '.. and Format attribute is ok');
    is($node->getAttribute('NameQualifier'),
        'bar', ".. and NameQualifier attribute is ok");

    test_xml_attribute_ok($xp,
        '/samlp:AuthnRequest/saml:Subject/saml:NameID/@NameQualifier',
        'mynameid');

    %attributes = (
        Format      => 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent',
        AllowCreate => 1,
    );

    test_node_attributes_ok($xp, '/samlp:AuthnRequest/samlp:NameIDPolicy',
        \%attributes);

    ok(!$xp->exists('/samlp:AuthnRequest/samlp:RequestedAuthnContext'),
        "We don't have RequestedAuthnContext");

    ### TODO: Does this really belong here?
    my $signer = Net::SAML2::XML::Sig->new(
        {
            key  => 't/sign-nopw-cert.pem',
            cert => 't/sign-nopw-cert.pem',
        }
    );

    isa_ok($signer, "Net::SAML2::XML::Sig");

    my $signed = $signer->sign($xp->getContextNode->toString);
    ok($signed, "Signed with XML::Sig");

    my $verify = $signer->verify($signed);
    ok($verify, "Verified with XML::Sig");
    ### END TODO
}


{
    my ($ar, $xp) = net_saml2_authnreq(
        force_authn => '1',
        is_passive  => '1'
    );
    my %attributes = (
        Destination  => ignore(),
        ForceAuthn   => 'true',
        ID           => ignore(),
        IsPassive    => 'true',
        IssueInstant => 'myissueinstant',
        Version      => '2.0',
    );
    test_node_attributes_ok($xp, '/samlp:AuthnRequest', \%attributes);
}

{
    my ($ar, $xp) = net_saml2_authnreq(
        force_authn => '0',
        is_passive  => '0'
    );

    my %attributes = (
        Destination  => ignore(),
        ID           => ignore(),
        IssueInstant => ignore(),
        Version      => ignore(),
        ForceAuthn   => 'false',
        IsPassive    => 'false',
    );
    test_node_attributes_ok($xp, '/samlp:AuthnRequest', \%attributes);
}

{

    my ($ar, $xp) = net_saml2_authnreq(
        assertion_url    => 'https://foo.bar/assertion',
        assertion_index  => 1,
        attribute_index  => 42,
        protocol_binding => 'HTTP-POST',
    );

    my %attributes = (
        Destination                    => ignore(),
        ID                             => ignore(),
        IssueInstant                   => ignore(),
        Version                        => ignore(),
        AssertionConsumerServiceURL    => 'https://foo.bar/assertion',
        AssertionConsumerServiceIndex  => 1,
        AttributeConsumingServiceIndex => 42,
        ProtocolBinding => 'urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST',
    );

    test_node_attributes_ok($xp, '/samlp:AuthnRequest', \%attributes);

}

{
    my ($ar, $xp) = net_saml2_authnreq(AuthnContextClassRef => [qw(foo bar)],);

    my @nodes
        = $xp->findnodes(
        '/samlp:AuthnRequest/samlp:RequestedAuthnContext/saml:AuthnContextClassRef'
        );
    is(@nodes, 2, "and has two AuthnContextClassRef nodes");

    is($nodes[0]->textContent(),
        "foo", "... and the correct content for node 1");
    is($nodes[1]->textContent(),
        "bar", "... and the correct content for node 2");
}

{
    my ($ar, $xp) = net_saml2_authnreq(AuthnContextDeclRef => [qw(foo bar)],);

    my @nodes
        = $xp->findnodes(
        '/samlp:AuthnRequest/samlp:RequestedAuthnContext/saml:AuthnContextDeclRef'
        );
    is(@nodes, 2, "and has two AuthnContextDeclRef nodes");

    is($nodes[0]->textContent(),
        "foo", "... and the correct content for node 1");
    is($nodes[1]->textContent(),
        "bar", "... and the correct content for node 2");
}

{

    my $sp = net_saml2_sp(
        authnreq_signed        => 0,
        want_assertions_signed => 0,
        slo_url_post           => '/sls-post-response',
        slo_url_soap           => '/slo-soap',
    );

    my %params = (
        force_authn => 1,
        is_passive  => 0,
    );

    my $req = $sp->authn_request($sp->issuer, '', %params,);

    my $xp = get_xpath(
        $req->as_xml,
        samlp => 'urn:oasis:names:tc:SAML:2.0:protocol',
        saml  => 'urn:oasis:names:tc:SAML:2.0:assertion',
    );
}

{

    my ($ar, $xp) = net_saml2_authnreq(
        identity_providers => [qw(one two three)]
    );

    my $nodes = $xp->findnodes(
        '/samlp:AuthnRequest/samlp:Scoping/samlp:IDPList/samlp:IDPEntry');
    is($nodes->size, 3, "Found three IDP entries");

    cmp_deeply([$nodes->map(sub { return $_->getAttribute('ProviderID') })],
        [qw(one two three)], "... and the correct provider IDs found");

}

done_testing;
