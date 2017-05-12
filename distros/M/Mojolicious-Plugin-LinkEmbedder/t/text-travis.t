use t::App;
use Test::More;

plan skip_all => 'TEST_ONLINE=1 need to be set' unless $ENV{TEST_ONLINE};

$t->get_ok("/embed?url=https://travis-ci.org/Nordaaker/convos/builds/47421379")
  ->element_exists('.link-embedder.text-html')
  ->text_is('.link-embedder.text-html > h3', 'Build succeeded at 2015-01-18T13:30:57Z')
  ->text_is('.link-embedder.text-html > p',  'Jan Henning Thorsen: cpanm --from https://cpan.metacpan.org/')
  ->element_exists(qq(.link-embedder-media img[src="https://travis-ci.com/img/travis-mascot-200px.png"]));

diag 'body=' . $t->tx->res->body unless $t->success;

done_testing;
