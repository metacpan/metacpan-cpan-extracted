use strict;
use warnings;
use Test::Lib;
use Test::Net::SAML2;
use File::Temp qw(tempdir);
use POSIX qw(strftime);

use Net::SAML2::Protocol::Assertion;
use XML::Enc;

# Generate an SP keypair: the IdP would encrypt to the public cert
# (in real deployments, the IdP gets the cert from SP metadata).
my $dir = tempdir(CLEANUP => 1);
my $sp_key = "$dir/sp.key";
my $sp_crt = "$dir/sp.crt";
system("openssl genrsa -out $sp_key 2048 2>/dev/null") == 0
    or die "sp keygen failed";
system("openssl req -new -x509 -key $sp_key -out $sp_crt -days 1 "
     . "-subj '/CN=SP' 2>/dev/null") == 0
    or die "sp certgen failed";

# Construct an UNSIGNED <saml:Assertion>.
my $now = strftime("%Y-%m-%dT%H:%M:%SZ", gmtime(time - 60));
my $exp = strftime("%Y-%m-%dT%H:%M:%SZ", gmtime(time + 3600));
my $unsigned_assertion = <<"XML";
<saml:Assertion xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion"
                ID="_unsigned_assertion_$$" Version="2.0" IssueInstant="$now">
  <saml:Issuer>http://idp.test</saml:Issuer>
  <saml:Subject>
    <saml:NameID>admin\@victim.com</saml:NameID>
    <saml:SubjectConfirmation Method="urn:oasis:names:tc:SAML:2.0:cm:bearer">
      <saml:SubjectConfirmationData NotOnOrAfter="$exp" Recipient="http://sp.test/saml/post"/>
    </saml:SubjectConfirmation>
  </saml:Subject>
  <saml:Conditions NotBefore="$now" NotOnOrAfter="$exp">
    <saml:AudienceRestriction>
      <saml:Audience>http://sp.test</saml:Audience>
    </saml:AudienceRestriction>
  </saml:Conditions>
  <saml:AuthnStatement AuthnInstant="$now" SessionIndex="_s_$$"/>
  <saml:AttributeStatement>
    <saml:Attribute Name="role">
      <saml:AttributeValue>user</saml:AttributeValue>
    </saml:Attribute>
  </saml:AttributeStatement>
</saml:Assertion>
XML

# Encrypt it to the SP's public cert. The attacker can do this in real
# life because SP certs are published in SP metadata.
my $encrypter = XML::Enc->new({
    cert               => $sp_crt,
    no_xml_declaration => 1,
});
my $encrypted = $encrypter->encrypt($unsigned_assertion);

# Wrap the encrypted blob in a samlp:Response.
my $response = <<"XML";
<samlp:Response xmlns:samlp="urn:oasis:names:tc:SAML:2.0:protocol"
                xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion"
                ID="_resp_$$" Version="2.0" IssueInstant="$now"
                Destination="http://sp.test/saml/post">
  <saml:Issuer>http://idp.test</saml:Issuer>
  <samlp:Status>
    <samlp:StatusCode Value="urn:oasis:names:tc:SAML:2.0:status:Success"/>
  </samlp:Status>
  <saml:EncryptedAssertion>
    $encrypted
  </saml:EncryptedAssertion>
</samlp:Response>
XML

# Without require_signed_assertion: the unsigned encrypted assertion
# is silently accepted (backward-compatible default behaviour).
{
    lives_ok ( sub {
            Net::SAML2::Protocol::Assertion->new_from_xml(
                xml                      => $response,
                key_file                 => $sp_key,
                cacert                   => $sp_crt,
                insecure_trust_embedded_cert => 1,
            );
        },
        'unsigned encrypted assertion is accepted without require_signed_assertion (backward compat)'
    )
}

# With require_signed_assertion => 1: the unsigned encrypted assertion
# is refused. This is the gate that closes the
# attacker-encrypts-arbitrary-content-to-SP-pubkey class.
{
    throws_ok(
        sub {
            Net::SAML2::Protocol::Assertion->new_from_xml(
                xml                      => $response,
                key_file                 => $sp_key,
                require_signed_assertion => 1,
                cacert                   => $sp_crt,
            );
        },
        qr/Decrypted assertion has no signature/,
        'require_signed_assertion => 1 croaks on unsigned encrypted assertion'
    );
}

done_testing;
