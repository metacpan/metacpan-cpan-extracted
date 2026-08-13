#!/usr/bin/env perl

use v5.38;
use experimental qw(try);
use Future::AsyncAwait;
use PAGI::FastAPI;

my $app = PAGI::FastAPI->new(
    title   => 'PAGI::FastAPI Chat Server',
    version => '1.0.0',
);

# In-memory store for active WebSocket client connections
my %clients;

$app->get('/',
    handler => async sub ($c) {
        $c->set_header('content-type', 'text/html; charset=utf-8');
        return <<'HTML';
<!DOCTYPE html>
<html>
<head>
    <title>PAGI::FastAPI WebSocket Chat</title>
    <style>
        body { font-family: sans-serif; margin: 2em; max-width: 600px; }
        #chat { border: 1px solid #ccc; height: 300px; overflow-y: scroll; padding: 10px; margin-bottom: 10px; }
        .msg { margin-bottom: 5px; }
        .system { color: #888; font-style: italic; }
        input[type="text"] { width: 70%; padding: 8px; }
        button { padding: 8px 12px; }
    </style>
</head>
<body>
    <h2>PAGI::FastAPI WebSocket Chat</h2>
    <div id="chat"></div>
    <form id="form">
        <input type="text" id="input" placeholder="Type a message..." autocomplete="off" required />
        <button type="submit">Send</button>
    </form>

    <script>
        const ws = new WebSocket((location.protocol === 'https:' ? 'wss://' : 'ws://') + location.host + '/ws');
        const chat = document.getElementById('chat');
        const form = document.getElementById('form');
        const input = document.getElementById('input');

        function appendMsg(text, isSystem = false) {
            const div = document.createElement('div');
            div.className = 'msg' + (isSystem ? ' system' : '');
            div.textContent = text;
            chat.appendChild(div);
            chat.scrollTop = chat.scrollHeight;
        }

        ws.onopen = () => appendMsg('Connected to chat server', true);
        ws.onmessage = (e) => appendMsg(e.data);
        ws.onclose = () => appendMsg('Disconnected from chat server', true);

        form.onsubmit = (e) => {
            e.preventDefault();
            if (input.value) {
                ws.send(input.value);
                input.value = '';
            }
        };
    </script>
</body>
</html>
HTML
    }
);

async sub broadcast_text ($message) {
    for my $client_ws (values %clients) {
        try {
            await $client_ws->send_text($message);
        }
        catch ($err) {
            # Ignore write errors for clients mid-disconnect
        }
    }
}

$app->websocket('/ws',
    handler => async sub ($ws, $deps) {
        await $ws->accept;

        my $client_id = "$ws";
        $clients{$client_id} = $ws;

        await broadcast_text("System: A new user joined the chat.");

        try {
            while (my $msg = await $ws->receive_text) {
                await broadcast_text("User: $msg");
            }
        }
        catch ($err) {
            # Catch client disconnects
        }

        delete $clients{$client_id};
        await broadcast_text("System: A user left the chat.");
    }
);

$app->to_app;
