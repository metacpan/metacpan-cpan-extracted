#!perl
use 5.010;
use strict;
use warnings;
use lib 't/lib';
use Test::More;

BEGIN {
    eval { require File::Raw::XML; require Crypt::JWS; 1 }
        or plan skip_all => "File::Raw::XML and Crypt::JWS are required ($@)";
}

use Punk::SAML ();
use Punk::SAML::IdP ();
use Punk::SAML::Metadata ();
use Punk::SAML::Response ();
use FakeIdP ();
use MIME::Base64 ();
use Crypt::JWS::Key ();

my $MD = 'urn:oasis:names:tc:SAML:2.0:metadata';
my $DS = 'http://www.w3.org/2000/09/xmldsig#';
my $REDIRECT = 'urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect';
my $POST     = 'urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST';

# A real certificate, so the reader's "will it parse" check is exercised
# against something that actually parses.
my $key  = Crypt::JWS::Key->generate('RS256');
my $key2 = Crypt::JWS::Key->generate('RS256');

sub cert_b64 {
    my ($k) = @_;
    # a self-signed certificate is what metadata carries; make one by
    # asking openssl, and skip the whole file if it is not here
    my ($pem, $der) = @_[1, 2];
    return $pem;
}

# Two certificates WITH their private keys, because sign_metadata has to
# sign with the key belonging to the certificate it publishes. A first
# pass at this test generated the two independently and produced a
# perfectly valid signature that verified against nothing.
my ($CERT_PEM, $CERT_KEY, $CERT2_PEM);
BEGIN {
    for my $n (1, 2) {
        my $kf = "psaml-md-key-$$-$n.pem";
        my $c = `openssl req -x509 -newkey rsa:2048 -keyout $kf -nodes -subj "/CN=idp$n" -days 3650 2>/dev/null`;
        my $k = do { open my $fh, '<', $kf or last; local $/; <$fh> };
        unlink $kf;
        if ($n == 1) { $CERT_PEM = $c; $CERT_KEY = $k } else { $CERT2_PEM = $c }
    }
    unless ($CERT_PEM && $CERT_KEY && $CERT_PEM =~ /BEGIN CERTIFICATE/) {
        require Test::More;
        Test::More::plan(skip_all => 'openssl is required to build certificates');
    }
}

sub bare {
    my ($pem) = @_;
    my ($b) = $pem =~ /-----BEGIN CERTIFICATE-----(.*?)-----END/s;
    $b =~ s/\s+//g;
    return $b;
}

