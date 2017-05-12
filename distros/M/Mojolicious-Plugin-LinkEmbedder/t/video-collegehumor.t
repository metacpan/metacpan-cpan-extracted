use t::App;
use Test::More;

plan skip_all => 'TEST_ONLINE=1 need to be set' unless $ENV{TEST_ONLINE};

$t->get_ok('/embed?url=http://www.collegehumor.com/video/6952147/jake-and-amir-road-trip-part-6-las-vegas')
  ->element_exists('iframe[class="link-embedder video-collegehumor"]')
  ->element_exists('iframe[src="http://www.collegehumor.com/e/6952147"][width="600"][height="369"]');

$t->get_ok('/embed.json?url=http://www.collegehumor.com/video/6952147/jake-and-amir-road-trip-part-6-las-vegas')
  ->json_is('/media_id',   '6952147')
  ->json_is('/pretty_url', 'http://www.collegehumor.com/video/6952147/jake-and-amir-road-trip-part-6-las-vegas')
  ->json_is('/url',        'http://www.collegehumor.com/video/6952147/jake-and-amir-road-trip-part-6-las-vegas');

done_testing;
