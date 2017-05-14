
use strict;
use warnings;

use Test::More;

use Plack::Test;
use HTTP::Request;
use HTTP::Headers;

use Data::Printer;

use Plack::App::HipChat::WebHook;

my $app = Plack::App::HipChat::WebHook->new({
    hipchat_user_agent => 'TEST_USER_AGENT',
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
my @uagent = ( 'TEST_USER_AGENT', 'HipChat.com' );
my @json = ( '{"event": "room_notification", "item": {"message": {"color": "yellow", "date": "2015-01-17T20:29:06.018495+00:00", "from": "SomeDude", "id": "886f-1e10-4aa-ad-575de4", "mentions": [], "message": "Message text", "message_format": "html", "type": "notification"}, "room": {"id": 9610, "links": {"participants": "https://api.hipchat.com/v2/room/910/participant", "self": "https://api.hipchat.com/v2/room/90", "webhooks": "https://api.hipchat.com/v2/room/96/webhook"}, "name": "DevChat"}}, "oauth_client_id": "e336-47-46-b5-be0d9", "webhook_id": 530}',
             '{"event": "room_notification", "ite' );
my @uri = ( '/hipchat_notification', '/hipchat_nofritication' );

my @tests = (
    { # Good user-agent
        text   => 'All good with hipchat_user_agent',
        ctype  => $ctype[0],
        json   => $json[0],
        uagent => $uagent[0],
        uri    => $uri[0],
        expect => 200,
    },
    { # Bad user-agent
        text   => 'Bad user-agent',
        ctype  => $ctype[0],
        json   => $json[0],
        uagent => $uagent[1],
        uri    => $uri[0],
        expect => 400,
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
