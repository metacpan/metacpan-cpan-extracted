use strict;
use warnings;

use Test::More tests => 5;

use Plient;
use Plient::Test;
use Plient::Handler::curl;
use Plient::Handler::wget;
use Plient::Handler::HTTPLite;
use Plient::Handler::HTTPTiny;
use Plient::Handler::LWP;
$ENV{PLIENT_HANDLER_PREFERENCE_ONLY} = 1;

my $url = start_http_server();
SKIP: {
    skip 'no plackup available', 5 unless $url;
    for my $handler (qw/curl wget HTTPLite HTTPTiny LWP/) {
      SKIP: {
            my $class = 'Plient::Handler::' . $handler;
            if ( $class->init ) {
                skip "http_get is not supported in $handler", 1
                  unless $class->support_method('http_head');
            }
            else {
                skip "$handler not available", 1;
            }
            Plient->handler_preference( http => [$handler] );
            like(
                plient( HEAD => "$url/hello" ),
                qr/Plient-Head-Path: \/hello/,
                "get head /hello using $handler"
            );
        }
    }
}
