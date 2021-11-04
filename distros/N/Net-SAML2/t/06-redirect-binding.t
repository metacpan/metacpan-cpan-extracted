use Test::Lib;
use Test::Net::SAML2;

use Net::SAML2::IdP;

my $sp = net_saml2_sp();

my $metadata = path('t/idp-metadata.xml')->slurp;

my $idp = Net::SAML2::IdP->new_from_xml(
    xml    => $metadata,
    cacert => 't/cacert.pem'
);

isa_ok($idp, "Net::SAML2::IdP");

my $sso_url = $idp->sso_url($idp->binding('redirect'));
is(
    $sso_url,
    'http://sso.dev.venda.com/opensso/SSORedirect/metaAlias/idp',
    'Redirect URI is correct'
);

my $authnreq = $sp->authn_request(
    $idp->entityid,
    $idp->format('persistent')
)->as_xml;

my $xp = get_xpath($authnreq);

my $redirect = $sp->sso_redirect_binding($idp, 'SAMLRequest');
isa_ok($redirect, 'Net::SAML2::Binding::Redirect');

my $location = $redirect->sign($authnreq, 'http://return/url');

# TODO: Use URI to grab the base URI and query params to check if
# everything exists

like(
    $location,
    qr#\Qhttp://sso.dev.venda.com/opensso/SSORedirect/metaAlias/idp?SAMLRequest=\E#,
    "location checks out"
);

my ($request, $relaystate) = $redirect->verify($location);

test_xml_attribute_ok($xp, '/saml2p:AuthnRequest/@ID', qr/^NETSAML2_/,
    "Found a requestID");

is($relaystate, 'http://return/url', "Relay state shows correct uri");

done_testing;
