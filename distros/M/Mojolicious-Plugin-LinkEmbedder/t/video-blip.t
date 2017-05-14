use t::App;
use Test::More;

plan skip_all => 'TEST_ONLINE=1 need to be set' unless $ENV{TEST_ONLINE};

$t->get_ok('/embed?url=http://blip.tv/the-cinema-snob/endless-love-by-the-cinema-snob-6723860')
  ->element_exists('iframe[class="link-embedder video-blip"]')
  ->element_exists('iframe[src="http://blip.tv/play/hJFxg5qyeAI.x?p=1"][width="720"][height="433"]');

$t->get_ok('/embed.json?url=http://blip.tv/the-cinema-snob/endless-love-by-the-cinema-snob-6723860')
  ->json_is('/media_id',   'hJFxg5qyeAI.x')
  ->json_is('/pretty_url', 'http://blip.tv/the-cinema-snob/endless-love-by-the-cinema-snob-6723860')
  ->json_is('/url',        'http://blip.tv/the-cinema-snob/endless-love-by-the-cinema-snob-6723860');

done_testing;
