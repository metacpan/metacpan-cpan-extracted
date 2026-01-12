use strict;
use warnings;
use Test::Lib;
use Test::Net::SAML2;
use Net::SAML2::IdP;
use Test::Mock::One;

delete $ENV{'PERL_LWP_SSL_CA_FILE'};
delete $ENV{'HTTPS_CA_FILE'};
delete $ENV{'PERL_LWP_SSL_CA_PATH'};
delete $ENV{'HTTPS_CA_DIR'};

my $xml = <<XML;
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<EntityDescriptor entityID="http://sso.dev.venda.com/opensso" xmlns="urn:oasis:names:tc:SAML:2.0:metadata">
    <IDPSSODescriptor WantAuthnRequestsSigned="false" protocolSupportEnumeration="urn:oasis:names:tc:SAML:2.0:protocol">
        <KeyDescriptor use="signing">
            <ds:KeyInfo xmlns:ds="http://www.w3.org/2000/09/xmldsig#">
                <ds:X509Data>
                    <ds:X509Certificate>
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
                    </ds:X509Certificate>
                </ds:X509Data>
            </ds:KeyInfo>
        </KeyDescriptor>
        <ArtifactResolutionService index="0" isDefault="true" Binding="urn:oasis:names:tc:SAML:2.0:bindings:SOAP" Location="http://sso.dev.venda.com/opensso/ArtifactResolver/metaAlias/idp"/>
        <SingleLogoutService Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect" Location="http://sso.dev.venda.com/opensso/IDPSloRedirect/metaAlias/idp" ResponseLocation="http://sso.dev.venda.com/opensso/IDPSloRedirect/metaAlias/idp"/>
        <SingleLogoutService Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST" Location="http://sso.dev.venda.com/opensso/IDPSloPOST/metaAlias/idp" ResponseLocation="http://sso.dev.venda.com/opensso/IDPSloPOST/metaAlias/idp"/>
        <SingleLogoutService Binding="urn:oasis:names:tc:SAML:2.0:bindings:SOAP" Location="http://sso.dev.venda.com/opensso/IDPSloSoap/metaAlias/idp"/>
        <ManageNameIDService Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect" Location="http://sso.dev.venda.com/opensso/IDPMniRedirect/metaAlias/idp" ResponseLocation="http://sso.dev.venda.com/opensso/IDPMniRedirect/metaAlias/idp"/>
        <ManageNameIDService Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST" Location="http://sso.dev.venda.com/opensso/IDPMniPOST/metaAlias/idp" ResponseLocation="http://sso.dev.venda.com/opensso/IDPMniPOST/metaAlias/idp"/>
        <ManageNameIDService Binding="urn:oasis:names:tc:SAML:2.0:bindings:SOAP" Location="http://sso.dev.venda.com/opensso/IDPMniSoap/metaAlias/idp"/>
        <NameIDFormat>urn:oasis:names:tc:SAML:2.0:nameid-format:persistent</NameIDFormat>
        <NameIDFormat>urn:oasis:names:tc:SAML:2.0:nameid-format:transient</NameIDFormat>
        <NameIDFormat>urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress</NameIDFormat>
        <NameIDFormat>urn:oasis:names:tc:SAML:1.1:nameid-format:unspecified</NameIDFormat>
        <NameIDFormat>urn:oasis:names:tc:SAML:1.1:nameid-format:WindowsDomainQualifiedName</NameIDFormat>
        <NameIDFormat>urn:oasis:names:tc:SAML:2.0:nameid-format:kerberos</NameIDFormat>
        <NameIDFormat>urn:oasis:names:tc:SAML:1.1:nameid-format:X509SubjectName</NameIDFormat>
        <SingleSignOnService Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect" Location="http://sso.dev.venda.com/opensso/SSORedirect/metaAlias/idp"/>
        <SingleSignOnService Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST" Location="http://sso.dev.venda.com/opensso/SSOPOST/metaAlias/idp"/>
        <SingleSignOnService Binding="urn:oasis:names:tc:SAML:2.0:bindings:SOAP" Location="http://sso.dev.venda.com/opensso/SSOSoap/metaAlias/idp"/>
        <NameIDMappingService Binding="urn:oasis:names:tc:SAML:2.0:bindings:SOAP" Location="http://sso.dev.venda.com/opensso/NIMSoap/metaAlias/idp"/>
        <AssertionIDRequestService Binding="urn:oasis:names:tc:SAML:2.0:bindings:SOAP" Location="http://localhost:43312/opensso/AIDReqSoap/IDPRole/metaAlias/idp"/>
        <AssertionIDRequestService Binding="urn:oasis:names:tc:SAML:2.0:bindings:URI" Location="http://localhost:43312/opensso/AIDReqUri/IDPRole/metaAlias/idp"/>
    </IDPSSODescriptor>
