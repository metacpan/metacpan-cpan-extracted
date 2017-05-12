#!perl -T

use Test::More tests => 6;
use Plack::Test;
use Plack::Builder;
use HTTP::Request;

use Plack::App::PubSubHubbub::Subscriber;
use Plack::App::PubSubHubbub::Subscriber::Config;

my $conf = Plack::App::PubSubHubbub::Subscriber::Config->new(
    callback => 'http://example.tld:8081/callback?arg1=1',
);

my $s = Plack::App::PubSubHubbub::Subscriber->new(
    config => $conf,
    on_ping => sub {
        my ($content_type, $content, $token) = @_;
        is $content_type, 'application/json', "content type";
        is $content, '["content"]', "content";
        is $token, 'mytoken', "token";
    },
);

isa_ok $s, 'Plack::App::PubSubHubbub::Subscriber';

is $s->callback_path, '/callback', 'just the path';

my $app = builder {
    mount $s->callback_path, $s;
};

test_psgi
    app => $app,
    client => sub {
        my $cb  = shift;
        my $req = HTTP::Request->new(POST => "http://example.tld:8081/callback/mytoken?arg1=1",
            ['Content-Type', 'application/json'], '["content"]');
        my $res = $cb->($req);
        is $res->code, 200, "OK";
    };


