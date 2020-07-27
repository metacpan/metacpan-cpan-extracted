use Test::More;

use Mojo::Feed;
use Mojo::File qw(path);

ok(Mojo::Feed->is_feed_content_type('application/atom+xml'), 'content type 1');
ok(Mojo::Feed->is_feed_content_type('application/atom+xml; charset=utf-8'), 'content type 1');

my $feed = Mojo::Feed->new(file => path('t/samples/itunes_summary.xml'));
is_deeply( $feed->namespaces,
{
 "atom" => "http://www.w3.org/2005/Atom",
  "content" => "http://purl.org/rss/1.0/modules/content/",
  "dc" => "http://purl.org/dc/elements/1.1/",
  "itunes" => "http://www.itunes.com/dtds/podcast-1.0.dtd",
  "media" => "http://search.yahoo.com/mrss/",
  "slash" => "http://purl.org/rss/1.0/modules/slash/",
  "sy" => "http://purl.org/rss/1.0/modules/syndication/",
  "wfw" => "http://wellformedweb.org/CommentAPI/"
},
'extract namespaces'
);


done_testing;
