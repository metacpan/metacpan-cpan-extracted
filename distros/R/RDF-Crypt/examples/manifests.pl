use 5.010;
use strict;
use Data::Dumper;
use RDF::Crypt;

my $signer = RDF::Crypt::Signer->new_from_file('/home/tai/keys/tobyink-private.pem');
my $manifest = $signer->generate_manifest(
	'http://tobyinkster.co.uk/#i',
	[
		'http://localhost/test/sig/foo.ttl',
		'http://localhost/test/sig/bar.ttl',
		'http://localhost/test/sig/baz.ttl',
		'http://localhost/test/sig/foo.ttl',
	],
);

print RDF::Trine::Serializer::Turtle
	-> new(namespaces => {
		wot => 'http://xmlns.com/wot/0.1/',
		wox => 'http://ontologi.es/wotox#',
		xsd => 'http://www.w3.org/2001/XMLSchema#',
	})
	-> serialize_model_to_string($manifest);

my @result = RDF::Crypt::Verifier->verify_manifest($manifest);
print Dumper \@result;
