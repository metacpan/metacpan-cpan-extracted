use utf8;
use t::App;
use Test::More;

plan skip_all => 'TEST_ONLINE=1 need to be set' unless $ENV{TEST_ONLINE};

my @tests = (
  {
    url   => 'https://metacpan.org/',
    image => '//metacpan.org/static/icons/apple-touch-icon.png',
    h3    => 'Search the CPAN - metacpan.org',
    p     => '',
  },
  {
    url   => 'https://metacpan.org/pod/Mojolicious',
    image => '/4a49eb49e0b98ed1a1fb30b7d39baac3',
    h3    => 'Mojolicious',
    p     => 'Real-time web framework',
  },
  {
    url   => 'https://metacpan.org/author/JHTHORSEN',
    image => '/806800a3aeddbad6af673dade958933b',
    h3    => 'Jan Henning Thorsen',
    p     => 'CPAN Author',
  },
  {
    url   => 'https://metacpan.org/release/Convos',
    image => 'gravatar',
    h3    => 'Convos',
    p     => 'Multiuser IRC proxy with web interface',
  },
);

# test caching
splice @tests, 1, 0, $tests[0];

for my $test (@tests) {
  diag $test->{url};

  $t->get_ok("/embed?url=$test->{url}")->element_exists('.link-embedder.text-html')
    ->text_is('.link-embedder.text-html > h3', $test->{h3})->text_is('.link-embedder.text-html > p', $test->{p})
    ->element_exists(qq(.link-embedder-media img[src*="$test->{image}"]));

  diag 'body=' . $t->tx->res->body unless $t->success;

  #last if $test->{url} eq 'https://metacpan.org/pod/Mojolicious';
}

done_testing;
