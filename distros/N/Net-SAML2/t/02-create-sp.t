use strict;
use warnings;
use Test::Lib;
use Test::Net::SAML2;
use URN::OASIS::SAML2 qw(:bindings :urn);

{
    my $sp = net_saml2_sp(
        authnreq_signed        => 0,
        want_assertions_signed => 0,
        slo_url_post           => '/sls-post-response',
        slo_url_soap           => '/slo-soap',
    );

    my $xml = $sp->metadata;
    like($xml, qr/^\<\?xml version="1.0" encoding="UTF-8"\?\>/, "Have XML version declaration");

    my $xpath = get_xpath(
        $xml,
        md => URN_METADATA,
        ds => URN_SIGNATURE,
    );

    my $node
        = get_single_node_ok($xpath,
        '//md:EntityDescriptor/md:SPSSODescriptor');
    is($node->getAttribute('WantAssertionsSigned'), 'false',
        'Wants assertions to be signed');
    is(
        $node->getAttribute('AuthnRequestsSigned'), 'false',
        '.. and also authn requests to be signed'
    );

    my @ssos
        = $xpath->findnodes(
        '//md:EntityDescriptor/md:SPSSODescriptor/md:AssertionConsumerService'
        );

    if (is(@ssos, 2, "Got two assertionConsumerService(s)")) {
        is(
            $ssos[0]->getAttribute('Binding'),
            'urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST',
            "Returns the correct binding: HTTP-POST"
        );
        is(
            $ssos[1]->getAttribute('Binding'),
            'urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Artifact',
            "Returns the correct binding: HTTP-Artifact"
        );
    }

    {
        my $node = get_single_node_ok($xpath,
            '//md:SingleLogoutService[@Binding="urn:oasis:names:tc:SAML:2.0:bindings:SOAP"]'
        );
        is(
            $node->getAttribute('Location'),
            'http://localhost:3000/slo-soap',
            ".. with the correct location"
        );

        $node = get_single_node_ok($xpath,
            '//md:SingleLogoutService[@Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST"]'
        );
        is(
            $node->getAttribute('Location'),
            'http://localhost:3000/sls-post-response',
            ".. with the correct location"
        );
    }


    my $root_node = get_single_node_ok($xpath, '/md:EntityDescriptor');
    my $signature_node = $root_node->firstChild;
    is($signature_node->nodeName(),
        'dsig:Signature', "First node is the signature");

    is(
        'e73560b0e23602121aedc55bcb1ca637',
        $sp->key_name('signing'),
        "Got a key name for the signing key"
    );
    is(
        undef,
        $sp->key_name('encryption'),
        "... and there is no encryption key name"
    );

}

{
    my $sp    = net_saml2_sp(sign_metadata => 0);
    my $xml = $sp->metadata;
    like($xml, qr/^\<\?xml version="1.0" encoding="UTF-8"\?\>/, "Have XML version declaration");

    my $xpath = get_xpath(
        $xml,
        md => URN_METADATA,
        ds => URN_SIGNATURE,
    );

    my $nodes = $xpath->findnodes('//ds:Signature');
    is($nodes->size(), 0, "We don't have any ds:Signature present");

}

