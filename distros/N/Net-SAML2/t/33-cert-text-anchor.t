use strict;
use warnings;
use Test::Lib;
use Test::Net::SAML2;
use File::Temp qw(tempdir);
use POSIX qw(strftime);

use Net::SAML2::Protocol::Assertion;
use Net::SAML2::Object::Response;
use XML::Sig;

# cert_text (certificate pinning) must be a first-class trust anchor:
# every defence a cacert deployment gets, a cert_text deployment gets
# too. This file mirrors t/32-xsw-defenses.t with cert_text in place of
# cacert, and adds the case cacert cannot defend - an attacker holding a
# certificate issued by the same CA as the IdP.

my $dir = tempdir(CLEANUP => 1);
my $idp_key = "$dir/idp.key";
my $idp_crt = "$dir/idp.crt";
system("openssl genrsa -out $idp_key 2048 2>/dev/null") == 0 or die "idp keygen";
system("openssl req -new -x509 -key $idp_key -out $idp_crt -days 1 "
     . "-subj '/CN=Test IdP' 2>/dev/null") == 0 or die "idp certgen";

sub slurp {
    my $file = shift;
    open my $fh, '<', $file or die "open $file: $!";
    local $/;
    return <$fh>;
}

my $idp_pem = slurp($idp_crt);

