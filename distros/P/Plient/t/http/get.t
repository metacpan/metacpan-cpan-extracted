use strict;
use warnings;

use Test::More tests => 10;

use Plient;
use Plient::Test;
use Plient::Util;
use Plient::Handler::curl;
use Plient::Handler::wget;
use Plient::Handler::HTTPLite;
use Plient::Handler::HTTPTiny;
use Plient::Handler::LWP;
$ENV{PLIENT_HANDLER_PREFERENCE_ONLY} = 1;

my $url = start_http_server();
SKIP: {
    skip 'no plackup available', 10 unless $url;

    for my $handler (qw/curl wget HTTPLite HTTPTiny LWP/) {
      SKIP: {
            my $class = 'Plient::Handler::' . $handler;
            if ( $class->init ) {
                skip "http_get is not supported in $handler", 2
                  unless $class->support_method('http_get');
            }
            else {
                skip "$handler not available", 2;
            }

            Plient->handler_preference( http => [$handler] );
            is( plient( GET => "$url/hello" ),
                'hello', "get /hello using $handler" );
            is(
                plient(
                    GET => "$url/hello",
                    { headers => { 'User-Agent' => 'plient/0.01' } }
                ),
                'hello plient/0.01',
                "get /hello using $handler with customized agent"
            );
        }
    }
}
