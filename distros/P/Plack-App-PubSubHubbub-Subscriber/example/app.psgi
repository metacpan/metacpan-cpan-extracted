use strict;
use warnings;

use lib qw( lib );

use Plack::Builder;
use Plack::Response;
use Plack::App::PubSubHubbub::Subscriber;
use Plack::App::PubSubHubbub::Subscriber::Config;
use Plack::App::PubSubHubbub::Subscriber::Client;

my $conf = Plack::App::PubSubHubbub::Subscriber::Config->new(
    callback => "http://example.tld:8081/callback",
    lease_seconds => 86400,
    verify => 'sync',
);

my $app = Plack::App::PubSubHubbub::Subscriber->new(
    config => $conf,
    on_verify => sub {
        my ($topic, $token, $mode, $lease) = @_;
        return 1;
    },
    on_ping => sub {
        my ($content_type, $content, $token) = @_;
        print STDERR "$content\n";
    },
);

my $client = Plack::App::PubSubHubbub::Subscriber::Client->new(
    config => $conf,
);

builder {
    mount $app->callback_path, $app;
    mount '/subscribe' => sub {
        my $result = $client->subscribe(
            'http://pubsubhubbub.appspot.com/',
            'http://allthingsd.com/feed/',
            'testtoken' );

        if ($result->{success}) {
            my $res = Plack::Response->new(200);
            $res->body("subscribed: ".$result->{success});
            return $res->finalize;
        }
        else {
            my $res = Plack::Response->new(500);
            $res->body("error: ".$result->{error});
            return $res->finalize;
        }
    };
};
