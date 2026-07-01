use strict;
use warnings;
use Test2::V0;
use Future::AsyncAwait;
use PAGI::WebSocket;

# try_send_* must honor its contract — returns false on a failed send, never
# throws — WITHOUT fabricating a 1006 "Connection lost" disconnect or marking a
# live socket closed. A real send error (encoding/validation/bug) is NOT a
# disconnect (per spec a send after close is a silent no-op, never raises), so
# the connection state must be left untouched.

sub connected_ws_that_dies {
    my $scope = { type => 'websocket', path => '/ws', headers => [] };
    my $ws = PAGI::WebSocket->new(
        $scope, sub { Future->done }, sub { die "real send error\n" },
    );
    $ws->_set_state('connected');
    return $ws;
}

for my $m (qw(try_send_text try_send_bytes try_send_json)) {
    subtest "$m: failure returns 0 and leaves connection state intact" => sub {
        my $ws = connected_ws_that_dies();
        my $arg = $m eq 'try_send_json' ? { a => 1 } : 'payload';

        my $ok = $ws->$m($arg)->get;

        is $ok, 0, "$m returns false on a failed send";
        ok !$ws->is_closed, 'a non-disconnect error does NOT mark the socket closed';
        is $ws->close_code, undef, 'no fabricated 1006 close code';
        is $ws->close_reason, undef, 'no fabricated close reason (state untouched)';
    };
}

subtest 'try_send on an already-closed socket still short-circuits to 0' => sub {
    my $scope = { type => 'websocket', path => '/ws', headers => [] };
    my $ws = PAGI::WebSocket->new($scope, sub { Future->done }, sub { Future->done });
    $ws->_set_closed(1000, 'done');
    is $ws->try_send_text('x')->get, 0, 'returns 0 when already closed';
};

done_testing;
