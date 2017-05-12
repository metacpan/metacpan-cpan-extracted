use t::App;
use Test::More;

plan skip_all => 'TEST_ONLINE=1 need to be set' unless $ENV{TEST_ONLINE};

$t->get_ok('/embed?url=http://www.youtube.com/user/jsconfeu')->text_like('.link-embedder.text-html > h3', qr{JSConf}i);

$t->get_ok('/embed?url=http://www.youtube.com/watch?v=4BMYH-AQyy0')
  ->element_exists('iframe[class="link-embedder video-youtube"]')
  ->element_exists('iframe[src="//www.youtube.com/embed/4BMYH-AQyy0?"]')
  ->element_exists('iframe[width="640"][height="390"]');

$t->get_ok('/embed.json?url=http://www.youtube.com/watch?v=4BMYH-AQyy0%26eurl=huh%26mode=huh%26search=huh')
  ->json_is('/media_id', '4BMYH-AQyy0')->json_like('/pretty_url', qr{^https?://www\.youtube\.com/watch\?v=4BMYH-AQyy0})
  ->json_like('/url', qr{^https?://www\.youtube\.com/watch\?v=4BMYH-AQyy0&eurl=huh&mode=huh&search=huh});

done_testing;
