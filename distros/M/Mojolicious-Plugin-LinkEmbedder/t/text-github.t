use utf8;
use t::App;
use Test::More;

plan skip_all => 'TEST_ONLINE=1 need to be set' unless $ENV{TEST_ONLINE};

my @tests = (
  {
    url   => 'https://github.com/kraih/mojo/issues/729',
    image => '/u/737152',
    h3    => qr{Validate &lt;input type=&quot;checkbox&quot;&gt;},
    p     => qr{rshadow\s+opened\s+this\s+Issue\s+Jan\s+12,\s+2015\s+·\s+4\s+comments}s
  },
  {
    url   => 'http://git.io/aKhMuA',
    image => '/u/45729',
    h3    => qr{Add\s+back\s+compat\s+redirect\s+from\s+/convos}s,
    p     => qr{jhthorsen\s+committed\s+Oct\s+19,\s+2014}s
  },
  {
    url   => 'https://github.com/Nordaaker/convos',
    image => '/u/811887',
    h3    => qr{convos - Better group chat},
    p     => qr{Convos is}
  },
  {
    url   => 'https://github.com/Nordaaker/convos/issues/50',
    image => '/u/45729',
    h3    => qr{Feature/start backend},
    p     => qr{marcusramberg\s+merged\s+2\s+commits}s
  },
);

# test caching
splice @tests, 1, 0, $tests[0];

for my $test (@tests) {
  diag $test->{url};

  #last if $test->{url} eq 'https://github.com/Nordaaker/convos';

  $t->get_ok("/embed?url=$test->{url}")->element_exists('.link-embedder.text-html')
    ->element_exists(qq(.link-embedder-media img[src*="$test->{image}"]))
    ->text_like('.link-embedder.text-html > p', $test->{p});

  like $t->tx->res->dom->at("h3"), $test->{h3}, "escaped h3";
}

done_testing;