</EntityDescriptor>
XML

my $idp = Net::SAML2::IdP->new_from_xml(
    xml    => $xml,
    cacert => 't/net-saml2-cacert.pem'
);

isa_ok($idp, "Net::SAML2::IdP");

my $redirect_binding = $idp->binding('redirect');
my $soap_binding     = $idp->binding('soap');

is(
    $redirect_binding,
    'urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect',
    "Has correct binding: HTTP-Redirect"
);
is(
    $soap_binding,
    'urn:oasis:names:tc:SAML:2.0:bindings:SOAP',
    "Has correct binding: SOAP"
);

is(
    $idp->sso_url($redirect_binding),
    'http://sso.dev.venda.com/opensso/SSORedirect/metaAlias/idp',
    'Has correct sso_url'
);
is(
    $idp->slo_url($redirect_binding),
    'http://sso.dev.venda.com/opensso/IDPSloRedirect/metaAlias/idp',
    'Has correct slo_url'
);
is(
    $idp->art_url($soap_binding),
    'http://sso.dev.venda.com/opensso/ArtifactResolver/metaAlias/idp',
    'Has correct art_url'
);

foreach my $use (keys %{$idp->certs}) {
    for my $cert (@{$idp->cert($use)}) {
        looks_like_a_cert($cert);
    }
};

is(
    $idp->entityid,
    'http://sso.dev.venda.com/opensso',
    "Has the correct entityid"
);

is(
    $idp->format('transient'),
    'urn:oasis:names:tc:SAML:2.0:nameid-format:transient',
    "has correct transient format"
);
is(
    $idp->format,
    'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent',
    'has correct persistent format'
);

{
    my $xml = path('t/idp-metadata2.xml')->slurp;
    my $idp = Net::SAML2::IdP->new_from_xml(
        xml    => $xml,
        cacert => 't/net-saml2-cacert.pem'
    );
    isa_ok($idp, "Net::SAML2::IdP");

    my $redirect_binding = $idp->binding('redirect');
    my $soap_binding     = $idp->binding('soap');

    is(
        $redirect_binding,
        'urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect',
        "Has correct binding: HTTP-Redirect"
    );
    is(
        $soap_binding,
        'urn:oasis:names:tc:SAML:2.0:bindings:SOAP',
        "Has correct binding: SOAP"
    );

    is(
        $idp->sso_url($redirect_binding),
        'http://sso.dev.venda.com/opensso/SSORedirect/metaAlias/idp',
        'Has correct sso_url'
    );
    is(
        $idp->slo_url($redirect_binding),
        'http://sso.dev.venda.com/opensso/IDPSloRedirect/metaAlias/idp',
        'Has correct slo_url'
    );
    is(
        $idp->art_url($soap_binding),
        'http://sso.dev.venda.com/opensso/ArtifactResolver/metaAlias/idp',
        'Has correct art_url'
    );

    foreach my $use (keys %{$idp->certs}) {
        for my $cert (@{$idp->cert($use)}) {
            looks_like_a_cert($cert);
        }
    };

    is(
        $idp->entityid,
        'http://sso.dev.venda.com/opensso',
        "Has the correct entityid"
    );

    is(
        $idp->format('transient'),
        'urn:oasis:names:tc:SAML:2.0:nameid-format:transient',
        "has correct transient format"
    );
    is(
        $idp->format,
        'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent',
        'has correct persistent format'
    );
}