sub make_assertion {
    my %p = @_;
    my $id     = $p{id}     // "_legit_" . int(rand(1e9));
    my $nameid = $p{nameid} // 'lowuser@victim.com';
    my $now    = strftime("%Y-%m-%dT%H:%M:%SZ", gmtime(time - 60));
    my $exp    = strftime("%Y-%m-%dT%H:%M:%SZ", gmtime(time + 3600));

    return <<"XML";
<saml:Assertion xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion"
                ID="$id" Version="2.0" IssueInstant="$now">
  <saml:Issuer>http://idp.test/idp</saml:Issuer>
  <saml:Subject>
    <saml:NameID Format="urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress">$nameid</saml:NameID>
    <saml:SubjectConfirmation Method="urn:oasis:names:tc:SAML:2.0:cm:bearer">
      <saml:SubjectConfirmationData InResponseTo="_req_$$" NotOnOrAfter="$exp" Recipient="http://sp.test/saml/post"/>
    </saml:SubjectConfirmation>
  </saml:Subject>
  <saml:Conditions NotBefore="$now" NotOnOrAfter="$exp">
    <saml:AudienceRestriction>
      <saml:Audience>http://sp.test</saml:Audience>
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

sub wrap_in_response {
    my %p = @_;
    my $inner = $p{inner};
    my $resp_id = "_resp_$$" . "_" . int(rand(1e9));
    my $now = strftime("%Y-%m-%dT%H:%M:%SZ", gmtime());
    return <<"XML";
<samlp:Response xmlns:samlp="urn:oasis:names:tc:SAML:2.0:protocol"
                xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion"
                ID="$resp_id" Version="2.0" IssueInstant="$now"
                InResponseTo="_req_$$"
                Destination="http://sp.test/saml/post">
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

# See t/32-xsw-defenses.t - moves the Signature to the schema-required
# position without disturbing the canonical form that was digested.
sub sign_schema_compliant {
    my ($s, $xml) = @_;
    my $signed = $s->sign($xml);
    my ($sig) = $signed =~ m{(<(?:ds|dsig):Signature\b.*?</(?:ds|dsig):Signature>)}s;
    return $signed unless $sig;
    $signed =~ s{\Q$sig\E}{}s;
    $signed =~ s{(</saml:Issuer>)}{$1$sig}s;
    return $signed;
}

# ============================================================
# Sanity: cert_text ALONE is a working trust anchor
#
# Previously _trusted_signature_refs consulted cacert only, so a
# cert_text-only caller satisfied the constructor guard and then always
# croaked "No trusted signature found" - pinning was accepted at the
# door and unusable in practice.
# ============================================================
{
    my $response = wrap_in_response(
        inner => sign_schema_compliant($signer, make_assertion()));

    my $a = eval {
        Net::SAML2::Protocol::Assertion->new_from_xml(
            xml       => $response,
            cert_text => $idp_pem,
        );
    };
    ok($a, 'cert_text alone: legit signed assertion parses') or diag $@;
    is($a && $a->nameid, 'lowuser@victim.com',
        'cert_text alone: nameid extracted');
}

# ============================================================
# cert_text and cacert together
# ============================================================
{
    my $response = wrap_in_response(
        inner => sign_schema_compliant($signer, make_assertion()));

    my $a = eval {
        Net::SAML2::Protocol::Assertion->new_from_xml(
            xml       => $response,
            cert_text => $idp_pem,
            cacert    => $idp_crt,
        );
    };
    ok($a, 'cert_text + cacert: legit signed assertion parses') or diag $@;
}

# ============================================================
# A signature by any other key is rejected under pinning
# ============================================================
{
    my $atk_key = "$dir/atk.key";
    my $atk_crt = "$dir/atk.crt";
    system("openssl genrsa -out $atk_key 2048 2>/dev/null") == 0 or die "atk keygen";
    system("openssl req -new -x509 -key $atk_key -out $atk_crt -days 1 "
         . "-subj '/CN=Evil Attacker' 2>/dev/null") == 0 or die "atk certgen";

    my $atk_signer = XML::Sig->new({
        x509               => 1,
        key                => $atk_key,
        cert               => $atk_crt,
        no_xml_declaration => 1,
    });

    my $response = wrap_in_response(inner => sign_schema_compliant(
        $atk_signer, make_assertion(nameid => 'admin@victim.com')));

    throws_ok(
        sub {
            Net::SAML2::Protocol::Assertion->new_from_xml(
                xml       => $response,
                cert_text => $idp_pem,
            );
        },
        qr/signature verification failed|does not validate against|No trusted signature/,
        'cert_text: assertion signed by an unpinned key is rejected'
    );
}

# ============================================================
# The case cacert cannot defend: attacker holds a certificate
# issued by the SAME CA as the IdP.
#
# cacert accepts it - it chains. cert_text does not - it is not the
# pinned certificate. This is why cert_text is not merely equal to
# cacert on the key-trust axis but strictly stronger.
# ============================================================
{
    my $ca_key = "$dir/ca.key";
    my $ca_crt = "$dir/ca.crt";
    system("openssl genrsa -out $ca_key 2048 2>/dev/null") == 0 or die "ca keygen";
    system("openssl req -new -x509 -key $ca_key -out $ca_crt -days 1 "
         . "-subj '/CN=Shared CA' 2>/dev/null") == 0 or die "ca certgen";

    my %leaf;
    for my $who (qw(idp atk)) {
        my $k = "$dir/$who-ca.key";
        my $r = "$dir/$who-ca.csr";
        my $c = "$dir/$who-ca.crt";
        system("openssl genrsa -out $k 2048 2>/dev/null") == 0 or die "$who keygen";
        system("openssl req -new -key $k -out $r -subj '/CN=$who under CA' 2>/dev/null") == 0
            or die "$who csr";
        system("openssl x509 -req -in $r -CA $ca_crt -CAkey $ca_key "
             . "-CAcreateserial -out $c -days 1 2>/dev/null") == 0 or die "$who sign";
        $leaf{$who} = { key => $k, crt => $c };
    }

    # Attacker signs an escalated assertion with their CA-issued cert.
    my $atk_signer = XML::Sig->new({
        x509               => 1,
        key                => $leaf{atk}{key},
        cert               => $leaf{atk}{crt},
        no_xml_declaration => 1,
    });
    my $response = wrap_in_response(inner => sign_schema_compliant(
        $atk_signer, make_assertion(nameid => 'admin@victim.com')));

    # cacert pointed at the shared CA accepts it.
    my $via_cacert = eval {
        Net::SAML2::Protocol::Assertion->new_from_xml(
            xml    => $response,
            cacert => $ca_crt,
        );
    };
    is($via_cacert && $via_cacert->nameid, 'admin@victim.com',
        'broad cacert accepts an attacker certificate issued by the same CA');

    # cert_text pinned to the IdP's leaf refuses it.
    throws_ok(
        sub {
            Net::SAML2::Protocol::Assertion->new_from_xml(
                xml       => $response,
                cert_text => slurp($leaf{idp}{crt}),
            );
        },
        qr/signature verification failed|does not validate against|No trusted signature/,
        'cert_text refuses an attacker certificate issued by the same CA'
    );
}

# ============================================================
# XSW different-ID wrapping is defended under cert_text
# (mirrors t/32 Test 3)
# ============================================================
{
    my $signed_legit = sign_schema_compliant($signer,
        make_assertion(id => "_legit_" . int(rand(1e9)),
                       nameid => 'lowuser@victim.com'));

    my $atk_xml = make_assertion(id => "_attacker_" . int(rand(1e9)),
                                 nameid => 'admin@victim.com');

    my $response = wrap_in_response(
        inner => "$atk_xml\n<wrapper xmlns=\"urn:wrapper\">$signed_legit</wrapper>");

    my $a = eval {
        Net::SAML2::Protocol::Assertion->new_from_xml(
            xml       => $response,
            cert_text => $idp_pem,
        );
    };
    my $err = $@;
    ok($a, 'XSW different-ID under cert_text: returned an Assertion') or diag $err;
    is($a && $a->nameid, 'lowuser@victim.com',
        'XSW different-ID under cert_text: extracted NameID is the LEGIT one');
}

# ============================================================
# XSW1 duplicate-ID fails closed under cert_text
# (mirrors t/32 Test 2)
# ============================================================
{
    my $legit_id = "_dup_" . int(rand(1e9));
    my $signed_legit = sign_schema_compliant($signer,
        make_assertion(id => $legit_id, nameid => 'lowuser@victim.com'));

    # Same ID, no signature, escalated NameID.
    my $atk_xml = make_assertion(id => $legit_id, nameid => 'admin@victim.com');

    my $response = wrap_in_response(
        inner => "$atk_xml\n<wrapper xmlns=\"urn:wrapper\">$signed_legit</wrapper>");

    throws_ok(
        sub {
            Net::SAML2::Protocol::Assertion->new_from_xml(
                xml       => $response,
                cert_text => $idp_pem,
            );
        },
        qr/ambiguous|signature verification failed/,
        'XSW1 duplicate-ID under cert_text: fails closed'
    );
}

# ============================================================
# Multi-signature attack is defended under cert_text
# (mirrors t/32 Test 4)
# ============================================================
{
    my $atk_key = "$dir/atk2.key";
    my $atk_crt = "$dir/atk2.crt";
    system("openssl genrsa -out $atk_key 2048 2>/dev/null") == 0 or die "atk2 keygen";
    system("openssl req -new -x509 -key $atk_key -out $atk_crt -days 1 "
         . "-subj '/CN=Evil Attacker 2' 2>/dev/null") == 0 or die "atk2 certgen";

    my $atk_signer = XML::Sig->new({
        x509               => 1,
        key                => $atk_key,
        cert               => $atk_crt,
        no_xml_declaration => 1,
    });

    # Attacker's own validly-signed (by their own cert) escalated assertion
    # first in document order, the IdP-signed one second.
    my $signed_atk = sign_schema_compliant($atk_signer,
        make_assertion(id => "_atk_" . int(rand(1e9)), nameid => 'admin@victim.com'));
    my $signed_legit = sign_schema_compliant($signer,
        make_assertion(id => "_legit_" . int(rand(1e9)), nameid => 'lowuser@victim.com'));

    my $response = wrap_in_response(inner => "$signed_atk\n$signed_legit");

    my $a = eval {
        Net::SAML2::Protocol::Assertion->new_from_xml(
            xml       => $response,
            cert_text => $idp_pem,
        );
    };
    my $err = $@;

    # Under pinning the attacker's signature does not validate against the
    # pinned certificate at all, so either outcome is safe: the document is
    # rejected outright, or extraction anchors at the IdP-signed subtree.
    if ($a) {
        is($a->nameid, 'lowuser@victim.com',
            'multi-sig under cert_text: extracted NameID is the pinned-signer one');
    }
    else {
        like($err, qr/signature verification failed|No trusted signature|does not validate against/,
            'multi-sig under cert_text: rejected outright');
    }
}

# ============================================================
# Multiple <samlp:Response> in one document (mirrors t/32 Test 5)
# ============================================================
{
    my $now = strftime("%Y-%m-%dT%H:%M:%SZ", gmtime(time - 60));
    my $legit_resp_id = "_legit_resp_" . int(rand(1e9));

    my $legit_resp_unsigned = <<"XML";
<samlp:Response xmlns:samlp="urn:oasis:names:tc:SAML:2.0:protocol"
                xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion"
                ID="$legit_resp_id" Version="2.0" IssueInstant="$now"
                InResponseTo="_req_$$"
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

    my $atk_asn_xml = make_assertion(
        id     => "_atk_asn_" . int(rand(1e9)),
        nameid => 'admin@victim.com',
    );

    my $multi_response = wrap_in_response(
        inner => "$atk_asn_xml\n<wrapper xmlns=\"urn:wrapper\">$legit_signed_response</wrapper>");

    my $a = eval {
        Net::SAML2::Protocol::Assertion->new_from_xml(
            xml       => $multi_response,
            cert_text => $idp_pem,
        );
    };
    my $err = $@;
    ok($a, 'multi-response under cert_text: returned an Assertion') or diag $err;
    is($a && $a->nameid, 'lowuser@victim.com',
        'multi-response under cert_text: NameID is from the signed Response');
}

# ============================================================
# Object::Response accepts cert_text and propagates it to the
# Assertion, so pinning callers are never pushed onto
# insecure_trust_embedded_cert (which would disable the XSW anchor).
# ============================================================
{
    my $signed_legit = sign_schema_compliant($signer,
        make_assertion(id => "_legit_" . int(rand(1e9)),
                       nameid => 'lowuser@victim.com'));
    my $atk_xml = make_assertion(id => "_attacker_" . int(rand(1e9)),
                                 nameid => 'admin@victim.com');
    my $xsw = wrap_in_response(
        inner => "$atk_xml\n<wrapper xmlns=\"urn:wrapper\">$signed_legit</wrapper>");

    my $response = eval {
        Net::SAML2::Object::Response->new_from_xml(
            xml       => $xsw,
            cert_text => $idp_pem,
        );
    };
    ok($response, 'Object::Response accepts cert_text as a trust anchor') or diag $@;

    my $a = $response && eval { $response->to_assertion() };
    ok($a, 'Object::Response->to_assertion works under cert_text') or diag $@;
    is($a && $a->nameid, 'lowuser@victim.com',
        'Object::Response propagates cert_text: XSW anchor still applies');
}

# ============================================================
# No anchor at all is still refused by Object::Response
# ============================================================
{
    my $response = wrap_in_response(
        inner => sign_schema_compliant($signer, make_assertion()));

    throws_ok(
        sub { Net::SAML2::Object::Response->new_from_xml(xml => $response) },
        qr/requires 'cacert' or 'cert_text'/,
        'Object::Response still refuses to build with no trust anchor'
    );
}

done_testing;
