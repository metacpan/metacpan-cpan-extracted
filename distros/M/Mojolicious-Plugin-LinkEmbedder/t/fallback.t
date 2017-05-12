use t::App;
use Test::More;

for my $url ('x', 'foo:bar', 'spotify:') {
  $t->get_ok("/embed.json?url=$url")->status_is(400)->json_is('/code', 400)->json_is('/message', 'Invalid input');
}

SKIP: {
  skip 'Skipping google.com tests. (TEST_ONLINE=1)', 3 unless $ENV{TEST_ONLINE};

  my $url_re = qr{^https?.*google\.};

  $t->get_ok('/embed?url=http://google.com')->text_like('a[href*="google"]', $url_re);
  $t->get_ok('/embed.json?url=http://google.com')->json_like('/pretty_url', $url_re)->json_like('/url', $url_re);

  local $TODO = 'Not sure what media_id should hold';
  $t->json_is('/media_id', '');
}

done_testing;
