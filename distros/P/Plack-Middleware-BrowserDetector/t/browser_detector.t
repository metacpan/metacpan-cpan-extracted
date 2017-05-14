use strict;
use warnings;
use Test::More;
use Plack::Builder;
use HTTP::Message::PSGI;
use HTTP::Request::Common;

my $app = builder {
    enable 'Plack::Middleware::BrowserDetector';
    \&test_for_browser,
};

while (my $test = <DATA>) {
    my ($browser, $user_agent) = split /\s*=\s*/, $test;

    my $req = GET "/?$browser", User_Agent => $user_agent;
    $app->($req->to_psgi);
}

sub test_for_browser {
    my $env = shift;

    my $method  = $env->{'QUERY_STRING'};
    my $browser = $env->{'BrowserDetector.browser'};

    ok ref($browser) eq 'HTTP::BrowserDetect', 'HTTP::BrowserDetect object';
    ok $browser->$method, "Browser is $method" if $method;
}

done_testing();

__DATA__
chrome  = Mozilla/5.0 (X11; Linux i686) AppleWebKit/535.21 (KHTML, like Gecko) Chrome/19.0.1041.0 Safari/535.21
safari  = Mozilla/5.0 (Macintosh; Intel Mac OS X 10_7_3) AppleWebKit/534.55.3 (KHTML, like Gecko) Version/5.1.3 Safari/534.53.10
firefox = Mozilla/5.0 (Windows NT 6.1; rv:15.0) Gecko/20120716 Firefox/15.0a2
ie      = Mozilla/5.0 (Windows; U; MSIE 9.0; Windows NT 9.0; en-US
curl    = curl/7.9.8 (i686-pc-linux-gnu) libcurl 7.9.8 (OpenSSL 0.9.6b) (ipv6 enabled)
opera   = Opera/9.80 (Windows NT 6.1; U; es-ES) Presto/2.9.181 Version/12.00
