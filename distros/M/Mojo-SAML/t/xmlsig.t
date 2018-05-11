use Mojo::Base -strict;

use Mojo::XMLSig;
use Mojo::File 'path';
use Mojo::Util;

use Test::More;

subtest 'existing document' => sub {
  my $req = path('t/keycloak_saml_response.xml')->slurp;
  ok Mojo::XMLSig::has_signature($req), 'sample request has signature';
  ok Mojo::XMLSig::verify($req), 'sample request verifies itself';
};

subtest 'create document, sign, and verify' => sub {
  my $cert = path('t/test.cer')->slurp;
  my $x509 = Crypt::OpenSSL::X509->new_from_string($cert);
  my $pub  = Crypt::OpenSSL::RSA->new_public_key($x509->pubkey);
  my $key  = Crypt::OpenSSL::RSA->new_private_key(path('t/test.key')->slurp);

  $cert = Mojo::XMLSig::trim_cert($cert);

  my $xml = <<"XML";
<Thing ID="abc123"><ds:Signature xmlns:ds="http://www.w3.org/2000/09/xmldsig#">
  <ds:SignedInfo>
    <ds:CanonicalizationMethod Algorithm="http://www.w3.org/2001/10/xml-exc-c14n#" />
    <ds:SignatureMethod Algorithm="http://www.w3.org/2000/09/xmldsig#rsa-sha1" />
    <ds:Reference URI="#abc123">
      <ds:Transforms>
        <ds:Transform Algorithm="http://www.w3.org/2000/09/xmldsig#enveloped-signature" />
        <ds:Transform Algorithm="http://www.w3.org/2001/10/xml-exc-c14n#" />
      </ds:Transforms>
      <ds:DigestMethod Algorithm="http://www.w3.org/2000/09/xmldsig#sha1" />
      <ds:DigestValue></ds:DigestValue>
    </ds:Reference>
  </ds:SignedInfo>
  <ds:SignatureValue></ds:SignatureValue>
    <KeyInfo xmlns="http://www.w3.org/2000/09/xmldsig#">
  <X509Data>
    <X509Certificate>$cert</X509Certificate>
  </X509Data>
</KeyInfo>

</ds:Signature>

  <Important>Cool Stuff</Important>
</Thing>
XML

  my $signed = Mojo::XMLSig::sign($xml, $key);
  ok $signed, 'A document was returned';
  ok Mojo::XMLSig::has_signature($signed), 'the document has a signature';
  ok Mojo::XMLSig::verify($signed), 'the signature verifies by itself';
  ok Mojo::XMLSig::verify($signed, $pub), 'the signature verifies using the public key from the cert';

  subtest 'alter the document' => sub {
    my $warn = '';
    local $SIG{__WARN__} = sub { $warn .= $_[0] };
    ok $signed =~ s/Cool Stuff/Very Neat Stuff/, 'substitution was made';
    ok !Mojo::XMLSig::verify($signed), 'the signature no longer verifies';
    ok !Mojo::XMLSig::verify($signed, $pub), 'the signature no longer verifies using the public key from the cert';
    ok $warn, 'warnings were issued';
  };
};

done_testing;