{ my $xml = <<XML;
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<EntityDescriptor entityID="http://sso.dev.venda.com/opensso" xmlns="urn:oasis:names:tc:SAML:2.0:metadata">
    <IDPSSODescriptor WantAuthnRequestsSigned="false" protocolSupportEnumeration="urn:oasis:names:tc:SAML:2.0:protocol">
        <KeyDescriptor use="signing">
            <ds:KeyInfo xmlns:ds="http://www.w3.org/2000/09/xmldsig#">
                <ds:X509Data>
                    <ds:X509Certificate>
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
                    </ds:X509Certificate>
                </ds:X509Data>
            </ds:KeyInfo>
        </KeyDescriptor>
        <ArtifactResolutionService index="0" isDefault="true" Binding="urn:oasis:names:tc:SAML:2.0:bindings:SOAP" Location="http://sso.dev.venda.com/opensso/ArtifactResolver/metaAlias/idp"/>
        <SingleLogoutService Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect" Location="http://sso.dev.venda.com/opensso/IDPSloRedirect/metaAlias/idp" ResponseLocation="http://sso.dev.venda.com/opensso/IDPSloRedirect/metaAlias/idp"/>
        <SingleLogoutService Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST" Location="http://sso.dev.venda.com/opensso/IDPSloPOST/metaAlias/idp" ResponseLocation="http://sso.dev.venda.com/opensso/IDPSloPOST/metaAlias/idp"/>
        <SingleLogoutService Binding="urn:oasis:names:tc:SAML:2.0:bindings:SOAP" Location="http://sso.dev.venda.com/opensso/IDPSloSoap/metaAlias/idp"/>
        <ManageNameIDService Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect" Location="http://sso.dev.venda.com/opensso/IDPMniRedirect/metaAlias/idp" ResponseLocation="http://sso.dev.venda.com/opensso/IDPMniRedirect/metaAlias/idp"/>
        <ManageNameIDService Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST" Location="http://sso.dev.venda.com/opensso/IDPMniPOST/metaAlias/idp" ResponseLocation="http://sso.dev.venda.com/opensso/IDPMniPOST/metaAlias/idp"/>
        <ManageNameIDService Binding="urn:oasis:names:tc:SAML:2.0:bindings:SOAP" Location="http://sso.dev.venda.com/opensso/IDPMniSoap/metaAlias/idp"/>
        <SingleSignOnService Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect" Location="http://sso.dev.venda.com/opensso/SSORedirect/metaAlias/idp"/>
        <SingleSignOnService Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST" Location="http://sso.dev.venda.com/opensso/SSOPOST/metaAlias/idp"/>
        <SingleSignOnService Binding="urn:oasis:names:tc:SAML:2.0:bindings:SOAP" Location="http://sso.dev.venda.com/opensso/SSOSoap/metaAlias/idp"/>
        <NameIDMappingService Binding="urn:oasis:names:tc:SAML:2.0:bindings:SOAP" Location="http://sso.dev.venda.com/opensso/NIMSoap/metaAlias/idp"/>
        <AssertionIDRequestService Binding="urn:oasis:names:tc:SAML:2.0:bindings:SOAP" Location="http://localhost:43312/opensso/AIDReqSoap/IDPRole/metaAlias/idp"/>
        <AssertionIDRequestService Binding="urn:oasis:names:tc:SAML:2.0:bindings:URI" Location="http://localhost:43312/opensso/AIDReqUri/IDPRole/metaAlias/idp"/>
    </IDPSSODescriptor>
</EntityDescriptor>
XML

    my $idp = Net::SAML2::IdP->new_from_xml(
        xml    => $xml,
        cacert => 't/net-saml2-cacert.pem'
    );

    is($idp->format, undef, "No default format thus no format set");

}

