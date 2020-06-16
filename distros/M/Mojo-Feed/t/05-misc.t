use Test::More;

use Mojo::Feed;

ok(Mojo::Feed->is_feed_content_type('application/atom+xml'), 'content type 1');
ok(Mojo::Feed->is_feed_content_type('application/atom+xml; charset=utf-8'), 'content type 1');

done_testing;
