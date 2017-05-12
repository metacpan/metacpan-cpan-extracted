use t::App;
use Test::More;

plan skip_all => 'TEST_ONLINE=1 need to be set' unless $ENV{TEST_ONLINE};

my @types = qw( video/mpeg video/mpeg video/quicktime video/mp4 video/ogg );
for my $ext (qw( mpg mpeg mov mp4 ogv )) {
  my $type = shift @types;
  $t->get_ok("/embed?url=http://video.thinkninja.com/grumpify_banner.$ext")
    ->element_exists(qq(video[width="640"][height="390"][preload="metadata"][controls]))
    ->element_exists(qq(video > source[src="http://video.thinkninja.com/grumpify_banner.$ext"][type="$type"]))
    ->text_is(qq(video > p), 'Your browser does not support the video tag.');
}

$t->get_ok("/embed.json?url=http://video.thinkninja.com/grumpify_banner.ogv")->json_is('/media_id', '')
  ->json_is('/pretty_url', 'http://video.thinkninja.com/grumpify_banner.ogv')
  ->json_is('/url',        'http://video.thinkninja.com/grumpify_banner.ogv');

done_testing;
