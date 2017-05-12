use utf8;
use Test::More tests => 10;
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

my $key = Crypt::OpenSSL::RSA->generate_key(1024);
my $V   = RDF::Crypt::Verifier->new_from_string($key->get_public_key_string);
my $S   = RDF::Crypt::Signer->new_from_string($key->get_private_key_string);

ok(
	$V->verify_text($_, $S->sign_text($_)),
) for @strings;

ok(
	not $V->verify_text($_, uc $S->sign_text($_)),
) for @strings;