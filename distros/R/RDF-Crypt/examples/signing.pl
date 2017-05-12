use 5.010;
use strict;

use RDF::Crypt;

my $signer = RDF::Crypt::Signer->new_from_file('t/key-for-testing/test-key-private.pem');
my $signed = $signer->sign_embed_turtle('<http://localhost/test/sig/bar.ttl> <http://localhost/test/sig/p> <http://localhost/test/sig/o> .');

say $signed;
say $signer->verify_embedded_turtle($signed);

my $verifier = RDF::Crypt::Verifier->new_from_file('t/key-for-testing/test-key-public.pem');
say $verifier->verify_embedded_turtle($signed);

