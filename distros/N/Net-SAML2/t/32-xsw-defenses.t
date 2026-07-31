use strict;
use warnings;
use Test::Lib;
use Test::Net::SAML2;
use File::Temp qw(tempdir);
use POSIX qw(strftime);

use Net::SAML2::Protocol::Assertion;
use XML::Sig;

# Shared setup: generate an IdP keypair + self-signed cert that we'll
# use both for signing assertions in the tests below AND as the SP's
# cacert (self-trust). At test time openssl shells out; matches the
# PoC pattern at poc/saml-attacker-cert-poc/.
my $dir = tempdir(CLEANUP => 1);
my $idp_key = "$dir/idp.key";
my $idp_crt = "$dir/idp.crt";
system("openssl genrsa -out $idp_key 2048 2>/dev/null") == 0 or die "idp keygen";
system("openssl req -new -x509 -key $idp_key -out $idp_crt -days 1 "
     . "-subj '/CN=Test IdP' 2>/dev/null") == 0 or die "idp certgen";

# Build a SAML assertion XML with a chosen ID and NameID.
sub make_assertion {
    my %p = @_;
    my $id     = $p{id}     // "_legit_" . int(rand(1e9));
    my $nameid = $p{nameid} // 'lowuser@victim.com';
    my $issuer = $p{issuer} // 'http://idp.test/idp';
    my $now    = strftime("%Y-%m-%dT%H:%M:%SZ", gmtime(time - 60));
    my $exp    = strftime("%Y-%m-%dT%H:%M:%SZ", gmtime(time + 3600));
    my $aud    = $p{audience} // 'http://sp.test';
    my $recip  = $p{recipient} // 'http://sp.test/saml/post';

    return <<"XML";
<saml:Assertion xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion"
                ID="$id" Version="2.0" IssueInstant="$now">
  <saml:Issuer>$issuer</saml:Issuer>
  <saml:Subject>
    <saml:NameID Format="urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress">$nameid</saml:NameID>
    <saml:SubjectConfirmation Method="urn:oasis:names:tc:SAML:2.0:cm:bearer">
      <saml:SubjectConfirmationData InResponseTo="_req_$$" NotOnOrAfter="$exp" Recipient="$recip"/>
    </saml:SubjectConfirmation>
  </saml:Subject>
  <saml:Conditions NotBefore="$now" NotOnOrAfter="$exp">
    <saml:AudienceRestriction>
      <saml:Audience>$aud</saml:Audience>
    </saml:AudienceRestriction>
  </saml:Conditions>
  <saml:AuthnStatement AuthnInstant="$now" SessionIndex="_sess_$$">
    <saml:AuthnContext>
      <saml:AuthnContextClassRef>urn:oasis:names:tc:SAML:2.0:ac:classes:Password</saml:AuthnContextClassRef>
    </saml:AuthnContext>
  </saml:AuthnStatement>
  <saml:AttributeStatement>
    <saml:Attribute Name="role">
      <saml:AttributeValue>user</saml:AttributeValue>
    </saml:Attribute>
  </saml:AttributeStatement>
</saml:Assertion>
XML
}

# Wrap a (possibly-signed) Assertion XML in a Response wrapper.
sub wrap_in_response {
    my %p = @_;
    my $inner = $p{inner};
    my $resp_id = "_resp_$$" . "_" . int(rand(1e9));
    my $now = strftime("%Y-%m-%dT%H:%M:%SZ", gmtime());
    my $dest = $p{destination} // 'http://sp.test/saml/post';
    return <<"XML";
<samlp:Response xmlns:samlp="urn:oasis:names:tc:SAML:2.0:protocol"
                xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion"
                ID="$resp_id" Version="2.0" IssueInstant="$now"
                Destination="$dest">
  <saml:Issuer>http://idp.test/idp</saml:Issuer>
  <samlp:Status>
    <samlp:StatusCode Value="urn:oasis:names:tc:SAML:2.0:status:Success"/>
  </samlp:Status>
$inner
</samlp:Response>
XML
}

