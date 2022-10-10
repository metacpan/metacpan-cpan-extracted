use strict;
use warnings;
use Test::Lib;
use Test::Net::SAML2;

use Net::SAML2::IdP;
use Net::SAML2::Binding::SOAP;
use Test::Mock::One;

use LWP::UserAgent;

my $sp = net_saml2_sp();

my $metadata = path('t/idp-metadata.xml')->slurp;

my $idp = Net::SAML2::IdP->new_from_xml(
    xml    => $metadata,
    cacert => 't/cacert.pem'
);
isa_ok($idp, "Net::SAML2::IdP");

my $slo_url = $idp->slo_url($idp->binding('soap'));
is(
    $slo_url,
    'http://sso.dev.venda.com/opensso/IDPSloSoap/metaAlias/idp',
    'SLO url is correct'
);

my $idp_cert;
foreach my $use (keys %{$idp->certs}) {
    for my $cert (@{$idp->cert($use)}) {
        $idp_cert = $cert;
        looks_like_a_cert($cert);
    }
};

my $nameid  = 'user-to-log-out';
my $session = 'session-to-log-out';

my $request
    = $sp->logout_request($idp->entityid, $nameid, $idp->format('persistent'),
    $session);

isa_ok($request, "Net::SAML2::Protocol::LogoutRequest");
my $request_xml = $request->as_xml;

my $xp = get_xpath($request_xml);
isa_ok($xp, "XML::LibXML::XPathContext");

my $ua   = LWP::UserAgent->new;
my $soap = $sp->soap_binding($ua, $slo_url, $idp_cert);
isa_ok($soap, "Net::SAML2::Binding::SOAP");

my $soap_req = $soap->create_soap_envelope($request_xml);

# TODO: set soap paths and check envelop and body
$xp = get_xpath($soap_req);
isa_ok($xp, "XML::LibXML::XPathContext");

my $xml = $soap->handle_request($soap_req);
like($xml, qr/\Q<samlp:LogoutRequest\E/, "Logout XML found");
$xp = get_xpath($xml);
isa_ok($xp, "XML::LibXML::XPathContext");

my $soaped_request = Net::SAML2::Protocol::LogoutRequest->new_from_xml(
    xml => $xml
);
isa_ok($soaped_request, 'Net::SAML2::Protocol::LogoutRequest');

is($soaped_request->session, $request->session,
    "SOAP session equals request session");
is($soaped_request->nameid, $request->nameid,
    "SOAP nameid equals request nameid");

{
    # Testing trust anchors of SAML
    # You can set various trust anchors of SAML so the response is checked
    # against some kind of anchor.
    my %anchors = (
        subject     => [qw(foo bar)],
        issuer      => 'Net::SAML2',
        issuer_hash => [
            'f1d2d2f924e986ac86fdf7b36c94bcdf32beec15',
            'e242ed3bffccdf271b7fbaf34ed72d089537b42f'
        ],
    );

    my $xml      = "<xml></xml>";
    my $override = Sub::Override->new(
        'Net::SAML2::Binding::SOAP::_get_saml_from_soap' => sub {
            return $xml;
        },
    );
    $override->override(
        'XML::Sig::new' => sub {
            return Test::Mock::One->new(
                subject     => 'foo',
                issuer      => 'Net::SAML2',
                issuer_hash => 'f1d2d2f924e986ac86fdf7b36c94bcdf32beec15',
            );
        }
    );

    foreach (keys %anchors) {
        my $soap = Net::SAML2::Binding::SOAP->new(
            url      => 'https://example.com/auth/saml',
            key      => $sp->key,
            cert     => $sp->cert,
            idp_cert => $idp_cert,
            anchors  => { $_ => $anchors{$_} }
        );
        isa_ok($soap, "Net::SAML2::Binding::SOAP");

        is($soap->handle_response('here be soap'),
            "<xml></xml>", "We got our XML, so we are verified");
    }

    my $soap = Net::SAML2::Binding::SOAP->new(
        url      => 'https://example.com/auth/saml',
        key      => $sp->key,
        cert     => $sp->cert,
        idp_cert => $idp_cert,
        anchors  => { subject => 'testsuite failure expected' }
    );

    throws_ok(
        sub {
            $soap->handle_response('here be failure');
        },
        qr/Could not verify trust anchors of certificate!/,
        "We cannot trust the anchor"
    )
}

done_testing;
