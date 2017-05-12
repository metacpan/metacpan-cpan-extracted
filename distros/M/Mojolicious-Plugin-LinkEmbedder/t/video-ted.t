use t::App;
use Test::More;

plan skip_all => 'TEST_ONLINE=1 need to be set' unless $ENV{TEST_ONLINE};

$t->get_ok('/embed?url=http://www.ted.com/talks/ryan_holladay_to_hear_this_music_you_have_to_be_there_literally.html')
  ->element_exists(
  'iframe[src="//embed.ted.com/talks/ryan_holladay_to_hear_this_music_you_have_to_be_there_literally.html"]')
  ->element_exists('iframe[class="link-embedder video-ted"]')->element_exists('iframe[width="560"][height="315"]')
  ->element_exists('iframe[frameborder="0"][scrolling="no"][allowfullscreen]');

$t->get_ok(
  '/embed.json?url=http://www.ted.com/talks/ryan_holladay_to_hear_this_music_you_have_to_be_there_literally.html')
  ->json_is('/media_id', 'ryan_holladay_to_hear_this_music_you_have_to_be_there_literally')
  ->json_like('/pretty_url',
  qr{http://www\.ted\.com/talks/ryan_holladay_to_hear_this_music_you_have_to_be_there_literally})
  ->json_like('/url', qr{http://www\.ted\.com/talks/ryan_holladay_to_hear_this_music_you_have_to_be_there_literally});

done_testing;
