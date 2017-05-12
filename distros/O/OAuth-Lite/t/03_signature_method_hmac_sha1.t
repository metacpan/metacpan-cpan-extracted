use Test::More tests => 8;

use OAuth::Lite::SignatureMethod::HMAC_SHA1;

is(OAuth::Lite::SignatureMethod::HMAC_SHA1->method_name, 'HMAC-SHA1');
is(OAuth::Lite::SignatureMethod::HMAC_SHA1->build_body_hash(qq{Hello World!}), q{Lve95gjOVATpfV8EL5X4nxwjKHE=});

my $base = "hogehogehoge";

my $signer = OAuth::Lite::SignatureMethod::HMAC_SHA1->new(
	consumer_secret => 'foo',
	token_secret    => 'bar',
);

my $signature = $signer->sign($base);
is($signature, q{TdSY8Tl5G/ihzaO8aRnIIdc7Wkc=});

my $verifier = OAuth::Lite::SignatureMethod::HMAC_SHA1->new(
	consumer_secret => 'foo',
	token_secret    => 'bar',
);

my $invalid_verifier = OAuth::Lite::SignatureMethod::HMAC_SHA1->new(
	consumer_secret => 'foo',
	token_secret    => 'invalid',
);

ok($verifier->verify($base, $signature));
ok(!$invalid_verifier->verify($base, $signature));

my $signer2 = OAuth::Lite::SignatureMethod::HMAC_SHA1->new(
	consumer_secret => 'foo',
);

my $signature2 = $signer2->sign($base);
is($signature2, q{ietxdwnHDniD+idyuFYk7MVQxHY=});

my $verifier2 = OAuth::Lite::SignatureMethod::HMAC_SHA1->new(
	consumer_secret => 'foo',
);

ok($verifier2->verify($base, $signature2));
ok(!$invalid_verifier->verify($base, $signature2));

