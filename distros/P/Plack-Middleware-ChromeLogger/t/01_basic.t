use strict;
use Plack::Builder;
use HTTP::Request::Common;
use LWP::UserAgent;
use MIME::Base64;
use JSON;

use Test::More 0.88;
use Plack::Test;

my $res = sub {
    $_[0]->{"psgix.chrome_logger"}->info('OH!');
    [ 200, ['Content-Type' => 'text/plain'], ['OK'] ];
};

my $expect_log = qq|eyJ2ZXJzaW9uIjoiMC4yIiwiY29sdW1ucyI6WyJsb2ciLCJiYWNrdHJhY2UiLCJ0eXBlIl0sInJv''d3MiOltbWyJPSCEiXSxudWxsLCJpbmZvIl1dfQ==''|;

{
    my $app = builder {
        enable 'ChromeLogger';
        $res;
    };
    my $cli = sub {
            my $cb = shift;
            my $res = $cb->(GET '/');
            is $res->code, 200;
            is $res->content_type, 'text/plain';
            is $res->content, 'OK';
            my $chrome_log = $res->header('X-ChromeLogger-Data');
            my $json_log = MIME::Base64::decode_base64($chrome_log);
            my $hash     = decode_json $json_log;
            is $hash->{rows}[0][0][0], 'OH!';
    };
    test_psgi $app, $cli;
}

done_testing;
