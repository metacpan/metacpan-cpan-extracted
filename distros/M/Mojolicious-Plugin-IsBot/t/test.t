use Test::More;
use Mojo::Base -strict;
use Test::Mojo;

use utf8;

BEGIN {
    use_ok 'Mojolicious::Plugin::IsBot';
}

package MyApp;
use Mojo::Base 'Mojolicious';

sub startup {
    my $app = shift;
    $app->plugin('IsBot');

    my $router = $app->routes->namespaces( ['MyApp::Controller'] );
    $router->get('/')->to('test#isbottest');
}

package MyApp::Controller::Test;
use Mojo::Base 'Mojolicious::Controller';

sub isbottest {
    my $c = shift;
    return $c->rendered(200) if $c->req->is_bot;
    $c->rendered(500);
}

package main;

my $t = Test::Mojo->new( MyApp->new );

subtest 'bots' => sub {
    $t->get_ok( '/' => { 'User-Agent' => 'perl' } )->status_is(200);
    $t->get_ok( '/' => { 'User-Agent' => 'axios' } )->status_is(200);
    $t->get_ok( '/' => { 'User-Agent' => 'ia_archiver' } )->status_is(200);
    $t->get_ok( '/' => { 'User-Agent' => 'java' } )->status_is(200);
};

my $req = Mojo::Message::Request->new;

sub is_bot {
    $req->is_bot(@_);
}

