use strict;
use warnings;
use Test::More;
use Test::Exception;
use File::Temp qw(tempdir);
use POSIX qw(strftime);

# Deliberately load ONLY Net::SAML2::Object::Response and NOT the full
# Net::SAML2 stack (and NOT Test::Net::SAML2, whose Util loads Net::SAML2).
# to_assertion() must work standalone, which requires Object::Response to
# load Net::SAML2::Protocol::Assertion itself.  If that `use` is missing the
# rest of the suite hides it because the test helper pulls in Net::SAML2.
#
# This check must run before anything else could pull in Assertion.  XML::Sig
# (used below to sign the fixtures) does not load it, so it is required after.
use Net::SAML2::Object::Response;

ok($INC{'Net/SAML2/Protocol/Assertion.pm'},
    'Object::Response loads Net::SAML2::Protocol::Assertion');

use XML::Sig;

# Build a signed Response with a cert we control so the cacert path actually
# verifies under the hardening branch's signature gate.  The eherkenning
# fixture cannot be used here: it references its key via <KeyName> (no
# embedded X509Certificate), which the cacert verify path rejects.  We
# self-trust: the same self-signed cert signs the Response and serves as the
# SP cacert.  Mirrors the setup in t/32-xsw-defenses.t.
my $dir = tempdir(CLEANUP => 1);
my $idp_key = "$dir/idp.key";
my $idp_crt = "$dir/idp.crt";
system("openssl genrsa -out $idp_key 2048 2>/dev/null") == 0 or die "idp keygen";
system("openssl req -new -x509 -key $idp_key -out $idp_crt -days 1 "
     . "-subj '/CN=Test IdP' 2>/dev/null") == 0 or die "idp certgen";

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
    my $inner = shift;
    my $resp_id = "_resp_$$" . "_" . int(rand(1e9));
    my $now = strftime("%Y-%m-%dT%H:%M:%SZ", gmtime());
    return <<"XML";
<samlp:Response xmlns:samlp="urn:oasis:names:tc:SAML:2.0:protocol"
                xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion"
                ID="$resp_id" Version="2.0" IssueInstant="$now"
                InResponseTo="NETSAML2_req$$"
                Destination="http://sp.test/saml/post">
  <saml:Issuer>http://idp.test/idp</saml:Issuer>
  <samlp:Status>
    <samlp:StatusCode Value="urn:oasis:names:tc:SAML:2.0:status:Success"/>
  </samlp:Status>
$inner
</samlp:Response>
XML
}

# Sign, then move the <Signature> to right after <saml:Issuer> (schema
# position) without reserialising the signed element, so the digest stays
# valid.  Same helper shape as t/32-xsw-defenses.t.
sub sign_schema_compliant {
    my ($s, $xml) = @_;
    my $signed = $s->sign($xml);
    my ($sig) = $signed =~ m{(<(?:ds|dsig):Signature\b.*?</(?:ds|dsig):Signature>)}s;
    return $signed unless $sig;
    $signed =~ s{\Q$sig\E}{}s;
    $signed =~ s{(</saml:Issuer>)}{$1$sig}s;
    return $signed;
}

my $signer = XML::Sig->new({
    x509               => 1,
    key                => $idp_key,
    cert               => $idp_crt,
    no_xml_declaration => 1,
});

my $signed_response = wrap_in_response(
    sign_schema_compliant($signer, make_assertion(nameid => 'lowuser@victim.com'))
);

# Response built with a trust anchor -> to_assertion inherits it, so the
# caller need not supply cacert a second time and a missing cacert cannot
# silently produce an unverified Assertion.
{
    my $resp = Net::SAML2::Object::Response->new_from_xml(
        xml    => $signed_response,
        cacert => $idp_crt,
    );
    my $assertion;
    lives_ok(sub { $assertion = $resp->to_assertion },
        'standalone to_assertion() succeeds without re-passing cacert') or diag $@;
    isa_ok($assertion, 'Net::SAML2::Protocol::Assertion');
    is($assertion && $assertion->cacert, $idp_crt,
        'Assertion inherited the Response cacert');
    is($assertion && $assertion->nameid, 'lowuser@victim.com',
        'extracted the signed NameID through the inherited cacert path');
}

# Response built insecure -> the insecure posture flows through, so the
# Assertion does not croak for a missing cacert it was never going to use.
{
    my $resp = Net::SAML2::Object::Response->new_from_xml(
        xml                          => $signed_response,
        insecure_trust_embedded_cert => 1,
    );
    my $assertion = $resp->to_assertion;
    is($assertion->insecure_trust_embedded_cert, 1,
        'Assertion inherited the Response insecure_trust_embedded_cert flag');
}

# Caller-supplied args override the inherited defaults: an insecure Response
# can still be upgraded to a real trust anchor at to_assertion time.
{
    my $resp = Net::SAML2::Object::Response->new_from_xml(
        xml                          => $signed_response,
        insecure_trust_embedded_cert => 1,
    );
    my $assertion = $resp->to_assertion(cacert => $idp_crt);
    is($assertion->cacert, $idp_crt,
        'caller cacert overrides the inherited insecure posture');
}

done_testing;
