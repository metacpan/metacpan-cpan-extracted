use RDF::Crypt;
use Data::Dumper;

my $enc = RDF::Crypt::Encrypter->new_from_webid(
	'http://tobyinkster.co.uk/#i',
);

print Dumper( $enc->public_keys );
