use strict;
use warnings;
use Test::Lib;
use Test::Net::SAML2;
use URI;
use MIME::Base64 qw/decode_base64/;

use Net::SAML2::IdP;
use Net::SAML2::Binding::Redirect;
use XML::Sig;

# handle_response trust-anchor enforcement (security regression test).
#
# Without a pre-configured cacert / cert_text the verifier in
# Net::SAML2::Role::VerifyXML short-circuits and accepts the SAML
# response's embedded KeyInfo certificate - equivalent to no signature
# verification. handle_response refuses to enter that state unless the
# caller opts out explicitly via insecure_trust_embedded_cert => 1.
#
# Constructing the binding for signing-only use (sp_post_binding
# passes cert/key without cacert) is still permitted - the check
# lives at handle_response, not BUILD.

# Construction without trust anchors is fine (signing-only).
lives_ok(sub { Net::SAML2::Binding::POST->new; },
    'bare new() is permitted (signing-only callers do not call handle_response)');

# handle_response proceeds with a cacert or cert_text
throws_ok(sub { Net::SAML2::Binding::POST->new(cacert => 't/net-saml2-cacert.pem' )->handle_response(''); },
    qr/unable to parse xml/,
    'handle_response does not fail with a cacert');

# handle_response refuses to proceed without a trust anchor.
throws_ok(sub { Net::SAML2::Binding::POST->new->handle_response(''); },
    qr/requires 'cacert' or 'cert_text'/,
    'handle_response croaks without a cacert or cert_text');

# Explicit opt-out unblocks handle_response.
lives_ok(sub {
    my $b = Net::SAML2::Binding::POST->new(insecure_trust_embedded_cert => 1);
    # decode_base64('') -> '' -> verify_xml('') will fail downstream,
    # but the trust-anchor check should pass. Trap downstream error.
    my $override = Sub::Override->override(
        'MIME::Base64::decode_base64' => sub ($) { return '' }
    );
    $override->override('Net::SAML2::Binding::POST::verify_xml' => sub { return 0 });
    $b->handle_response('');
}, 'explicit insecure_trust_embedded_cert opt-out lets handle_response proceed');

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
