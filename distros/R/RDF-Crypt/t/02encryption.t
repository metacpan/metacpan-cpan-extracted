use utf8;
use Test::More tests => 5;
use RDF::Crypt;

my @strings;
push @strings, '';
push @strings, 'Testing: 1, 2, 3';
push @strings, 'Hello world';
push @strings, 'This is a very, very, very, very, very, very, very, very, very, ' .
	'very, very, very, very, very, very, very, very, very, very, very, very, ' .
	'very, very, very, very, very, very, very, very, very, very, very, very, ' .
	'very, very, very, very, very, very, very, very, very, very, very, very, ' .
	'very, very, very, very, very, very, very, very, very, very, very, very, ' .
	'very, very, very, very, very, very, very, very, very, very, very, very, ' .
	'very, very, very, very, very, very, very, very, very, very, very, very, ' .
	'very, very, very, very, very, very, very, very, very, very, very, very, ' .
	'very, very, very, very, very, very, very, very, very, very, very, very, ' .
	'very, very, very, very, very, very, very, very, very, very, very, very, ' .
	'very, very, very, very, very, very, very, very, very, very, very, very, ' .
	'very, very, very, very, very, very, very, very, very, very, very, very, ' .
	'very, very, very, very, very, very, very, very, very, very, very, very, ' .
	'very, very, very, very, very, very, very, very, very, very, very, very, ' .
	'very, very, very, very, very, very, very, very, very, very, very, very, ' .
	'very, very, very, very, very, very, very, very, very, very, very, very, ' .
	'very, very, very, very, very, very long string. A lot more than 512 bits.';
push @strings, 'Schloß';

my $key = Crypt::OpenSSL::RSA->generate_key(512);
my $E   = RDF::Crypt::Encrypter->new_from_string($key->get_public_key_string);
my $D   = RDF::Crypt::Decrypter->new_from_string($key->get_private_key_string);

is(
	$D->decrypt_text( $E->encrypt_text($_) ),
	$_,
) for @strings;

