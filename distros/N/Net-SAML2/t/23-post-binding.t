use strict;
use warnings;
use Test::Lib;
use Test::Net::SAML2;
use URI;
use MIME::Base64 qw/decode_base64/;

use Net::SAML2::IdP;
use Net::SAML2::Binding::Redirect;
use XML::Sig;

my $sp = net_saml2_sp();

my $metadata = path('t/idp-metadata.xml')->slurp;

my $idp = Net::SAML2::IdP->new_from_xml(
    xml    => $metadata,
    cacert => 't/net-saml2-cacert.pem'
);
isa_ok($idp, "Net::SAML2::IdP");

my $sso_url = $idp->sso_url($idp->binding('post'));
is(
    $sso_url,
    'http://sso.dev.venda.com/opensso/SSOPOST/metaAlias/idp',
    'POST URI is correct'
);

my $authnreq = $sp->authn_request(
    $idp->entityid,
    $idp->format('persistent')
)->as_xml;

my $post = $sp->sp_post_binding($idp, 'SAMLRequest');
isa_ok($post, 'Net::SAML2::Binding::POST');

my $post_request = $post->sign_xml($authnreq);

my $request = decode_base64($post_request);
my $xp = get_xpath(
    $request,
    saml2p => 'urn:oasis:names:tc:SAML:2.0:protocol',
    saml   => 'urn:oasis:names:tc:SAML:2.0:assertion',
);

test_xml_value_ok($xp, '/samlp:AuthnRequest/saml:Issuer', 'Some%20entity%20ID');

my $signer = XML::Sig->new();
ok($signer->verify($request), "Valid Signature");

my %logout_params;

my $logoutreq = $sp->logout_request(
    $idp->slo_url('urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST'),
    'timlegge@cpan.org',
    $idp->format || undef,
    '94750270472009384017107023022',
    \%logout_params,
)->as_xml;

$post = $sp->sp_post_binding($idp, 'SAMLRequest');

$post_request = $post->sign_xml($logoutreq);
$request = decode_base64($post_request);

$xp = get_xpath(
    $request,
    saml2p => 'urn:oasis:names:tc:SAML:2.0:protocol',
    saml   => 'urn:oasis:names:tc:SAML:2.0:assertion',
);
test_xml_value_ok($xp, '//samlp:SessionIndex', '94750270472009384017107023022');

$signer = XML::Sig->new();
ok($signer->verify($request), "Valid Signature");

done_testing;
