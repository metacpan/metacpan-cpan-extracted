use t::App;
use Test::More;

plan skip_all => 'TEST_ONLINE=1 need to be set' unless $ENV{TEST_ONLINE};

$t->get_ok('/embed?url=https://instagram.com/p/6i1C0uF4wm/');
my $dom = $t->tx->res->dom;
like $dom->at('blockquote'), qr{\#geysir \#iceland \#slowmo}, 'blockquote';
like $dom->at('script')->{src}, qr/embeds\.js/, 'script';

$t->get_ok('/embed.json?url=https://instagram.com/p/6i1C0uF4wm/')
  ->json_is('/media_id', '1054638553270029350_437021506');

done_testing;
