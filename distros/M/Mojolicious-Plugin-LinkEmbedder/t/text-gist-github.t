use t::App;
use Test::More;

plan skip_all => 'TEST_ONLINE=1 need to be set' unless $ENV{TEST_ONLINE};

$t->get_ok('/embed?url=https://gist.github.com/jhthorsen/3964764')
  ->element_exists(q(div#link_embedder_text_gist_github_1), 'container tag')
  ->element_exists(
  q(script[src="https://gist.github.com/jhthorsen/3964764.json?callback=link_embedder_text_gist_github_1"]),
  'json script tag')
  ->content_like(qr{window\.link_embedder_text_gist_github_1=function}, 'link_embedder_text_gist_github_1()')
  ->content_like(qr{document\.getElementById\('link_embedder_text_gist_github_1'\)\.innerHTML=g\.div}, 'g.div');

$t->get_ok('/embed?url=https://gist.github.com/jhthorsen')
  ->text_is('a[href="https://gist.github.com/jhthorsen"][target="_blank"]', 'https://gist.github.com/jhthorsen');

done_testing;
