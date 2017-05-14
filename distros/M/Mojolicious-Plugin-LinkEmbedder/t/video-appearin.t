use t::App;
use Test::More;

plan skip_all => 'TEST_ONLINE=1 need to be set' unless $ENV{TEST_ONLINE};

$t->get_ok('/embed?url=https://appear.in/your-room-name')
  ->element_exists('iframe[class="link-embedder video-appearin"]')
  ->element_exists('iframe[src="https://appear.in/your-room-name"]');

$t->get_ok('/embed.json?url=https://appear.in/your-room-name')->json_is('/media_id', 'your-room-name');

done_testing;
