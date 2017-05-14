use utf8;
use t::App;
use Test::More;

plan skip_all => 'TEST_ONLINE=1 need to be set' unless $ENV{TEST_ONLINE};

my @tests = (
  {
    url   => 'https://github.com/kraih/mojo/issues/729',
    image => '/u/737152',
    h3    => 'Validate &lt;input type=&quot;checkbox&quot;&gt;',
    p     => qr{rshadow opened this Issue Jan 12, 2015 · 4 comments}
  },
  {
    url   => 'http://git.io/aKhMuA',
    image => '/u/45729',
    h3    => 'Add back compat redirect from /convos to /',
    p     => qr{jhthorsen authored Oct 19, 2014}
  },
  {
    url   => 'https://github.com/Nordaaker/convos',
    image => '/u/811887',
    h3    => 'convos - Better group chat',
    p     => qr{Convos is the simplest way to use IRC}
  },
  {
    url   => 'https://github.com/Nordaaker/convos/issues/50',
    image => '/u/45729',
    h3    => 'Feature/start backend',
    p     => qr{marcusramberg merged 2 commits into master from feature/start-backend}
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

  is $t->tx->res->dom->at("h3"), "<h3>$test->{h3}</h3>", "escaped h3";
}

done_testing;
