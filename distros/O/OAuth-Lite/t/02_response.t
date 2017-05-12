use Test::More tests => 13;

use OAuth::Lite::Response;

my $encoded = q{oauth_token=foo&oauth_token_secret=bar};

my $r3 = OAuth::Lite::Response->from_encoded($encoded);
is($r3->token->token, 'foo');
is($r3->token->secret, 'bar');
ok(!$r3->token->callback_confirmed);

$r3 = OAuth::Lite::Response->from_encoded($encoded."\n");
is($r3->token->token, 'foo');
is($r3->token->secret, 'bar');
ok(!$r3->token->callback_confirmed);

$r3 = OAuth::Lite::Response->from_encoded($encoded."\r\n");
is($r3->token->token, 'foo');
is($r3->token->secret, 'bar');
ok(!$r3->token->callback_confirmed);

my $r4 = OAuth::Lite::Response->from_encoded(q{oauth_token=foo&oauth_token_secret=bar&oauth_callback_confirmed=true});
ok($r4->token->callback_confirmed);
my $r5 = OAuth::Lite::Response->from_encoded(q{oauth_token=foo&oauth_token_secret=bar&oauth_callback_confirmed=false});
ok(!$r5->token->callback_confirmed);

my $r6 = OAuth::Lite::Response->from_encoded(q{oauth_token=foo&oauth_token_secret=bar&oauth_callback_confirmed=false&foo=bar});
is($r6->param('foo'), 'bar');
ok(!$r6->param('unknown'));
