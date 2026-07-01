use strict;
use warnings;
use Test2::V0;
use Future::AsyncAwait;
use PAGI::WebSocket;

# An HTTP denial (websocket.http.response.*) sends a response, not a WebSocket
# close frame, so there is no RFC6455 close code — close_code must be undef
# after deny(). The bare-403 fallback (no denial-response support) DOES send a
# real close frame (1008) and must keep that code.

sub recorder { my @e; my $s = sub { push @e, $_[0]; Future->done }; return ($s, \@e) }

subtest 'deny() with denial-response support: closed, but no close code' => sub {
    my ($send, $sent) = recorder();
    my $scope = {
        type => 'websocket', path => '/ws', headers => [],
        extensions => { 'websocket.http.response' => {} },
    };
    my $ws = PAGI::WebSocket->new($scope, sub { Future->done }, $send);

    $ws->deny(status => 401)->get;

    ok $ws->is_closed, 'connection is closed after deny';
    is $ws->close_code, undef, 'no RFC6455 close code for an HTTP denial (not 401)';
    is $sent->[0]{type}, 'websocket.http.response.start', 'denial response emitted';
    is $sent->[0]{status}, 401, 'the 401 still goes out as the HTTP status';
};

subtest 'deny() without denial support: bare-403 fallback keeps close code 1008' => sub {
    my ($send, $sent) = recorder();
    my $scope = { type => 'websocket', path => '/ws', headers => [] };   # no extension
    my $ws = PAGI::WebSocket->new($scope, sub { Future->done }, $send);

    $ws->deny(status => 401)->get;

    ok $ws->is_closed, 'closed';
    is $ws->close_code, 1008, 'the real close-frame path keeps its RFC6455 code';
    is $sent->[0]{type}, 'websocket.close', 'sent a real close frame';
};

done_testing;