my $signer = XML::Sig->new({
    x509               => 1,
    key                => $idp_key,
    cert               => $idp_crt,
    no_xml_declaration => 1,
});

# Helper: sign and post-process so the <dsig:Signature> sits right
# after <saml:Issuer> within the signed element - the position the
# SAML 2.0 schema (AssertionType, StatusResponseType) requires.
# XML::Sig appends the signature as the last child, which is valid
# per W3C XML-DSig but rejected by strict schema-validating SPs.
#
# This is regex-based and only moves the Signature element verbatim
# (no parsing/reserialization). Internal whitespace of SignedInfo
# is untouched, so digest and signature math both remain valid.
sub sign_schema_compliant {
    my ($s, $xml) = @_;
    my $signed = $s->sign($xml);
    my ($sig) = $signed =~ m{(<(?:ds|dsig):Signature\b.*?</(?:ds|dsig):Signature>)}s;
    return $signed unless $sig;
    # Move the Signature element ONLY - no surrounding whitespace -
    # so the canonical form of the signed element (after enveloped-
    # signature transform strips the Signature) is byte-identical to
    # what XML::Sig digested. Any added whitespace would change the
    # text-node structure and break digest validation.
    $signed =~ s{\Q$sig\E}{}s;
    $signed =~ s{(</saml:Issuer>)}{$1$sig}s;
    return $signed;
}

# ============================================================
# Sanity: a legitimately-signed Response + Assertion parses
# ============================================================
{
    my $assertion_xml = make_assertion(nameid => 'lowuser@victim.com');
    my $signed = sign_schema_compliant($signer, $assertion_xml);
    my $response = wrap_in_response(inner => $signed);

    my $a = eval {
        Net::SAML2::Protocol::Assertion->new_from_xml(
            xml    => $response,
            cacert => $idp_crt,
        );
    };
    ok($a, 'sanity: legit signed assertion parses') or diag $@;
    is($a && $a->nameid, 'lowuser@victim.com', 'sanity: nameid extracted');
}

# ============================================================
# Test 1: math gate catches a corrupted SignatureValue
# ============================================================
{
    my $assertion_xml = make_assertion(nameid => 'lowuser@victim.com');
    my $signed = sign_schema_compliant($signer, $assertion_xml);
    my $response = wrap_in_response(inner => $signed);

    # Corrupt the first base64 char of the SignatureValue so the signature
    # math must fail. Deterministic: flip the captured char to a
    # guaranteed-different value (A<->B), regardless of what it is, and
    # tolerate optional whitespace/newline after the opening tag. The
    # previous version set a fixed char ('A') which was a no-op when the
    # original char already equalled it, making the test flaky.
    (my $corrupted = $response) =~ s{
        (<(?:ds|dsig)?:?SignatureValue[^>]*>\s*) ([A-Za-z0-9+/])
    }{
        $1 . ($2 eq 'A' ? 'B' : 'A')
    }ex;
    isnt($corrupted, $response, 'corruption regex made a change');

    throws_ok(
        sub {
            Net::SAML2::Protocol::Assertion->new_from_xml(
                xml    => $corrupted,
                cacert => $idp_crt,
            );
        },
        qr/XML signature verification failed/,
        'XML signature verification failed croaks on corrupted SignatureValue'
    );
}

