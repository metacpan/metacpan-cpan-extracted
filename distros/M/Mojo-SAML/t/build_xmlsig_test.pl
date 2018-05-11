use Mojo::Base -strict;

use Mojo::SAML ':docs';

use Crypt::OpenSSL::RSA;
use Crypt::OpenSSL::X509;
use Mojo::File 'path';

my $key = Crypt::OpenSSL::RSA->new_private_key(path('t/test.key')->slurp);
my $cert = Crypt::OpenSSL::X509->new_from_string(path('t/test.cer')->slurp);

my $key_info = KeyInfo->new(cert => $cert);
my $doc = Mojo::SAML::Document->new(
  insert_signature => Signature->new(key_info => $key_info),
  sign_with_key => $key,
);  
$doc->template($doc->build_template(<<'XML'));
<Thing ID="abc123">
  <Important>Cool Stuff</Important>
</Thing>
XML

say $doc;
