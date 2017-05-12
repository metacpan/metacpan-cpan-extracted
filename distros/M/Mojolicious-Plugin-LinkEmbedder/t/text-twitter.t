use t::App;
use Test::More;

plan skip_all => 'TEST_ONLINE=1 need to be set' unless $ENV{TEST_ONLINE};

# https://github.com/jhthorsen/mojolicious-plugin-linkembedder/issues/17
$t->get_ok('/embed?url=https://twitter.com/mulligan/status/555050159189413888/')
  ->element_exists(
  'div.link-embedder.text-twitter > blockquote[class="twitter-tweet"][lang="en"][data-conversation="none"]');

# https://github.com/jhthorsen/mojolicious-plugin-linkembedder/issues/17
$t->get_ok('/embed?url=https://twitter.com/mulligan/status/555050159189413888/photo/1')
  ->element_exists(
  'div.link-embedder.text-twitter > blockquote[class="twitter-tweet"][lang="en"][data-conversation="none"]');

$t->get_ok('/embed?url=https://twitter.com/jhthorsen/status/434045220116643843')
  ->element_exists(
  'div.link-embedder.text-twitter > blockquote[class="twitter-tweet"][lang="en"][data-conversation="none"]')
  ->element_exists(
  'div.link-embedder.text-twitter > blockquote > a[href="https://twitter.com/jhthorsen/status/434045220116643843"]')
  ->element_exists('div.link-embedder.text-twitter > script[src="//platform.twitter.com/widgets.js"]');

$t->get_ok('/embed?url=https://twitter.com/jhthorsen')
  ->text_is('a[href="https://twitter.com/jhthorsen"][target="_blank"]', 'https://twitter.com/jhthorsen');

done_testing;
