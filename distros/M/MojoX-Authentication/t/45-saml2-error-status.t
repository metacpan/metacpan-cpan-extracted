use v5.24;
use warnings;
use experimental qw< signatures >;
use Test::More;
use FindBin qw< $Bin >;
use MIME::Base64 qw< encode_base64 >;
use Data::Dumper ();

eval { require Net::SAML2; Net::SAML2->VERSION(0.86); 1 }
   or plan skip_all => 'Net::SAML2 0.86 not available';

require Net::SAML2::XML::Sig;
require MojoX::Authentication::Model::SAML2;

# The IdP can answer with a non-success status (e.g. Responder/AuthnFailed)
# and no assertion at all. parse_assertion must report that status, not die
# later on something unrelated to the real cause.

my $data  = "$Bin/data";
my $saml2 = MojoX::Authentication::Model::SAML2->new(
   idp => "$data/test-idp-metadata.xml",
   sp_configuration => {
      identifier => 'https://srv.example.com/sp',
      key        => "$Bin/../eg/server.key",
   },
);

sub signed_response ($id, $status_xml) {
   my $xml = qq{<samlp:Response xmlns:samlp="urn:oasis:names:tc:SAML:2.0:protocol" xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion" ID="resp-$id" InResponseTo="$id" Version="2.0" IssueInstant="2026-11-09T00:00:00Z" Destination="http://127.0.0.1:3000/saml2"><saml:Issuer>https://idp.example.com</saml:Issuer><samlp:Status>$status_xml</samlp:Status></samlp:Response>};
   my $signer = Net::SAML2::XML::Sig->new({
      x509 => 1,
      key  => "$data/test-idp.key",
      cert => "$data/test-idp.crt",
      no_xml_declaration => 1,
   });
   return encode_base64($signer->sign($xml), '');
}

sub error_for ($id, $status_xml) {
   $saml2->cache->set({ ts => time() }, $saml2->_key(authnreq_id => $id), time() + 30);
   my $user = eval {
      $saml2->parse_assertion($id, signed_response($id, $status_xml));
   };
   my $error = $@;    # copy: evals below reset $@
   ok !defined($user), "$id: no user returned";
   my $text = "$error";
   if (eval { $error->isa('Ouch') }) {
      local $Data::Dumper::Indent = 0;
      $text .= ' ' . Data::Dumper::Dumper($error->data);
   }
   return $text;
}

my $responder = 'urn:oasis:names:tc:SAML:2.0:status:Responder';
my $authn_failed = 'urn:oasis:names:tc:SAML:2.0:status:AuthnFailed';

{
   my $error = error_for('req-responder',
      qq{<samlp:StatusCode Value="$responder"/>});
   like $error, qr{\Q$responder\E}, 'error reports the Responder status'
      or diag "got: $error";
}

{
   my $error = error_for('req-substatus',
      qq{<samlp:StatusCode Value="$responder"><samlp:StatusCode Value="$authn_failed"/></samlp:StatusCode>});
   like $error, qr{\Q$responder\E}, 'error reports the status';
   like $error, qr{\Q$authn_failed\E}, 'error reports the substatus'
      or diag "got: $error";
}

done_testing();
