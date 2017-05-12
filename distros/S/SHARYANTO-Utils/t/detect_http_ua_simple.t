#!perl

use 5.010;
use strict;
use warnings;

use Test::More 0.96;

use SHARYANTO::HTTP::DetectUA::Simple qw(detect_http_ua_simple);

my @tests = (
    # ff
    {env=>{HTTP_USER_AGENT=>'Mozilla/5.0 (Windows NT 6.1; WOW64; rv:7.0.1) Gecko/20100101 Firefox/7.0.12011-10-16 20:23:00'}, gui=>1},
    {env=>{HTTP_USER_AGENT=>'Mozilla/5.0 (Windows; U; Windows NT 5.1; en-GB; rv:1.8.1.6) Gecko/20070725 Firefox/2.0.0.6'}, gui=>1},

    # ie
    {env=>{HTTP_USER_AGENT=>'Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1)'}, gui=>1},

    # opera
    {env=>{HTTP_USER_AGENT=>'Opera/9.20 (Windows NT 6.0; U; en)'}, gui=>1},

    # chrome
    {env=>{HTTP_USER_AGENT=>'Mozilla/5.0 (Windows NT 6.1) AppleWebKit/535.2 (KHTML, like Gecko) Chrome/18.6.872.0 Safari/535.2 UNTRUSTED/1.0 3gpp-gba UNTRUSTED/1.0'}, gui=>1},

    # mobile/tablet
    {env=>{HTTP_USER_AGENT=>'Mozilla/5.0 (iPad; U; CPU OS 3_2 like Mac OS X; en-us) AppleWebKit/531.21.10 (KHTML, like Gecko) Version/4.0.4 Mobile/7B334b Safari/531.21.102011-10-16 20:23:50'}, gui=>1},
    {env=>{HTTP_USER_AGENT=>'Mozilla/5.0 (Linux; U; Android 2.3.4; en-us; DROID BIONIC Build/5.5.1_84_DBN-55) AppleWebKit/533.1 (KHTML, like Gecko) Version/4.0 Mobile Safari/533.1'}, gui=>1},
    {env=>{HTTP_USER_AGENT=>'BlackBerry9530/4.7.0.76 Profile/MIDP-2.0 Configuration/CLDC-1.1 VendorID/126'}, gui=>1},
    {env=>{HTTP_USER_AGENT=>'User-Agent: Opera/9.80 (J2ME/MIDP; Opera Mini/6.1.25378/25.692; U; en) Presto/2.5.25 Version/10.54'}, gui=>1}, # opera mini
    {env=>{HTTP_USER_AGENT=>'Mozilla/5.0 (compatible; MSIE 9.0; Windows Phone OS 7.5; Trident/5.0; IEMobile/9.0; NOKIA; Lumia 800)'}, gui=>1},
    {env=>{HTTP_USER_AGENT=>'NokiaN90-1/3.0545.5.1 Series60/2.8 Profile/MIDP-2.0 Configuration/CLDC-1.1'}, gui=>1},

    # GENERIC gui
    {env=>{HTTP_ACCEPT=>'text/html, application/xml;q=0.9, application/xhtml+xml, image/png, image/webp, image/jpeg, image/gif, image/x-xbitmap, */*;q=0.1'}, gui=>1},

    # text
    {env=>{HTTP_USER_AGENT=>'Links (2.5; Linux 3.2.0-1-amd64 x86_64; GNU C 4.6.2;OC text)'}, text=>1},
    {env=>{HTTP_USER_AGENT=>'ELinks/0.9.3 (textmode; Linux 2.6.11 i686; 79x24)'}, text=>1},
    {env=>{HTTP_USER_AGENT=>'Lynx/2.8.8dev.9 libwww-FM/2.14 SSL-MM/1.4.1 GNUTLS/2.12.14'}, text=>1},
    {env=>{HTTP_USER_AGENT=>'w3m/0.5.1'}, text=>1},

    # NEITHER
    {env=>{HTTP_USER_AGENT=>'Googlebot/2.1 ( http://www.googlebot.com/bot.html) '}},
    {env=>{HTTP_USER_AGENT=>'curl/7.23.1 (x86_64-pc-linux-gnu) libcurl/7.23.1 OpenSSL/1.0.0f zlib/1.2.3.4 libidn/1.23 libssh2/1.2.8 librtmp/2.3'}},
    {env=>{HTTP_ACCEPT=>'*/*'}},
);

test_detect(%$_) for @tests;

DONE_TESTING:
done_testing;

sub test_detect {
    my %args = @_;

    my $env = $args{env};
    my $tname = $args{name} //
        ($env->{HTTP_USER_AGENT} ?
             "User-Agent $env->{HTTP_USER_AGENT}" : undef) //
                 "Accept $env->{HTTP_ACCEPT}";

    subtest $tname => sub {
        my $res;
        eval { $res = detect_http_ua_simple($env) };
        ok(!$@, "doesnt die");

        if ($args{gui}) {
            ok($res->{is_gui_browser}, "gui");
        } else {
            ok(!$res->{is_gui_browser}, "not gui");
        }

        if ($args{text}) {
            ok($res->{is_text_browser}, "text browser");
        } else {
            ok(!$res->{is_text_browser}, "not text browser");
        }

        if ($args{gui} || $args{text}) {
            ok($res->{is_browser}, "browser");
        } else {
            ok(!$res->{is_browser}, "not browser");
        }

        done_testing;
    };
}
