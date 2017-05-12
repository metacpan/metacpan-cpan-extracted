use utf8;
use Test::More tests => 1;
use RDF::Crypt;
use RDF::TrineX::Functions -all;
use RDF::Query;

my $key = Crypt::OpenSSL::RSA->generate_key(1024);
my $E   = RDF::Crypt::Encrypter->new_from_string($key->get_public_key_string);
my $D   = RDF::Crypt::Decrypter->new_from_string($key->get_private_key_string);

my $data = parse <<'EXAMPLE', as => 'Turtle', base => 'http://example.com/';
@prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>.
@prefix contact: <http://www.w3.org/2000/10/swap/pim/contact#>.

_:b1
  rdf:type contact:Person;
  contact:fullName "Eric Miller";
  contact:mailbox <mailto:em@w3.org>;
  contact:personalTitle "Dr.".
EXAMPLE

my $sparql = <<'SPARQL';
PREFIX contact: <http://www.w3.org/2000/10/swap/pim/contact#> 
ASK WHERE {
	?x a contact:Person .
	?x contact:fullName "Eric Miller" .
}
SPARQL

ok(
	RDF::Query
		-> new($sparql)
		-> execute( $D->decrypt_model($E->encrypt_model($data), base => 'http://example.net/') )
		-> get_boolean
);