{
    my $sp = net_saml2_sp();

    my $xpath = get_xpath(
        $sp->metadata,
        md => URN_METADATA,
        ds => URN_SIGNATURE,
    );

    my $node = get_single_node_ok($xpath, '/md:EntityDescriptor');
    is(
        $node->getAttribute('entityID'),
        'Some entity ID',
        '.. has the correct entity ID'
    );

    ok($node->getAttribute('ID'), '.. has an ID');

    {
        # Test ContactPerson
        my $node = get_single_node_ok($xpath, '/node()/md:ContactPerson');
        my $p    = $node->nodePath();

        my $company = get_single_node_ok($xpath, "$p/md:Company");
        is(
            $company->textContent,
            'Net::SAML2::SP testsuite',
            "Got the correct company name for the contact person"
        );

        my $email = get_single_node_ok($xpath, "$p/md:EmailAddress");
        is($email->textContent, 'test@example.com',
            ".. and the correct email");
    }

    {
        # Test Organisation
        my $node = get_single_node_ok($xpath, '/node()/md:Organization');
        my $p    = $node->nodePath();

        my $name = get_single_node_ok($xpath, "$p/md:OrganizationName");
        is($name->textContent, 'Net::SAML2::SP',
            "Got the correct company name");

        my $display_name
            = get_single_node_ok($xpath, "$p/md:OrganizationDisplayName");
        is(
            $display_name->textContent,
            'Net::SAML2::SP testsuite',
            ".. and the correct display name"
        );

        my $url = get_single_node_ok($xpath, "$p/md:OrganizationURL");
        is($url->textContent, 'http://www.example.com',
            ".. and the correct URI");
    }

    {
        # Test SPSSODescriptor
        my $node = get_single_node_ok($xpath, '/node()/md:SPSSODescriptor');
        is($node->getAttribute('AuthnRequestsSigned'),
            'true', '.. and authn request needs signing');
        is($node->getAttribute('WantAssertionsSigned'),
            'true', '.. as does assertions');
        is($node->getAttribute('errorURL'),
            'http://localhost:3000/error', 'Got the correct error URI');
        is(
            $node->getAttribute('protocolSupportEnumeration'),
            'urn:oasis:names:tc:SAML:2.0:protocol',
            'Got the protocolSupportEnumeration'
        );

        my $p = $node->nodePath();

        my $kd = get_single_node_ok($xpath, "$p/md:KeyDescriptor");

        ok(!$kd->getAttribute('use'), "No key descriptor");

        ok(
            !$kd->getAttribute('encryption'),
            "Key descriptor encryption is undefined"
        );

        my $ki = get_single_node_ok($xpath, $kd->nodePath() . "/ds:KeyInfo");

        my $cert = get_single_node_ok($xpath,
            $ki->nodePath() . "/ds:X509Data/ds:X509Certificate");
        ok($cert->textContent, "And we have the certificate data");

        my $keyname
            = get_single_node_ok($xpath, $ki->nodePath() . "/ds:KeyName");
        ok($keyname->textContent, "... and we have a key name");
    }

    # These nodes are missing
    ok(
        !$xpath->findnodes(
            '//md:SingleLogoutService[@Binding="urn:oasis:names:tc:SAML:2.0:bindings:SOAP"]'
        ),
        "No node found for slo_url_soap"
    );
    ok(
        !$xpath->findnodes(
            '//md:SingleLogoutService[@Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST"]'
        ),
        "No node found for slo_url_post"
    );

    {
        # Test Signature
        my $node = get_single_node_ok($xpath, '/node()/ds:Signature');

    }

}
{
    my $sp = net_saml2_sp( ( encryption_key => 't/sign-nopw-cert.pem' ) );

    my $xpath = get_xpath(
        $sp->metadata,
        md => URN_METADATA,
        ds => URN_SIGNATURE,
    );

    # Test SPSSODescriptor
    my $node = get_single_node_ok($xpath, '/node()/md:SPSSODescriptor');
    my $p = $node->nodePath();

    my $kd = get_single_node_ok($xpath, "$p/md:KeyDescriptor[\@use='signing']");

    is($kd->getAttribute('use'),
        "signing", "Key descriptor is there for signing");

    $kd = get_single_node_ok($xpath, "$p/md:KeyDescriptor[\@use='encryption']");

    is($kd->getAttribute('use'),
        "encryption", "Key descriptor is there for encryption");

    is(
        'e73560b0e23602121aedc55bcb1ca637',
        $sp->key_name('signing'),
        "Got a key name for the signing key"
    );
    is(
        'e73560b0e23602121aedc55bcb1ca637',
        $sp->key_name('encryption'),
        "... and we also have a encryption key name"
    );

}