# ============================================================
# Test 2: defensive croak on XSW1 duplicate-ID
# ============================================================
{
    my $legit_id = "_legit_id_dup_test";
    my $assertion_xml = make_assertion(id => $legit_id, nameid => 'lowuser@victim.com');
    my $signed = sign_schema_compliant($signer, $assertion_xml);

    # Inject a SECOND <saml:Assertion> with the SAME ID, AFTER the signed
    # one (so XML::Sig's _get_node still picks the legit one for digest).
    my $duplicate = qq{<saml:Assertion xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion" ID="$legit_id"><saml:Issuer>x</saml:Issuer></saml:Assertion>};
    my $payload = $signed . $duplicate;
    my $response = wrap_in_response(inner => $payload);

    throws_ok(
        sub {
            Net::SAML2::Protocol::Assertion->new_from_xml(
                xml    => $response,
                cacert => $idp_crt,
            );
        },
        qr/XSW guard|ambiguous|XML signature verification failed/,
        'duplicate-ID document is rejected (either XSW guard or upstream XML::Sig fail)'
    );
}

# ============================================================
# Test 3: XSW different-ID wrapping is defended
#
# Attacker constructs a Response containing a fresh attacker
# Assertion (different ID, NameID="admin@victim.com") prepended
# in document order, followed by the legitimately-signed Assertion
# (NameID="lowuser@victim.com"). Without the XSW anchor, document-
# order extraction would pick the attacker's element. With it,
# extraction is anchored at the signed Assertion's subtree.
# ============================================================
{
    my $legit_id = "_legit_" . int(rand(1e9));
    my $legit_xml = make_assertion(id => $legit_id, nameid => 'lowuser@victim.com');
    my $signed_legit = sign_schema_compliant($signer, $legit_xml);

    # Attacker's modified Assertion - no signature, NameID escalated.
    my $atk_id = "_attacker_" . int(rand(1e9));
    my $atk_xml = make_assertion(id => $atk_id, nameid => 'admin@victim.com');

    my $payload = "$atk_xml\n<wrapper xmlns=\"urn:wrapper\">$signed_legit</wrapper>";
    my $response = wrap_in_response(inner => $payload);

    my $a = eval {
        Net::SAML2::Protocol::Assertion->new_from_xml(
            xml    => $response,
            cacert => $idp_crt,
        );
    };
    my $err = $@;
    ok($a, 'XSW different-ID: new_from_xml returned an Assertion') or diag $err;
    is($a && $a->nameid, 'lowuser@victim.com',
        'XSW different-ID: extracted NameID is the LEGIT one (not admin@victim.com)');
}

# ============================================================
# Test 4: multi-signature attack is defended by trusted-refs filter
#
# Two signatures in the same Response:
#   - Sig A: by attacker's own self-signed cert (CA-untrusted),
#            covers an attacker-controlled Assertion
#   - Sig B: by the trusted IdP, covers the legitimately-signed
#            Assertion (the attacker captured this from their own
#            honest login).
# Both math-validate (each signed by its own key against own cert).
# XML::Sig validates ALL signatures and signer_cert ends as the
# LAST cert (IdP). Without trusted-refs filter, naive anchor at
# the first signature would pick the attacker's element.
# With trusted-refs: only the IdP-chained signature is considered.
# ============================================================
{
    # Generate attacker keypair + self-signed cert (not chained to IdP).
    my $atk_key = "$dir/atk.key";
    my $atk_crt = "$dir/atk.crt";
    system("openssl genrsa -out $atk_key 2048 2>/dev/null") == 0 or die "atk keygen";
    system("openssl req -new -x509 -key $atk_key -out $atk_crt -days 1 "
         . "-subj '/CN=Evil Attacker' 2>/dev/null") == 0 or die "atk certgen";

    # Attacker signs their own Assertion (NameID=admin)
    my $atk_signer = XML::Sig->new({
        x509               => 1,
        key                => $atk_key,
        cert               => $atk_crt,
        no_xml_declaration => 1,
    });
    my $atk_id = "_atk_" . int(rand(1e9));
    my $atk_xml = make_assertion(id => $atk_id, nameid => 'admin@victim.com');
    my $signed_atk = sign_schema_compliant($atk_signer, $atk_xml);

    # Legit IdP signs their Assertion (NameID=lowuser)
    my $legit_id = "_legit_" . int(rand(1e9));
    my $legit_xml = make_assertion(id => $legit_id, nameid => 'lowuser@victim.com');
    my $signed_legit = sign_schema_compliant($signer, $legit_xml);

    # Place attacker first in doc order, legit second.
    my $payload = "$signed_atk\n$signed_legit";
    my $response = wrap_in_response(inner => $payload);

    my $a = eval {
        Net::SAML2::Protocol::Assertion->new_from_xml(
            xml    => $response,
            cacert => $idp_crt,
        );
    };
    my $err = $@;
    isa_ok($a, 'Net::SAML2::Protocol::Assertion');
    is($a->nameid, 'lowuser@victim.com',
        'multi-sig: extracted NameID is the IdP-trusted one (not admin@victim.com)');
}

# ============================================================
# Test 5: multiple <samlp:Response> in one document - one good, one bad
#
# Attacker has a legitimately Response-LEVEL signed document from
# their honest login (Mode 1 - the IdP signed the entire
# <samlp:Response>). They wrap it untouched inside an outer Response
# they construct, prepending their own modified <saml:Assertion>
# with NameID=admin.
#
# The document now has TWO <samlp:Response> elements:
#   - outer: attacker-constructed, unsigned, with NameID=admin in
#     its own Assertion
#   - inner: legitimately signed by the IdP, NameID=lowuser
#
# Pre-fix Net::SAML2 walks the document with findnodes('//saml:Assertion')
# and picks the first match in document order = attacker's. Post-fix
# the XSW anchor identifies the inner signed Response via the
# signature's Reference URI and constrains extraction to its subtree.
#
# This is the same shape as poc/saml-attacker-cert-poc/poc-xsw-mode1.pl
# distilled into a regression test.
# ============================================================
{
    my $legit_resp_id = "_legit_resp_" . int(rand(1e9));
    my $now = strftime("%Y-%m-%dT%H:%M:%SZ", gmtime(time - 60));
    my $exp = strftime("%Y-%m-%dT%H:%M:%SZ", gmtime(time + 3600));

    # Build a complete Response containing the legit Assertion, then
    # sign the Response (Mode 1).
    my $legit_resp_unsigned = <<"XML";
<samlp:Response xmlns:samlp="urn:oasis:names:tc:SAML:2.0:protocol"
                xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion"
                ID="$legit_resp_id" Version="2.0" IssueInstant="$now"
                Destination="http://sp.test/saml/post">
  <saml:Issuer>http://idp.test/idp</saml:Issuer>
  <samlp:Status>
    <samlp:StatusCode Value="urn:oasis:names:tc:SAML:2.0:status:Success"/>
  </samlp:Status>
@{[ make_assertion(id => "_legit_asn_" . int(rand(1e9)),
                  nameid => 'lowuser@victim.com') ]}
</samlp:Response>
XML

    my $legit_signed_response = sign_schema_compliant($signer, $legit_resp_unsigned);

    # Attacker's Assertion: same shape, NameID=admin, NO signature.
    my $atk_asn_xml = make_assertion(
        id     => "_atk_asn_" . int(rand(1e9)),
        nameid => 'admin@victim.com',
    );

    # Build the outer attacker-constructed Response that wraps both.
    # The outer Response is first in doc order and contains the
    # attacker's Assertion before the legit signed Response (nested).
    my $payload = "$atk_asn_xml\n<wrapper xmlns=\"urn:wrapper\">$legit_signed_response</wrapper>";
    my $multi_response = wrap_in_response(inner => $payload);

    my $a = eval {
        Net::SAML2::Protocol::Assertion->new_from_xml(
            xml    => $multi_response,
            cacert => $idp_crt,
        );
    };
    my $err = $@;
    ok($a, 'multi-response: new_from_xml returned an Assertion') or diag $err;
    is($a && $a->nameid, 'lowuser@victim.com',
        'multi-response: extracted NameID is from the GOOD (signed) Response, '
      . 'not the BAD (attacker-prepended) one');
}

done_testing;