subtest 'subroutine_test' => sub {
    ok is_bot('perl'), 'is perl blocked?';
    ok is_bot('java'), 'is java blocked?';
    ok !is_bot('adskldasjadaskjdasjkladsjkladsjkldjkladsjkladsjkla'),
      'is random not blocked?';
    ok !is_bot('Mozilla/5.0 (X11; Linux x86_64; rv:109.0)'),
      'is firefox on linux not blocked?';
    ok !is_bot(
'Mozilla/5.0 (Linux; Android 13; SM-S908B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/112.0.0.0 Mobile Safari/537.36'
      ),
      'is firefox on samsung not blocked?';
    ok !is_bot(
'Mozilla/5.0 (Linux; Android 13; Pixel 6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/112.0.0.0 Mobile Safari/537.36'
      ),
      'Is firefox on google pixel not blocked?';
    ok !is_bot(
'Mozilla/5.0 (Linux; Android 12; Redmi Note 9 Pro) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/112.0.0.0 Mobile Safari/537.36'
      ),
      'Is firefox on Redmi note not blocked?';
    ok !is_bot(
'Mozilla/5.0 (iPhone14,3; U; CPU iPhone OS 15_0 like Mac OS X) AppleWebKit/602.1.50 (KHTML, like Gecko) Version/10.0 Mobile/19A346 Safari/602.1'
      ),
      'is iphone safari not blocked?';
    ok !is_bot(
'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/42.0.2311.135 Safari/537.36 Edge/12.246'
      ),
      'is MSFT edge not blocked?';
    ok !is_bot(
'Mozilla/5.0 (X11; CrOS x86_64 8172.45.0) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2704.64 Safari/537.36'
    ), 'is Chrome OS using chrome not blocked?';
    ok !is_bot( '
Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_2) AppleWebKit/601.3.9 (KHTML, like Gecko) Version/9.0.2 Safari/601.3.9'
      ),
      'Is MacOS Safari not blocked?';
    ok !is_bot(
'Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/47.0.2526.111 Safari/537.36'
      ),
      'Is win-7 safari not blocked?';
    ok !is_bot(
        'Dalvik/2.1.0 (Linux; U; Android 9; ADT-2 Build/PTT5.181126.002)'),
      'Is Google ADT-2 not blocked?';
    ok !is_bot(
'Mozilla/5.0 (CrKey armv7l 1.5.16041) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/31.0.1650.0 Safari/537.36'
    ), 'Is chromecast not blocked?';
    ok !is_bot('Roku4640X/DVP-7.70 (297.70E04154A)'), 'Is roku not blocked?';
    ok !is_bot(
'Mozilla/5.0 (Linux; Android 5.1; AFTS Build/LMY47O) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/41.99900.2250.0242 Safari/537.36'
    ), 'Is amazon fire stick not blocked?';
    ok !is_bot(
        'Dalvik/2.1.0 (Linux; U; Android 6.0.1; Nexus Player Build/MMB29T)'),
      'Is nexus player not blocked?';
    ok !is_bot('AppleTV11,1/11.1'), 'is apple TV not blocked?';
    ok !is_bot(
'Mozilla/5.0 (PlayStation; PlayStation 5/2.26) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.0 Safari/605.1.15'
    ), 'Is PS5 not blocked?';
    ok !is_bot(
'Mozilla/5.0 (Windows NT 10.0; Win64; x64; Xbox; Xbox Series X) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/48.0.2564.82 Safari/537.36 Edge/20.02'
    ), 'Is XBOX series X not blocked?';
    ok !is_bot(
'Mozilla/5.0 (Nintendo Switch; WifiWebAuthApplet) AppleWebKit/601.6 (KHTML, like Gecko) NF/4.0.0.5.10 NintendoBrowser/5.1.0.13343'
      ),
      'Is Nintendo Switch not blocked?';
    ok !is_bot(
'Mozilla/5.0 (X11; U; Linux armv7l like Android; en-us) AppleWebKit/531.2+ (KHTML, like Gecko) Version/5.0 Safari/533.2+ Kindle/3.0+'
    ), 'Is kindle not a bot?';

    ok is_bot(
'Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)'
      ),
      'Is googlebot a bot?';
    ok is_bot(
'Mozilla/5.0 (compatible; bingbot/2.0; +http://www.bing.com/bingbot.htm)'
      ),
      'Is bingbot a bot?';
    ok is_bot(
'Mozilla/5.0 (compatible; Yahoo! Slurp; http://help.yahoo.com/help/us/ysearch/slurp)'
    ), 'Is yahoobot a bot?';

    ok is_bot('ia_archiver'), 'Is Alexa Crawler a bot?';
    ok is_bot('Mozilla/4.0 (compatible; MSIE 5.5; Windows NT 4.0; obot)'),
      'Is obot a bot?';
    ok is_bot(
'Mozilla/5.0 (compatible;PetalBot;+https://webmaster.petalsearch.com/site/petalbot)'
    ), 'Is petal bot a bot?';
    ok is_bot('ds-robot/Nutch-1.20-SNAPSHOT'), 'Is nutch bot a bot?';
    ok is_bot(
'yacybot (/global; amd64 Linux 6.1.0-11-amd64; java 11.0.20; Etc/en) http://yacy.net/bot.html'
    ), 'Is yacybot a bot?';
    ok is_bot('yandex'),          'Is yandex a bot?';
    ok is_bot('newspaper/0.2.7'), 'Is newspaper a bot?';
    ok is_bot(
'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/115.0.0.0 Safari/537.36 Bytespider'
    ), 'Is bytepsider a bot?';
    ok is_bot('XenForo/1.5 (https://swedroid.se/forum)'), 'Is xenforo a bot?';
    ok is_bot(
'yacybot (/global; amd64 Linux 5.15.0-78-generic; java 11.0.20; Europe/en) http://yacy.net/bot.html'
    ), 'Is yacy2bot a bot?';
    ok is_bot(
'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/116.0 Bytespider'
    ), 'Is bytespider a bot?';
    ok is_bot('MagpieRSS/0.72 ( http://magpierss.sf.net)'), 'Is magpie a bot?';
    ok is_bot('MagpieRSS/0.7x (+http://magpierss.sf.net)'),
      'Is magpie 0.7x a bot?';
    ok is_bot('MagpieRSS/0.72 (+http://magpierss.sf.net)'),
      'Is magpie 0.72 a bot?';
};

done_testing;
