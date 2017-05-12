use Test::More tests => 21;

use OAuth::Lite::Token;

my $t1 = OAuth::Lite::Token->new_random;
is(length($t1->token), 20);
like($t1->token, qr/^[0-9a-zA-Z]{20}$/);
is(length($t1->secret), 20);
like($t1->secret, qr/^[0-9a-zA-Z]{20}$/);

my $t2 = OAuth::Lite::Token->new(
	token  => 'foo',
	secret => 'bar',
);

is($t2->token, 'foo');
is($t2->secret, 'bar');

my $encoded = $t2->as_encoded;
is($encoded, q{oauth_token=foo&oauth_token_secret=bar});

my $t3 = OAuth::Lite::Token->from_encoded($encoded);
is($t3->token, 'foo');
is($t3->secret, 'bar');
ok(!$t3->callback_confirmed);

$t3 = OAuth::Lite::Token->from_encoded($encoded."\n");
is($t3->token, 'foo');
is($t3->secret, 'bar');
ok(!$t3->callback_confirmed);

$t3 = OAuth::Lite::Token->from_encoded($encoded."\r\n");
is($t3->token, 'foo');
is($t3->secret, 'bar');
ok(!$t3->callback_confirmed);

my $t4 = OAuth::Lite::Token->from_encoded(q{oauth_token=foo&oauth_token_secret=bar&oauth_callback_confirmed=true});
ok($t4->callback_confirmed);
my $t5 = OAuth::Lite::Token->from_encoded(q{oauth_token=foo&oauth_token_secret=bar&oauth_callback_confirmed=false});
ok(!$t5->callback_confirmed);

my $t6 = OAuth::Lite::Token->new(
	token              => 'foo',
	secret             => 'bar',
  callback_confirmed => 1,
);

is($t6->token, 'foo');
is($t6->secret, 'bar');
is($t6->as_encoded, q{oauth_token=foo&oauth_token_secret=bar&oauth_callback_confirmed=true});