{
    my $xml = path('t/idp-metadata2.xml')->slurp;
    my $override = Sub::Override->new(
        'LWP::UserAgent::request' => sub {
            return Test::Mock::One->new(
                is_success      => 1,
                decoded_content => $xml
            )
        }
    );

    my $idp = Net::SAML2::IdP->new_from_url(
        url    => 'https://foo.example.com/auth/saml',
        cacert => 't/net-saml2-cacert.pem'
    );

    isa_ok($idp, "Net::SAML2::IdP");

    my $redirect_binding = $idp->binding('redirect');
    my $soap_binding     = $idp->binding('soap');

    is(
        $redirect_binding,
        'urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect',
        "Has correct binding: HTTP-Redirect"
    );
    is(
        $soap_binding,
        'urn:oasis:names:tc:SAML:2.0:bindings:SOAP',
        "Has correct binding: SOAP"
    );

    is(
        $idp->sso_url($redirect_binding),
        'http://sso.dev.venda.com/opensso/SSORedirect/metaAlias/idp',
        'Has correct sso_url'
    );
    is(
        $idp->slo_url($redirect_binding),
        'http://sso.dev.venda.com/opensso/IDPSloRedirect/metaAlias/idp',
        'Has correct slo_url'
    );
    is(
        $idp->art_url($soap_binding),
        'http://sso.dev.venda.com/opensso/ArtifactResolver/metaAlias/idp',
        'Has correct art_url'
    );

    foreach my $use (keys %{$idp->certs}) {
        for my $cert (@{$idp->cert($use)}) {
            looks_like_a_cert($cert);
        }
    };

    is(
        $idp->entityid,
        'http://sso.dev.venda.com/opensso',
        "Has the correct entityid"
    );

    is(
        $idp->format('transient'),
        'urn:oasis:names:tc:SAML:2.0:nameid-format:transient',
        "has correct transient format"
    );
    is(
        $idp->format,
        'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent',
        'has correct persistent format'
    );
}

{

    my $xml = path('t/idp-metadata2.xml')->slurp;
    my $ua;
    my $override = Sub::Override->new(
        'LWP::UserAgent::request' => sub {
            $ua = shift;
            return Test::Mock::One->new(
                is_success      => 1,
                decoded_content => $xml
            )
        }
    );

    Net::SAML2::IdP->new_from_url(
        url    => 'https://foo.example.com/auth/saml',
        cacert => 't/net-saml2-cacert.pem'
    );

    like($ua->agent, qr/^libwww-perl\/\d+\.\d+/, "Is the default user agent");

    Net::SAML2::IdP->new_from_url(
        url    => 'https://foo.example.com/auth/saml',
        cacert => 't/net-saml2-cacert.pem',
        ssl_opts => { verify_hostname => 1, SSL_ca_file => '/path/to/ca' },
    );
    like($ua->agent, qr/^libwww-perl\/\d+\.\d+/, "Is the default user agent");
    my %opts = map { $_ => $ua->ssl_opts($_) } $ua->ssl_opts;
    cmp_deeply(\%opts,
        {
            verify_hostname => 1,
            SSL_ca_file     => '/path/to/ca',
        },
        ".. and has the correct SSL options"
    );

    Net::SAML2::IdP->new_from_url(
        url    => 'https://foo.example.com/auth/saml',
        cacert => 't/net-saml2-cacert.pem',
        ua => LWP::UserAgent->new(
            agent    => "Foo",
            ssl_opts => { verify_hostname => 0 }
        ),
    );
    is($ua->agent, "Foo", "We have our custom agent");
    %opts = map { $_ => $ua->ssl_opts($_) } $ua->ssl_opts;
    cmp_deeply(\%opts,
        {
            verify_hostname => 0,
        },
        ".. and has the correct SSL options"
    );

}

{
    my $xml = path('t/idp-metadata2.xml')->slurp;
    my $ua;
    my $override = Sub::Override->new(
        'LWP::UserAgent::request' => sub {
            $ua = shift;
            return Test::Mock::One->new(
                is_success      => 0,
                message         => "I'm a teapot",
                code            => 418,
            )
        }
    );
    throws_ok(
        sub {
            Net::SAML2::IdP->new_from_url(
                url    => 'https://foo.example.com/auth/saml',
                cacert => 't/net-saml2-cacert.pem',
            );
        },
        qr/Error retrieving metadata: I'm a teapot \(418\)/,
        "Unable to get metadata because we're talking to a teapot",
    );
}

{
    my $xml = path('t/data/idp-metadata-signing-encryption.xml')->slurp;
    my $idp = Net::SAML2::IdP->new_from_xml(
        xml => $xml,
    );

    isa_ok($idp, "Net::SAML2::IdP");
    is(@{$idp->cert('signing')}, 1, 'Got one signing cert');
    is(@{$idp->cert('encryption')}, 1, 'Got one encryption cert');
}

{
    my $xml = path('t/data/idp-metadata-multiple-invalid-use.xml')->slurp;
    my $idp = Net::SAML2::IdP->new_from_xml(xml => $xml);
    is(@{$idp->cert('signing')}, 1, 'Got one signing cert');
    is(@{$idp->cert('encryption')}, 2, 'Got two encryption certs');
}

done_testing;
