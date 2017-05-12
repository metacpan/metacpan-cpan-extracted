use t::App;
use Test::More;

plan skip_all => 'TEST_ONLINE=1 need to be set' unless $ENV{TEST_ONLINE};

$t->get_ok('/embed?url=spotify:track:5tv77MoS0TzE0sJ7RwTj34')
  ->element_exists('iframe[class="link-embedder music-spotify"]')
  ->element_exists(
  'iframe[src="https://embed.spotify.com/?uri=spotify:track:5tv77MoS0TzE0sJ7RwTj34&theme=white&view=coverart"]')
  ->element_exists('iframe[width="300"][height="80"]');

$t->get_ok('/embed?url=http://open.spotify.com/artist/6VKNnZIuu9YEOvLgxR6uhQ')
  ->element_exists(
  'iframe[src="https://embed.spotify.com/?uri=spotify:artist:6VKNnZIuu9YEOvLgxR6uhQ&theme=white&view=coverart"]');

done_testing;
