use strict;
use Test::More;
use JSON;

BEGIN {
    use_ok('Rarbg::torrentapi::Res');
}

# Testing Rarbg::torrentapi::Res methods and attributes
can_ok( 'Rarbg::torrentapi::Res', ('new') );
can_ok( 'Rarbg::torrentapi::Res',
    qw( category download info_page pubdate title) );
can_ok( 'Rarbg::torrentapi::Res', qw( seeders leechers ranked size) );
can_ok( 'Rarbg::torrentapi::Res', ('episode_info') );
my $res_msg = <<RES;
        {
            "category": "TV Episodes",
            "download": "magnet:?xt=urn:btih:edbd27c890411a5e5659e9ae0daf631edc2d8ab7&dn=Star.Wars.Rebels.S01E13.HDTV.x264-BATV%5Brartv%5D&tr=http%3A%2F%2Ftracker.trackerfix.com%3A80%2Fannounce&tr=udp%3A%2F%2F9.rarbg.me%3A2710&tr=udp%3A%2F%2F9.rarbg.to%3A2710&tr=udp%3A%2F%2Fopen.demonii.com%3A1337%2Fannounce",
            "episode_info": {
                "airdate": "2015-03-02",
                "epnum": "13",
                "imdb": "tt2930604",
                "seasonnum": "1",
                "title": "Fire Across the Galaxy",
                "tvdb": "283468",
                "tvrage": "35995"
            },
            "info_page": "https://torrentapi.org/redirect_to_info.php?token=d6fpv3lrij&p=8_0_4_9_2_2__edbd27c890",
            "leechers": 0,
            "pubdate": "2015-03-03 02:33:40 +0000",
            "ranked": 1,
            "seeders": 0,
            "size": 188491315,
            "title": "Star.Wars.Rebels.S01E13.HDTV.x264-BATV[rartv]"
        }
RES
my $res_res = decode_json($res_msg);
my $res     = Rarbg::torrentapi::Res->new($res_res);

ok( $res->size == 188491315, 'Response int value test' );
is(
    $res->title,
    'Star.Wars.Rebels.S01E13.HDTV.x264-BATV[rartv]',
    'Response String value test'
);
isa_ok( $res->episode_info, 'HASH' );
is( $res->episode_info->{imdb}, 'tt2930604', 'Episode info hash test' );

done_testing;
