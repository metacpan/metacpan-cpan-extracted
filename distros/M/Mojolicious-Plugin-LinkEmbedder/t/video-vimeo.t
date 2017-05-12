use t::App;
use Test::More;

plan skip_all => 'TEST_ONLINE=1 need to be set' unless $ENV{TEST_ONLINE};

$ENV{VIMEO_ID} ||= '122950317';

$t->get_ok("/embed?url=https://vimeo.com/$ENV{VIMEO_ID}")->element_exists('iframe[class="link-embedder video-vimeo"]')
  ->element_exists(qq(iframe[src="//player.vimeo.com/video/$ENV{VIMEO_ID}?portrait=0&color=ffffff"]))
  ->element_exists(qq(iframe[width="500"][height="281"][frameborder="0"]));

$t->get_ok("/embed.json?url=https://vimeo.com/$ENV{VIMEO_ID}")->json_is('/media_id', $ENV{VIMEO_ID})
  ->json_like('/pretty_url', qr,^https?://vimeo\.com/$ENV{VIMEO_ID},)
  ->json_like('/url',        qr,^https?://vimeo\.com/$ENV{VIMEO_ID},);

done_testing;
