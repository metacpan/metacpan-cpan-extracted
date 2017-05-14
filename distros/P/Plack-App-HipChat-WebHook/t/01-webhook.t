
use strict;
use warnings;

use Test::More;

use Plack::Test;
use HTTP::Request;
use HTTP::Headers;

use Plack::App::HipChat::WebHook;

my $app = Plack::App::HipChat::WebHook->new({
    webhooks => {
        '/hipchat_notification' => sub {
            my $rh = shift;
            return [ 200,
                     [ 'Content-Type' => 'text/plain' ],
                     [ 'Completed' ]
                 ];
       },
        '/hipchat_second_notification' => sub {
            my $rh = shift;
            return [ 200,
                     [ 'Content-Type' => 'text/plain' ],
                     [ 'Completed' ]
                 ];
       },
    },
})->to_app;

## ( Good, Bad )
my @ctype  = ( 'application/json', 'text/plain' );
my @uagent = ( 'HipChat.com', 'SomeBrowser' );
my @json = ( '{"event": "room_notification", "item": {"message": {"color": "yellow", "date": "2015-01-17T20:29:06.018495+00:00", "from": "SomeDude", "id": "886f-1e10-4aa-ad-575de4", "mentions": [], "message": "Message text", "message_format": "html", "type": "notification"}, "room": {"id": 9610, "links": {"participants": "https://api.hipchat.com/v2/room/910/participant", "self": "https://api.hipchat.com/v2/room/90", "webhooks": "https://api.hipchat.com/v2/room/96/webhook"}, "name": "DevChat"}}, "oauth_client_id": "e336-47-46-b5-be0d9", "webhook_id": 530}',
             '{"event": "room_notification", "ite' );
my @uri = ( '/hipchat_notification', '/hipchat_nofritication' );

my @tests = (
    { # All good
        text   => 'All good',
        ctype  => $ctype[0],
        json   => $json[0],
        uagent => $uagent[0],
        uri    => $uri[0],
        expect => 200,
    },
    { # All good (second url)
        text   => 'All good (second URL)',
        ctype  => $ctype[0],
        json   => $json[0],
        uagent => $uagent[0],
        uri    => '/hipchat_second_notification',
        expect => 200,
    },

    { # Bad content-type
        text   => 'Bad content-type',
        ctype  => $ctype[1],
        json   => $json[0],
        uagent => $uagent[0],
        uri    => $uri[0],
        expect => 400,
    },
    { # Bad user-agent
        text   => 'Bad user-agent',
        ctype  => $ctype[0],
        json   => $json[0],
        uagent => $uagent[1],
        uri    => $uri[0],
        expect => 400,
    },
    { # Bad JSON
        text   => 'Bad JSON',
        ctype  => $ctype[0],
        json   => $json[1],
        uagent => $uagent[0],
        uri    => $uri[0],
        expect => 400,
    },
    { # Bad URL
        text   => 'Bad URL',
        ctype  => $ctype[0],
        json   => $json[1],
        uagent => $uagent[0],
        uri    => $uri[1],
        expect => 404,
    },
    { # Bad everything
        text   => 'Bad everything',
        ctype  => $ctype[1],
        json   => $json[1],
        uagent => $uagent[1],
        uri    => $uri[1],
        expect => 404,
    },
);

foreach my $rh_test (@tests) {
    test_psgi $app, sub {
        my $cb = shift;

        my $Headers = HTTP::Headers->new();
        $Headers->header('Content-Type' => $rh_test->{ctype});
        $Headers->header('User-Agent' => $rh_test->{uagent});
        my $Req = HTTP::Request->new('POST' => $rh_test->{uri},
                                     $Headers,
                                     $rh_test->{json});
        my $Res = $cb->($Req);
        is($Res->code, $rh_test->{expect}, $rh_test->{text});
    };
}



done_testing();
