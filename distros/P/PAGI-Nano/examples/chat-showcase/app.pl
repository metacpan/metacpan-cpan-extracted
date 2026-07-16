use v5.40;
use experimental 'signatures';
use Future::AsyncAwait;
use PAGI::Nano;

# Ports PAGI-Tools' 10-chat-showcase / websocket-chat-v2 to PAGI::Nano.
# A multi-user chat exercising every protocol at once: a REST rooms API (HTTP),
# room messaging with broadcast (WebSocket), a presence feed (SSE), app-lifetime
# room state (lifespan), and a custom request logger (event-layer middleware).
#
#     pagi-server app.pl
#     # connect a WS client to ws://127.0.0.1:5000/ws/chat and send
#     #   {"join":"general","user":"ada"} then {"text":"hello"}

# Coderef request logger. By convention a coderef middleware calls $next->().
my $logger = async sub ($scope, $receive, $send, $next) {
    warn "[req] $scope->{method} $scope->{path}\n" if ($scope->{type} // '') eq 'http';
    await $next->();
};

my $app = app {
    startup async sub ($state) {
        $state->{rooms}    = { general => { messages => [], members => {} } };
        $state->{presence} = [];   # SSE subscribers (PAGI::SSE handles)
    };

    enable $logger;

    # --- REST rooms API ---
    get '/api/rooms' => sub ($c) { [ sort keys %{ $c->state->{rooms} } ] };

    get '/api/room/:name/history' => sub ($c, $name) {
        my $room = $c->state->{rooms}{$name}
            or return $c->json({ error => 'no such room' }, status => 404);
        $room->{messages};
    };

    # --- WebSocket chat: join a room, then broadcast messages to its members ---
    websocket '/ws/chat' => async sub ($c) {
        my $ws    = $c->websocket;
        my $rooms = $c->state->{rooms};
        await $ws->accept;

        my ($room_name, $user, $room);
        await $ws->each_json(async sub ($msg) {
            if (my $r = $msg->{join}) {
                $room_name = $r;
                $user      = $msg->{user} // 'anon';
                $room      = $rooms->{$room_name} //= { messages => [], members => {} };
                $room->{members}{$user} = $ws;
                await $ws->send_json({ system => "joined $room_name as $user" });
            }
            elsif (defined $msg->{text} && $room) {
                my $entry = { room => $room_name, user => $user, text => $msg->{text} };
                push @{ $room->{messages} }, $entry;
                for my $member (values %{ $room->{members} }) {
                    await $member->send_json_if_connected($entry);   # broadcast
                }
            }
        });
    };

    # --- SSE presence feed ---
    sse '/events' => async sub ($c) {
        my $s = $c->sse;
        await $s->send_event(event => 'rooms', data => join(',', sort keys %{ $c->state->{rooms} }));
        await $s->close;
    };
};

$app;