{

    my $sp = net_saml2_sp(
        single_logout_service => [
            {
                Binding  => BINDING_HTTP_POST,
                Location => 'https://foo.example.com/slo-http-post'
            }
        ],
        assertion_consumer_service => [
            {
                Binding  => BINDING_HTTP_POST,
                Location => 'https://foo.example.com/acs-http-post',
            },
            {
                Binding  => BINDING_HTTP_ARTIFACT,
                Location => 'https://foo.example.com/acs-http-artifact',
                isDefault => 'true'
            }
        ],
        error_url => 'https://foo.example.com/error-url',
    );

    my $xpath = get_xpath(
        $sp->metadata,
        md => URN_METADATA,
        ds => URN_SIGNATURE,
    );


    # Test SPSSODescriptor
    my $node = get_single_node_ok($xpath, '//md:SPSSODescriptor');
    is($node->getAttribute('errorURL'),
        'https://foo.example.com/error-url', 'Got the correct error URI');

    my $path = $node->nodePath;

    my @ssos = $xpath->findnodes("$path/md:AssertionConsumerService");

    if (is(@ssos, 2, "Got two assertionConsumerService(s)")) {

        is(
            $ssos[0]->getAttribute('Binding'),
            BINDING_HTTP_POST,
            "Returns the correct binding: HTTP-POST"
        );
        is($ssos[0]->getAttribute('isDefault'),
            undef, "... and doesn't have a default");

        is($ssos[0]->getAttribute('index'), 1,
            "... and has the correct index");

        is(
            $ssos[1]->getAttribute('Binding'),
            BINDING_HTTP_ARTIFACT,
            "Returns the correct binding: HTTP-Artifact"
        );

        is($ssos[1]->getAttribute('isDefault'),
            'true', "... and is the default");

        is($ssos[1]->getAttribute('index'), 2,
            "... and has the correct index");
    }

    {
        my @warns;
        local $SIG{__WARN__} = sub { push(@warns, shift); };
        my $default = $sp->get_default_assertion_service;

        is(@warns, 0, "No warnings for isDefault checks");

        is($default->{Binding}, BINDING_HTTP_ARTIFACT,
            "We found the default assertion service");
        is($default->{Location}, 'https://foo.example.com/acs-http-artifact',
            "... with the correct URI");
        is($default->{index}, 2, "... and index");

    }

    {
        my $sp = net_saml2_sp(
            single_logout_service => [
                {
                    Binding  => BINDING_HTTP_POST,
                    Location => 'https://foo.example.com/slo-http-post'
                }
            ],
            assertion_consumer_service => [
                {
                    Binding  => BINDING_HTTP_POST,
                    Location => 'https://foo.example.com/acs-http-post',
                    isDefault => 'false',
                },
                {
                    Binding  => BINDING_HTTP_ARTIFACT,
                    Location => 'https://foo.example.com/acs-http-artifact',
                }
            ],
            error_url => 'https://foo.example.com/error-url',
        );

        my $default = $sp->get_default_assertion_service;
        cmp_deeply(
            $default,
            {
                'Binding'   => BINDING_HTTP_ARTIFACT,
                'Location'  => 'https://foo.example.com/acs-http-artifact',
                'index'     => 2,
            },
            "We have a default assertion service"
        );
    }
    {
        my $sp = net_saml2_sp(
            single_logout_service => [
                {
                    Binding  => BINDING_HTTP_POST,
                    Location => 'https://foo.example.com/slo-http-post'
                }
            ],
            assertion_consumer_service => [
                {
                    Binding  => BINDING_HTTP_POST,
                    Location => 'https://foo.example.com/acs-http-post',
                    isDefault => 'false',
                },
                {
                    Binding  => BINDING_HTTP_ARTIFACT,
                    Location => 'https://foo.example.com/acs-http-artifact',
                    isDefault => 'false',
                }
            ],
            error_url => 'https://foo.example.com/error-url',
        );

        my $default = $sp->get_default_assertion_service;
        cmp_deeply(
            $default,
            {
                Binding   => BINDING_HTTP_POST,
                Location  => 'https://foo.example.com/acs-http-post',
                index     => 1,
                isDefault => 'false',
            },
            "We have a default assertion service"
        );
    }

    {
        my $sp = net_saml2_sp(
            single_logout_service => [],
        );

        my $xpath = get_xpath(
            $sp->metadata,
            md => URN_METADATA,
            ds => URN_SIGNATURE,
        );

        my $nodes = $xpath->findnodes('//md:SingleLogoutService');
        is($nodes->size, 0, "No single logout service generated");

        $sp = net_saml2_sp();

        $xpath = get_xpath(
            $sp->metadata,
            md => URN_METADATA,
            ds => URN_SIGNATURE,
        );

        $nodes = $xpath->findnodes('//md:SingleLogoutService');
        is($nodes->size, 0, "No single logout service generated without arguments");

    }

    throws_ok(
        sub {
            my $sp = net_saml2_sp(
                single_logout_service => [],
                assertion_consumer_service => [],
            );
        },
        qr/You don't have any Assertion Consumer Services configured/,
        "Needs at least one ASC",
    );
}

{
    my $consuming_index = Net::SAML2::AttributeConsumingService->new(
        service_name => 'Net::SAML2 testsuite',
        index        => 1,
        attributes   => [
            Net::SAML2::RequestedAttribute->new(
                friendly_name => 'foo',
                name          => 'urn:foo:bar',
                name_format   => 'xx',
                required      => 1,
            ),
        ],
    );

    my $sp = net_saml2_sp(attribute_consuming_service => $consuming_index,);

    my $xpath = get_xpath(
        $sp->metadata,
        md => URN_METADATA,
        ds => URN_SIGNATURE,
    );

    my $node = get_single_node_ok($xpath, '//md:SPSSODescriptor');
    my $acs  = get_single_node_ok($node,  '//md:AttributeConsumingService');

    is($acs->getAttribute('index'),     1, ".. index is 1");
    is($acs->getAttribute('isDefault'), 'false', "Not the default");


    my @child = $acs->childNodes();
    is(@child,              2,                "Have 2 children");
    is($child[0]->nodeName, "md:ServiceName", "Service name node found");
    is(
        $child[0]->textContent,
        'Net::SAML2 testsuite',
        ".. with the correct value"
    );
    is($child[0]->getAttribute("xml:lang"),
        "en", ".. and xml:lang is set");

    is($child[1]->nodeName, "md:RequestedAttribute",
        "Requested attribute found");
    is($child[1]->getAttribute('FriendlyName'),
        'foo', ".. with the correct friendly name");
    is($child[1]->getAttribute('Name'),       'urn:foo:bar', ".. and name");
    is($child[1]->getAttribute('isRequired'), 'true', ".. and requiredness");
}

{
    my $sp = net_saml2_sp();

    my @warns;
    local $SIG{__WARN__} = sub { push(@warns, shift); };
    my $id = $sp->id;
    is($id, $sp->issuer, "id is still the issuer");
    cmp_deeply(
        \@warns,
        ["Net::SAML2 deprecation warning: id() has been renamed to issuer()\n"],
        "We have our deprecation warning"
    );
}

done_testing;
