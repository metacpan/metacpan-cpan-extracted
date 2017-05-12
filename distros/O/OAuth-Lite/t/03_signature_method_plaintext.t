use Test::More tests => 7;

use OAuth::Lite::SignatureMethod::PLAINTEXT;

is(OAuth::Lite::SignatureMethod::PLAINTEXT->method_name, 'PLAINTEXT');

my $base = "hogehogehoge";

my $signer = OAuth::Lite::SignatureMethod::PLAINTEXT->new(
	consumer_secret => 'foo',
	token_secret    => 'bar',
);

my $signature = $signer->sign($base);
is($signature, q{foo&bar});

my $verifier = OAuth::Lite::SignatureMethod::PLAINTEXT->new(
	consumer_secret => 'foo',
	token_secret    => 'bar',
);

my $invalid_verifier = OAuth::Lite::SignatureMethod::PLAINTEXT->new(
	consumer_secret => 'foo',
	token_secret    => 'invalid',
);

ok($verifier->verify($base, $signature));
ok(!$invalid_verifier->verify($base, $signature));

my $signer2 = OAuth::Lite::SignatureMethod::PLAINTEXT->new(
	consumer_secret => 'foo',
);

my $signature2 = $signer2->sign($base);
is($signature2, q{foo&});

my $verifier2 = OAuth::Lite::SignatureMethod::PLAINTEXT->new(
	consumer_secret => 'foo',
);

ok($verifier2->verify($base, $signature2));
ok(!$invalid_verifier->verify($base, $signature2));

