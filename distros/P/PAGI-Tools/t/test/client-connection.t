use strict; use warnings; use Test::More; use Future::AsyncAwait;
use PAGI::Test::Client;

my ($seen, $completed);
my $app = async sub {
    my ($scope, $receive, $send) = @_;
    $seen = $scope->{'pagi.connection'};
    ok $seen, 'scope carries pagi.connection';
    is $seen->is_connected, 1, 'connected during the request';
    is $seen->response_started, 0, 'not started before send';
    $seen->on_complete(sub { $completed = 1 });
    await $send->({ type => 'http.response.start', status => 200, headers => [] });
    is $seen->response_started, 1, 'started after http.response.start';
    await $send->({ type => 'http.response.body', body => 'hi', more => 0 });
};
PAGI::Test::Client->new(app => $app)->get('/');
is $completed, 1, 'on_complete fired once the request completed';
is $seen->is_connected, 0, 'request ended after completion';

# Clean completion: on_complete fires (after the app returns), on_disconnect does not.
{
    my ($conn, @ev);
    my $app = async sub {
        my ($scope, $receive, $send) = @_;
        $conn = $scope->{'pagi.connection'};
        $conn->on_complete(sub { push @ev, 'complete' });
        $conn->on_disconnect(sub { push @ev, 'disconnect' });
        await $send->({ type => 'http.response.start', status => 200, headers => [] });
        is_deeply \@ev, [], 'not complete yet at send time';
        await $send->({ type => 'http.response.body', body => 'ok', more => 0 });
    };
    PAGI::Test::Client->new(app => $app)->get('/');
    is_deeply \@ev, ['complete'], 'on_complete fires after the app returns; on_disconnect does not';
}

# App exception => synthetic 500 => abnormal server_error disconnect.
{
    my ($conn, @ev);
    my $boom = async sub {
        my ($scope) = @_;
        $conn = $scope->{'pagi.connection'};
        $conn->on_complete(sub { push @ev, 'complete' });
        $conn->on_disconnect(sub { push @ev, "disc:$_[0]" });
        die "boom\n";
    };
    my $resp = PAGI::Test::Client->new(app => $boom, raise_app_exceptions => 0)->get('/');
    is $resp->status, 500, 'synthetic 500 on app exception';
    is $conn->response_started, 1, 'response_started true for the synthesized 500';
    is_deeply \@ev, ['disc:server_error'], 'on_disconnect(server_error) fires, on_complete does not';
}

done_testing;