sub metadata {
    my (%o) = @_;
    my $binding = $o{binding} // $REDIRECT;
    my $keys = $o{keys} // qq{<md:KeyDescriptor use="signing"><ds:KeyInfo><ds:X509Data>}
        . qq{<ds:X509Certificate>} . bare($CERT_PEM) . qq{</ds:X509Certificate>}
        . qq{</ds:X509Data></ds:KeyInfo></md:KeyDescriptor>};
    my $inner = qq{<md:IDPSSODescriptor protocolSupportEnumeration="urn:oasis:names:tc:SAML:2.0:protocol"}
        . ($o{want_signed} ? ' WantAuthnRequestsSigned="true"' : '') . '>'
        . $keys
        . ($o{formats} // '<md:NameIDFormat>urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress</md:NameIDFormat>')
        . ($o{no_sso} ? '' : qq{<md:SingleSignOnService Binding="$binding" Location="https://idp.example.com/sso"/>})
        . '</md:IDPSSODescriptor>';
    $inner = '' if $o{no_descriptor};
    return qq{<md:EntityDescriptor xmlns:md="$MD" xmlns:ds="$DS" entityID="}
         . ($o{entity_id} // 'https://idp.example.com/entity') . qq{">$inner</md:EntityDescriptor>};
}

sub read_err {
    my (@a) = @_;
    local $@;
    eval { Punk::SAML::IdP->read(@a) };
    return $@;
}

# ---- the happy path --------------------------------------------------

{
    my $idp = Punk::SAML::IdP->read(metadata());
    is $idp->{entity_id}, 'https://idp.example.com/entity', 'the entity id';
    is $idp->{sso_url}, 'https://idp.example.com/sso', 'the SSO URL';
    is scalar @{ $idp->{certs} }, 1, 'one signing certificate';
    like $idp->{certs}[0], qr/BEGIN CERTIFICATE/,
        'kept as PEM, which is the form phase 6 already reads';
    like $idp->{fingerprints}[0], qr/\A[0-9a-f]{64}\z/,
        'with a SHA-256 fingerprint';
    is_deeply $idp->{name_id_formats},
        ['urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress'],
        'the name id formats are kept for punk saml idp to print';
    is $idp->{want_authn_requests_signed}, 0, 'WantAuthnRequestsSigned off';

    # the fingerprint is over the same DER the key came from, so it is
    # the number a provider's console shows
    my $want = unpack 'H*', Crypt::JWS::sha256(
        MIME::Base64::decode_base64(bare($CERT_PEM)));
    is $idp->{fingerprints}[0], $want,
        'and it is a digest of the certificate itself';
}

{
    my $idp = Punk::SAML::IdP->read(metadata(want_signed => 1));
    is $idp->{want_authn_requests_signed}, 1, 'WantAuthnRequestsSigned on';
}

# ---- the `use` attribute --------------------------------------------
#
# The specification says a missing `use` means the key serves both
# purposes, and providers omit it constantly. A reader that required it
# would find no keys in perfectly ordinary metadata.

{
    my $no_use = qq{<md:KeyDescriptor><ds:KeyInfo><ds:X509Data>}
        . qq{<ds:X509Certificate>} . bare($CERT_PEM) . qq{</ds:X509Certificate>}
        . qq{</ds:X509Data></ds:KeyInfo></md:KeyDescriptor>};
    my $idp = Punk::SAML::IdP->read(metadata(keys => $no_use));
    is scalar @{ $idp->{certs} }, 1, 'a KeyDescriptor with no use is a signing key';
}

{
    my $enc = qq{<md:KeyDescriptor use="encryption"><ds:KeyInfo><ds:X509Data>}
        . qq{<ds:X509Certificate>} . bare($CERT_PEM) . qq{</ds:X509Certificate>}
        . qq{</ds:X509Data></ds:KeyInfo></md:KeyDescriptor>};
    my $err = read_err(metadata(keys => $enc));
    isa_ok $err, 'Punk::SAML::Error', 'an encryption-only key';
    is $err->{code}, 'config', '  ... is not a signing key';
    like $err->{message}, qr/use="encryption"/, '  ... and the message says so';
}

# two certificates, in order: a provider mid-rotation publishes both
{
    my $two = join '', map {
        qq{<md:KeyDescriptor use="signing"><ds:KeyInfo><ds:X509Data>}
        . qq{<ds:X509Certificate>} . bare($_) . qq{</ds:X509Certificate>}
        . qq{</ds:X509Data></ds:KeyInfo></md:KeyDescriptor>}
    } ($CERT_PEM, $CERT2_PEM);
    my $idp = Punk::SAML::IdP->read(metadata(keys => $two));
    is scalar @{ $idp->{certs} }, 2, 'both certificates are kept';
    isnt $idp->{fingerprints}[0], $idp->{fingerprints}[1],
        'and they are different certificates';
}

# ---- the refusals ----------------------------------------------------

{
    my $err = read_err(metadata(binding => $POST));
    is $err->{code}, 'config', 'a POST-only SingleSignOnService is refused';
    like $err->{message}, qr/HTTP-Redirect/,
        '  ... naming the binding this plugin sends by';
}

is read_err(metadata(no_sso => 1))->{code}, 'config', 'no SSO service at all';
is read_err(metadata(no_descriptor => 1))->{code}, 'config',
    'no IDPSSODescriptor';
is read_err('<foo/>')->{code}, 'config', 'a root that is neither descriptor';
is read_err('not xml')->{code}, 'xml_parse', 'not XML at all';

{
    my $bad = qq{<md:KeyDescriptor use="signing"><ds:KeyInfo><ds:X509Data>}
        . qq{<ds:X509Certificate>bm90IGEgY2VydA==</ds:X509Certificate>}
        . qq{</ds:X509Data></ds:KeyInfo></md:KeyDescriptor>};
    my $err = read_err(metadata(keys => $bad));
    is $err->{code}, 'config', 'a certificate that will not parse';
    like $err->{message}, qr/will not parse as an X\.509/,
        '  ... is caught at boot, not at the first login';
}

# ---- federation metadata --------------------------------------------

{
    my $fed = qq{<md:EntitiesDescriptor xmlns:md="$MD" xmlns:ds="$DS">}
        . metadata(entity_id => 'https://a.example/e') =~ s/<\?xml[^>]*\?>//r
        . metadata(entity_id => 'https://b.example/e')
        . qq{</md:EntitiesDescriptor>};
    $fed =~ s{<md:EntityDescriptor xmlns:md="\Q$MD\E" xmlns:ds="\Q$DS\E" }{<md:EntityDescriptor }g;

    my $err = read_err($fed);
    is $err->{code}, 'config', 'federation metadata with no entity_id named';
    like $err->{message}, qr/https:\/\/a\.example\/e/, '  ... lists the ids';
    like $err->{message}, qr/https:\/\/b\.example\/e/, '  ... all of them';

    my $idp = Punk::SAML::IdP->read($fed, entity_id => 'https://b.example/e');
    is $idp->{entity_id}, 'https://b.example/e', 'and one can be chosen';

    is read_err($fed, entity_id => 'https://c.example/e')->{code}, 'config',
        'an entity that is not in the file';
}

# a single EntityDescriptor whose id is not the configured one
is read_err(metadata(), entity_id => 'https://other/')->{code}, 'config',
    'a single entity that is not the one configured';

# ---- SP metadata, written -------------------------------------------

my $ACS = 'https://app.example.com/saml/acs';
my $EID = 'https://app.example.com/saml/metadata';

{
    my $md = Punk::SAML::Metadata->build(entity_id => $EID, acs_url => $ACS);
    like $md, qr/entityID="\Q$EID\E"/, 'the entity id';
    like $md, qr/AuthnRequestsSigned="false"/, 'unsigned requests by default';
    like $md, qr/WantAssertionsSigned="true"/, 'assertions wanted signed';
    like $md, qr{Location="\Q$ACS\E"}, 'the ACS location';
    like $md, qr/Binding="\Q$POST\E"/, 'the POST binding for the ACS';
    unlike $md, qr/KeyDescriptor/, 'no KeyDescriptor without a cert';
    unlike $md, qr/NameIDFormat/, 'no NameIDFormat unless set';

    # it parses, which is the least a document handed to a provider owes
    ok File::Raw::XML::file_xml_decode($md), 'and it parses';
}

{
    my $md = Punk::SAML::Metadata->build(
        entity_id => $EID, acs_url => $ACS, cert => $CERT_PEM,
        name_id_format => 'urn:x', authn_requests_signed => 1,
        want_assertions_signed => 0);
    like $md, qr/AuthnRequestsSigned="true"/, 'signed requests advertised';
    like $md, qr/WantAssertionsSigned="false"/, 'and reflects require_signed';
    like $md, qr{<md:NameIDFormat>urn:x</md:NameIDFormat>}, 'the name id format';
    ok index($md, '<ds:X509Certificate>' . bare($CERT_PEM)
                . '</ds:X509Certificate>') >= 0,
        'the certificate, with the PEM armour and newlines stripped';
}

is(Punk::SAML::Metadata->content_type, 'application/samlmetadata+xml',
   "the media type is the specification's, not application/xml");

# ---- sign_metadata ---------------------------------------------------

{
    my $md = Punk::SAML::Metadata->build(entity_id => $EID, acs_url => $ACS);
    $md =~ s{(<md:EntityDescriptor)}{$1 ID="_md1"};
    # signed with the key that BELONGS to the published certificate
    my $signed = Punk::SAML::Metadata->sign($md, '_md1', $CERT_KEY,
                                            $CERT_PEM);
    like $signed, qr/<ds:Signature/, 'a Signature is spliced in';
    like $signed, qr{<md:EntityDescriptor[^>]*><ds:Signature},
        'as the first child, which is where the schema puts it';
    ok File::Raw::XML::file_xml_decode($signed), 'and the result parses';

    # Verified through this dist's own verifier - and that proves LESS
    # than it looks like it does. The signer canonicalises through the
    # same frx c14n and signs through the same jws table, so if the
    # canonicalisation were wrong both halves would be wrong together
    # and this would still pass. What proves the c14n is File::Raw::XML's
    # transcribed W3C vectors; what proves this document is a provider
    # accepting it, which is phase 11.
    ok Punk::SAML::_verify_document($signed, '_md1', [$CERT_PEM]),
        'and this dist verifies its own signature';

    # An edited document THROWS rather than returning false: the verifier
    # has three outcomes, not two, and "signed and wrong" is never the
    # same answer as "not signed". That distinction is what require_signed
    # depends on.
    (my $tampered = $signed) =~ s/\Q$ACS\E/https:\/\/evil\/acs/;
    my $err = do {
        local $@;
        eval { Punk::SAML::_verify_document($tampered, '_md1', [$CERT_PEM]) };
        $@;
    };
    isa_ok $err, 'Punk::SAML::Error', 'an edited signed document';
    is $err->{code}, 'bad_digest', '  ... fails on the digest';
}

done_testing();
